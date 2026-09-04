import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/badge_data.dart';

/// Camada de nuvem: tabela `crachas` + bucket `fotos-crachas` no Supabase.
/// O ID local do crachá é usado como PK (uuid em string) para manter
/// sincronia entre local e nuvem.
class BadgeCloudService {
  static SupabaseClient get _client => Supabase.instance.client;
  static const String _bucket = 'fotos-crachas';

  /// Faz upload da foto e retorna o path armazenado (ou null se sem foto).
  static Future<String?> _uploadPhoto(String badgeId, Uint8List? photo) async {
    if (photo == null || photo.isEmpty) return null;
    final path = '$badgeId.jpg';
    await _client.storage.from(_bucket).uploadBinary(
          path,
          photo,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );
    return path;
  }

  static Future<String?> getPhotoUrl(String? fotoPath) async {
    if (fotoPath == null || fotoPath.isEmpty) return null;
    return _client.storage.from(_bucket).getPublicUrl(fotoPath);
  }

  /// Salva (insert ou update) o crachá na nuvem. Lança exceção em falha.
  /// Com [skipPhotoUpload], a foto NÃO é reenviada (coluna foto_path
  /// preservada no upsert) — use quando os bytes são os mesmos do save anterior.
  static Future<void> saveBadge(BadgeData badge,
      {bool skipPhotoUpload = false}) async {
    final fotoPath =
        skipPhotoUpload ? null : await _uploadPhoto(badge.id, badge.photo);
    final row = {
      'id': badge.id,
      'nome': badge.name,
      'cargo': badge.role,
      'secretaria': badge.department,
      if (fotoPath != null) 'foto_path': fotoPath,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    await _client.from('crachas').upsert(row);
  }

  /// Lista todos os crachás da nuvem (mais recentes primeiro).
  /// Foto vem como URL pública quando existir.
  /// Os downloads das fotos rodam em PARALELO (mesmo resultado, boot mais rápido).
  static Future<List<BadgeData>> fetchBadges() async {
    final rows = await _client
        .from('crachas')
        .select('id, nome, cargo, secretaria, foto_path, created_at, updated_at')
        .order('updated_at', ascending: false);

    final futures = (rows as List<dynamic>).map((row) async {
      final map = row as Map<String, dynamic>;
      Uint8List? photoBytes;
      final fotoPath = map['foto_path'] as String?;
      if (fotoPath != null && fotoPath.isNotEmpty) {
        // Baixa os bytes da foto para o modelo local
        try {
          photoBytes = await _client.storage.from(_bucket).download(fotoPath);
        } catch (_) {
          // segue sem foto
        }
      }
      return _fromRow(map, photoBytes);
    }).toList();
    return Future.wait(futures);
  }

  static Future<BadgeData> _fromRow(Map<String, dynamic> map, Uint8List? photoBytes) async {
    return BadgeData(
      id: map['id'] as String,
      name: (map['nome'] ?? '') as String,
      role: (map['cargo'] ?? '') as String,
      department: (map['secretaria'] ?? '') as String,
      photo: photoBytes,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  /// Exclui crachá e a foto associada. Lança exceção em falha.
  static Future<void> deleteBadge(BadgeData badge) async {
    await _client.from('crachas').delete().eq('id', badge.id);
    if (badge.photo != null) {
      try {
        await _client.storage.from(_bucket).remove(['${badge.id}.jpg']);
      } catch (_) {/* foto já ausente */}
    }
  }
}
