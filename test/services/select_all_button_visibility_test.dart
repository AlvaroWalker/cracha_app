// Regressão: o botão "Selecionar os N visíveis" some quando a seleção
// ACUMULADA de outro filtro é maior que a lista visível atual.
//
// CENÁRIO (o bug):
//   1. Sem filtro, o usuário marca 5 crachás  → selectedIds.length == 5
//   2. Aplica um filtro que mostra 3         → filteredBadges.length == 3
//   3. A condição `selectedIds.length < filteredBadges.length` é
//      5 < 3 → FALSA → o botão some
//
// RESULTADO: os 3 visíveis estão 100% desmarcados, mas não há botão para
// marcá-los. O usuário é obrigado a clicar nos 3, um a um — exatamente o
// que o botão existiria para evitar.
//
// A condição deveria comparar só os visíveis que JÁ estão selecionados, não
// o total acumulado.
import 'package:cracha_app/models/badge_data.dart';
import 'package:cracha_app/services/badge_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cinco = [
    for (var i = 1; i <= 5; i++) BadgeData(id: 'b$i', name: 'CRACHA $i'),
  ];
  final tres = [
    for (var i = 1; i <= 3; i++) BadgeData(id: 'c$i', name: 'OUTRO $i'),
  ];

  late BadgeManager bm;

  setUp(() => bm = BadgeManager());

  /// Reproduz a condição da tela: o botão aparece enquanto houver visível
  /// NÃO selecionado. A versão antiga comparava `selectedBadgeIds.length`
  /// (acumulado entre filtros) com o total de visíveis — ver o bug no
  /// cabeçalho do arquivo.
  bool botaoAparece(List<BadgeData> visiveis) {
    final jaSelecionados =
        visiveis.where((b) => bm.isBadgeSelected(b.id)).length;
    return visiveis.isNotEmpty && jaSelecionados < visiveis.length;
  }

  test('REGRESSÃO: seleção acumulada maior não pode esconder o botão',
      () {
    // 1) Marca 5 com a lista inteira visível
    bm.selectAllBadges(cinco);
    expect(bm.selectedBadgeIds, hasLength(5));

    // 2) Filtro novo, 3 visíveis, NENHUM deles selecionado
    expect(
      botaoAparece(tres),
      isTrue,
      reason: 'com 5 selecionados de outro filtro e 3 visíveis NONE '
          'selecionados, o botão TEM que aparecer — senão o usuário não tem '
          'como marcar os 3 de uma vez',
    );
  });

  test('o botão some quando TODOS os visíveis já estão selecionados', () {
    bm.selectAllBadges(tres);
    expect(botaoAparece(tres), isFalse,
        reason: '3 visíveis, 3 selecionados → nada a fazer, botão some');
  });

  test('seleção parcial ainda mostra o botão', () {
    bm.selectAllBadges([tres.first]);
    expect(botaoAparece(tres), isTrue,
        reason: '1 de 3 marcado → ainda dá para marcar os outros 2');
  });

  test('a contagem correta é a dos visíveis selecionados, não o total', () {
    bm.selectAllBadges(cinco); // 5 de outro filtro
    bm.selectAllBadges(tres); // marca os 3 visíveis → total 8

    final visiveisSelecionados =
        tres.where((b) => bm.isBadgeSelected(b.id)).length;
    expect(visiveisSelecionados, 3);

    // O total acumulado é 8, mas só 3 importam para decidir o botão.
    expect(bm.selectedBadgeIds, hasLength(8));
  });

  test('sem filtro, o total e a contagem de visíveis coincidem', () {
    bm.selectAllBadges(cinco);
    expect(botaoAparece(cinco), isFalse,
        reason: 'sem filtro, 5 de 5 marcados → botão some (comportamento '
            'antigo continuava correto neste caso)');
  });
}
