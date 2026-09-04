import '../models/badge_data.dart';

/// Lógica pura de filtro/ordenação/agrupamento da galeria de crachás.
///
/// Extraída de `SavedBadgesPage` sem nenhuma mudança de comportamento:
/// recebe tudo por parâmetro explícito (sem ler State), então é
/// unit-testável e a tela só delega para cá.
class SavedBadgesFilter {
  /// Aplica busca + filtros + ordenação. Não muta a lista de entrada.
  static List<BadgeData> apply(
    List<BadgeData> badges, {
    required String searchQuery,
    required String? secretariaFiltro,
    required String ordenacao,
    required String periodoData,
  }) {
    var result = badges.where((badge) {
      if (searchQuery.isNotEmpty) {
        final nameMatch = badge.name.toLowerCase().contains(searchQuery);
        final roleMatch = badge.role.toLowerCase().contains(searchQuery);
        final deptMatch = badge.department.toLowerCase().contains(searchQuery);
        if (!(nameMatch || roleMatch || deptMatch)) return false;
      }
      if (secretariaFiltro != null &&
          badge.department.trim() != secretariaFiltro) {
        return false;
      }
      if (periodoData != 'todos') {
        final limite = switch (periodoData) {
          'hoje' => DateTime.now().subtract(const Duration(days: 1)),
          '7d' => DateTime.now().subtract(const Duration(days: 7)),
          '30d' => DateTime.now().subtract(const Duration(days: 30)),
          _ => null,
        };
        if (limite != null && badge.updatedAt.isBefore(limite)) return false;
      }
      return true;
    }).toList();

    switch (ordenacao) {
      case 'antigos':
        result.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case 'nome_az':
        result.sort((a, b) => a.name.compareTo(b.name));
      case 'nome_za':
        result.sort((a, b) => b.name.compareTo(a.name));
      default:
        result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    return result;
  }

  /// Conta crachás por secretaria, com chaves ordenadas (para o filtro).
  static Map<String, int> secretariasComContagem(List<BadgeData> badges) {
    final contagem = <String, int>{};
    for (final b in badges) {
      final key = b.department.trim();
      if (key.isEmpty) continue;
      contagem[key] = (contagem[key] ?? 0) + 1;
    }
    final sortedKeys = contagem.keys.toList()..sort();
    return {for (final k in sortedKeys) k: contagem[k]!};
  }
}

/// Rótulos e valores das opções de filtro/ordenação da galeria.
///
/// Centralizados aqui para que a tela (chips + BottomSheet) e qualquer
/// outro consumidor usem os mesmos textos, sem duplicação.
class SavedBadgesOptions {
  static const String ordenacaoPadrao = 'recentes';
  static const String periodoPadrao = 'todos';

  static const Map<String, String> ordenacaoLabels = {
    'recentes': 'Recentes',
    'antigos': 'Antigos',
    'nome_az': 'A-Z',
    'nome_za': 'Z-A',
  };

  static const Map<String, String> periodoLabels = {
    'todos': 'Todos',
    'hoje': 'Hoje',
    '7d': '7 dias',
    '30d': '30 dias',
  };
}
