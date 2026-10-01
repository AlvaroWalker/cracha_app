import 'package:cracha_app/models/badge_data.dart';
import 'package:cracha_app/services/badge_manager.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regressão do bug reportado pelo usuário: com um filtro de secretaria
/// ativo, "Selecionar Todos" marcava a coleção INTEIRA em vez dos crachás
/// visíveis — a exclusão em lote apagava exatamente o que não estava na tela.
///
/// O manager popula `_badges` via nuvem/storage (sem setter), então aqui
/// testamos só a lógica de seleção: que `selectAllBadges` marca exatamente
/// a lista que recebe, e que ela acumula.
void main() {
  const saude = 'SECRETARIA MUNICIPAL DE SAÚDE';
  const educacao = 'SECRETARIA MUNICIPAL DE EDUCAÇÃO';

  // 5 crachás: 2 de SAÚDE, 3 de EDUCAÇÃO. Reproduz a situação real em que
  // o filtro mostrava poucos, mas a seleção marcava todos.
  final saudeBadges = [
    BadgeData(id: 's1', name: 'ANA', department: saude),
    BadgeData(id: 's2', name: 'BRUNO', department: saude),
  ];
  final educacaoBadges = [
    BadgeData(id: 'e1', name: 'CARLA', department: educacao),
    BadgeData(id: 'e2', name: 'DANIEL', department: educacao),
    BadgeData(id: 'e3', name: 'ELISA', department: educacao),
  ];

  late BadgeManager bm;

  setUp(() {
    bm = BadgeManager();
  });

  test('selectAllBadges marca SOMENTE a lista que recebe (filtro ativo)', () {
    // A tela passa filteredBadges (já filtrado por secretaria).
    bm.selectAllBadges(saudeBadges);

    expect(bm.selectedBadgeIds, hasLength(2),
        reason: 'com filtro SAÚDE, só os 2 visíveis devem ficar marcados');
    expect(bm.selectedBadgeIds, containsAll(['s1', 's2']));
    expect(bm.selectedBadgeIds.contains('e1'), isFalse,
        reason: 'crachá de outra secretaria não pode ser marcado');
  });

  test('seleção acumula entre filtros diferentes', () {
    bm.selectAllBadges(saudeBadges);
    bm.selectAllBadges(educacaoBadges);

    expect(bm.selectedBadgeIds, hasLength(5),
        reason: 'trocar de filtro preserva a seleção anterior (2 + 3)');
  });

  test('selecionar de novo o mesmo filtro não duplica', () {
    bm.selectAllBadges(saudeBadges);
    bm.selectAllBadges(saudeBadges);

    expect(bm.selectedBadgeIds, hasLength(2),
        reason: 'Set.addAll é idempotente para os mesmos ids');
  });

  test('toggle numa seleção em lote desmarca só aquele crachá', () {
    bm.selectAllBadges(saudeBadges);

    bm.toggleBadgeSelection('s1');

    expect(bm.isBadgeSelected('s1'), isFalse);
    expect(bm.isBadgeSelected('s2'), isTrue,
        reason: 'toggle não deve limpar a seleção inteira');
  });

  test('clearBadgeSelection esvazia tudo', () {
    bm.selectAllBadges(saudeBadges);
    bm.selectAllBadges(educacaoBadges);
    expect(bm.selectedBadgeIds, isNotEmpty);

    bm.clearBadgeSelection();

    expect(bm.selectedBadgeIds, isEmpty);
  });
}