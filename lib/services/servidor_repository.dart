import 'package:supabase_flutter/supabase_flutter.dart';

/// Servidor vindo da base de RH (Supabase).
class Servidor {
  final String nome;
  final String cargo;
  final String secretaria;

  const Servidor({required this.nome, required this.cargo, required this.secretaria});

  Map<String, dynamic> toJson() => {'nome': nome, 'cargo': cargo, 'secretaria': secretaria};

  factory Servidor.fromJson(Map<String, dynamic> json) => Servidor(
        nome: json['nome'] as String? ?? '',
        cargo: json['cargo'] as String? ?? '',
        secretaria: json['secretaria'] as String? ?? '',
      );
}

/// Carrega servidores sob demanda do Supabase (lazy loading).
/// Não faz cache local — cada busca vai ao banco, com:
/// - Paginação automática (limite de 1000 por request do Supabase REST)
/// - Debounce no cliente
/// - Busca em nome, cargo e secretaria
class ServidorRepository {
  /// Remove acentos e normaliza para comparação.
  static String _normalize(String s) {
    final withAscii = s
        .replaceAll('Á', 'A').replaceAll('À', 'A').replaceAll('Ã', 'A').replaceAll('Â', 'A')
        .replaceAll('á', 'a').replaceAll('à', 'a').replaceAll('ã', 'a').replaceAll('â', 'a')
        .replaceAll('É', 'E').replaceAll('Ê', 'E')
        .replaceAll('é', 'e').replaceAll('ê', 'e')
        .replaceAll('Í', 'I').replaceAll('í', 'i')
        .replaceAll('Ó', 'O').replaceAll('Ô', 'O').replaceAll('Õ', 'O')
        .replaceAll('ó', 'o').replaceAll('ô', 'o').replaceAll('õ', 'o')
        .replaceAll('Ú', 'U').replaceAll('Ü', 'U')
        .replaceAll('ú', 'u').replaceAll('ü', 'u')
        .replaceAll('Ç', 'C').replaceAll('ç', 'c');
    return withAscii.toUpperCase().trim();
  }

  /// Busca servidores diretamente no Supabase via RPC ou query.
  /// Retorna no máximo [limit] resultados.
  ///
  /// Tenta primeiro a função `buscar_servidores` (ignora acentos via
  /// extensão `unaccent` — veja o SQL em `assets/data/buscar_servidores.sql`).
  /// Se a função não existir no banco, cai para o `ilike` (comportamento atual).
  static Future<List<Servidor>> searchRemote(String query,
      {int limit = 8}) async {
    final q = query.trim();
    if (q.length < 2) return [];

    try {
      final client = Supabase.instance.client;
      try {
        final rpc = await client.rpc('buscar_servidores',
            params: {'termo': q, 'limite': limit});
        return _fromRows(rpc as List<dynamic>);
      } catch (_) {
        // Função ainda não criada no banco — usa ilike direto.
      }
      // Usa ilike para case-insensitive match parcial
      final termo = '%${_escapeIlike(q)}%';
      final response = await client
          .from('servidores')
          .select('nome, cargo, secretaria')
          .or('nome.ilike.$termo,cargo.ilike.$termo,secretaria.ilike.$termo')
          .limit(limit);

      return _fromRows(response as List<dynamic>);
    } catch (e) {
      // ignore: avoid_print
      print('[ServidorRepository] Erro na busca: $e');
      return [];
    }
  }

  static List<Servidor> _fromRows(List<dynamic> rows) {
    final result = <Servidor>[];
    for (final row in rows) {
      final map = row as Map<String, dynamic>;
      result.add(Servidor(
        nome: (map['nome'] ?? '') as String,
        cargo: (map['cargo'] ?? '') as String,
        secretaria: (map['secretaria'] ?? '') as String,
      ));
    }
    return result;
  }

  /// Escapa caracteres especiais do ilike do Postgres.
  static String _escapeIlike(String s) =>
      s.replaceAll('%', r'\%').replaceAll('_', r'\_');

  /// Mantido para compatibilidade, mas não faz mais nada.
  /// Use [searchRemote] para buscar sob demanda.
  static Future<List<Servidor>> load({bool forceRefresh = false}) async => [];

  /// Mantido para compatibilidade.
  static List<Servidor> search(List<Servidor> all, String query, {int limit = 8}) {
    if (all.isEmpty) return [];
    final termos = _normalize(query).split(' ').where((t) => t.length >= 2).toList();
    if (termos.isEmpty) return [];

    final startsWith = <Servidor>[];
    final contains = <Servidor>[];

    for (final s in all) {
      final nome = _normalize(s.nome);
      final cargo = _normalize(s.cargo);
      final sec = _normalize(s.secretaria);
      final campos = '$nome $cargo $sec';

      if (nome.startsWith(termos.first)) {
        startsWith.add(s);
      } else if (termos.every((t) => campos.contains(t))) {
        contains.add(s);
      } else if (termos.any((t) => campos.contains(t))) {
        contains.add(s);
      }
      if (startsWith.length >= limit) break;
    }
    return [...startsWith, ...contains].take(limit).toList();
  }

  /// Tenta encontrar correspondência exata (para preencher ao sair do campo).
  static Servidor? exactMatch(List<Servidor> all, String name) {
    final q = _normalize(name);
    if (q.isEmpty || q.length < 4) return null;
    for (final s in all) {
      if (_normalize(s.nome) == q) return s;
    }
    return null;
  }
}
