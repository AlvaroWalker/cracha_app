import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/badge_data.dart';

/// Falha de rede/servidor na nuvem — a fila de retry deve reprocessar.
/// Permissão negada (RLS) NÃO vira isto: retry não conserta RLS.
class CloudUnavailableException implements Exception {
  final String message;
  const CloudUnavailableException(this.message);
  @override
  String toString() => message;
}

/// Camada de nuvem: tabela `crachas` + bucket privado `fotos-crachas`.
///
/// Galeria compartilhada: qualquer usuário autenticado lê, edita e exclui
/// qualquer crachá. `owner_id` no banco é metadado de autoria, não barreira.
/// O prefixo do dono no path do storage (`{ownerId}/{badgeId}.jpg`) é
/// organização, também não permissão — por isso o path real vem sempre do
/// banco ([BadgeData.photoPath]) e nunca é derivado do UID local: num crachá
/// criado por outra pessoa, derivar localmente apontaria para arquivo errado.
class BadgeCloudService {
  static SupabaseClient get _client => Supabase.instance.client;
  static const String _bucket = 'fotos-crachas';

  /// Assinatura de URL válida por 1h: cobre o render do preview e do PDF
  /// sem deixar a foto acessível para sempre.
  static const int _signedUrlTtlSeconds = 3600;

  /// Teto de downloads de foto em paralelo. Sem limite, uma galeria grande
  /// abre uma conexao por arquivo e o navegador derruba tudo junto.
  static const int photoConcurrency = 6;

  static bool _isPermissionDenied(Object error) {
    final text = error.toString().toLowerCase();
    return text.contains('row-level security') ||
        text.contains('row level security') ||
        text.contains('42501');
  }

  /// Traduz o erro bruto em exceção semântica: permissão negada não melhora
  /// com retry, então o caller precisa distinguir as duas.
  static Never _rethrow(Object error, String fallback) {
    if (_isPermissionDenied(error)) {
      throw Exception('Sem permissão para esta operação na nuvem.');
    }
    throw CloudUnavailableException(fallback);
  }

  static String? get _currentUid => _client.auth.currentSession?.user.id;

  /// Path da foto no storage, sempre com prefixo do dono.
  static String photoPathFor(String badgeId) {
    final uid = _currentUid;
    if (uid == null || uid.isEmpty) {
      throw const CloudUnavailableException(
          'Sem sessão ativa para enviar a foto.');
    }
    return '$uid/$badgeId.jpg';
  }

  /// Path da foto de um crachá que já existe na nuvem.
  ///
  /// Prefere o path persistido em `foto_path`. Só cai no derivado quando o
  /// registro não tem path nenhum (crachá legado ou já sem foto) — e nesse
  /// caso o derivado é o melhor palpite possível, não uma garantia.
  static String? photoPathForBadge(BadgeData badge) {
    final persisted = badge.photoPath;
    if (persisted != null && persisted.isNotEmpty) return persisted;
    final uid = _currentUid;
    if (uid == null || uid.isEmpty) return null;
    return '$uid/${badge.id}.jpg';
  }

  /// Apaga o objeto da foto do storage. Idempotente: objeto ausente não
  /// é erro.
  static Future<void> _removePhotoObject(String path) async {
    try {
      await _client.storage.from(_bucket).remove([path]);
    } catch (_) {
      // Foto já ausente ou sem permissão: não impede o save/exclusão.
    }
  }

  /// Faz upload da foto e retorna o path armazenado (ou null se sem foto).
  static Future<String?> _uploadPhoto(String badgeId, Uint8List? photo) async {
    if (photo == null || photo.isEmpty) return null;
    final path = photoPathFor(badgeId);
    try {
      await _client.storage.from(_bucket).uploadBinary(
            path,
            photo,
            fileOptions:
                const FileOptions(upsert: true, contentType: 'image/jpeg'),
          );
    } catch (e) {
      _rethrow(e, 'Falha ao enviar a foto para a nuvem.');
    }
    return path;
  }

  /// URL assinada temporária para exibir a foto de um bucket privado.
  /// Retorna null se o path for vazio ou inacessível.
  static Future<String?> getPhotoUrl(String? fotoPath) async {
    if (fotoPath == null || fotoPath.isEmpty) return null;
    try {
      return await _client.storage
          .from(_bucket)
          .createSignedUrl(fotoPath, _signedUrlTtlSeconds);
    } catch (_) {
      return null;
    }
  }

  /// Salva (insert ou update) o crachá na nuvem. Lança exceção em falha.
  ///
  /// `skipPhotoUpload` preserva o `foto_path` anterior (não reenvia bytes).
  /// Crachá **sem foto** grava `foto_path = NULL` explicitamente — sem isso,
  /// apagar a foto no app deixaria o registro apontando para um JPEG
  /// invisível na tela e vivo no bucket.
  static Future<void> saveBadge(BadgeData badge,
      {bool skipPhotoUpload = false}) async {
    final fotoPath =
        skipPhotoUpload ? null : await _uploadPhoto(badge.id, badge.photo);
    final row = <String, dynamic>{
      'id': badge.id,
      'nome': badge.name,
      'cargo': badge.role,
      'secretaria': badge.department,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (!skipPhotoUpload && badge.photo == null) {
      // Foto removida: limpa a referência e apaga o objeto antigo.
      final stale = photoPathForBadge(badge);
      if (stale != null) await _removePhotoObject(stale);
      row['foto_path'] = null;
    } else if (fotoPath != null) {
      row['foto_path'] = fotoPath;
    }

    try {
      await _client.from('crachas').upsert(row);
    } catch (e) {
      _rethrow(e, 'Falha ao salvar o crachá na nuvem.');
    }
  }

  /// Lista todos os crachás da nuvem (mais recentes primeiro).
  /// Fotos vêm como bytes baixados do bucket privado do próprio dono.
  static Future<List<BadgeData>> fetchBadges() async {
    final rows = await _client
        .from('crachas')
        .select('id, nome, cargo, secretaria, foto_path, created_at, updated_at')
        .order('updated_at', ascending: false);

    final badges = <BadgeData>[];
    final photoPaths = <String, String>{};
    for (final row in rows as List<dynamic>) {
      final map = row as Map<String, dynamic>;
      badges.add(_fromRow(map));
      final path = map['foto_path'] as String?;
      if (path != null && path.isNotEmpty) photoPaths[map['id'] as String] = path;
    }

    await _downloadPhotos(badges, photoPaths);
    return badges;
  }

  /// Baixa as fotos em paralelo com teto de [photoConcurrency].
  static Future<void> _downloadPhotos(
    List<BadgeData> badges,
    Map<String, String> photoPaths,
  ) async {
    final pending = <BadgeData>[
      for (final b in badges)
        if (photoPaths.containsKey(b.id)) b,
    ];
    if (pending.isEmpty) return;

    var cursor = 0;
    Future<void> worker() async {
      while (true) {
        final index = cursor++;
        if (index >= pending.length) return;
        final badge = pending[index];
        final path = photoPaths[badge.id];
        if (path == null) continue;
        try {
          badge.photo = await _client.storage.from(_bucket).download(path);
        } catch (_) {
          // Sem foto é estado válido: o crachá renderiza com placeholder.
        }
      }
    }

    final workers = [
      for (var i = 0; i < photoConcurrency && i < pending.length; i++) worker(),
    ];
    await Future.wait(workers);
  }

  static BadgeData _fromRow(Map<String, dynamic> map, [Uint8List? photoBytes]) {
    return BadgeData(
      id: map['id'] as String,
      name: (map['nome'] ?? '') as String,
      role: (map['cargo'] ?? '') as String,
      department: (map['secretaria'] ?? '') as String,
      photo: photoBytes,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
      photoPath: map['foto_path'] as String?,
      ownerId: map['owner_id'] as String?,
    );
  }

  /// Exclui crachá e a foto associada. Lança exceção em falha.
  ///
  /// A foto vai primeiro: se a linha for apagada antes e o remove falhar,
  /// não sobra referência para localizar o objeto depois.
  static Future<void> deleteBadge(BadgeData badge) async {
    final path = photoPathForBadge(badge);
    if (path != null) await _removePhotoObject(path);
    try {
      await _client.from('crachas').delete().eq('id', badge.id);
    } catch (e) {
      _rethrow(e, 'Falha ao excluir o crachá na nuvem.');
    }
  }

  /// Remove somente a foto de um crachá, mantendo o registro na tabela.
  static Future<void> removePhoto(BadgeData badge) async {
    final path = photoPathForBadge(badge);
    if (path != null) await _removePhotoObject(path);
  }
}
