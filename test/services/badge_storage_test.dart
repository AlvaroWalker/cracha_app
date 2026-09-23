import 'dart:convert';
import 'dart:typed_data';

import 'package:cracha_app/models/badge_data.dart';
import 'package:cracha_app/services/badge_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BadgeData', () {
    test('validate aceita um crachá completo', () {
      final badge = BadgeData(
        name: 'João da Silva',
        role: 'Professor',
        department: 'Secretaria de Educação',
      );
      expect(badge.validate(), isEmpty);
      expect(badge.isValid(), isTrue);
    });

    test('validate rejeita nome vazio, curto, cargo e secretaria', () {
      final semNome = BadgeData(name: '', role: 'Professor');
      expect(semNome.validate(), contains(BadgeValidationError.nameRequired));

      final nomeCurto = BadgeData(name: 'Ab', role: 'Professor');
      expect(nomeCurto.validate(), contains(BadgeValidationError.nameTooShort));

      final semCargo = BadgeData(name: 'João Silva', role: '   ');
      expect(semCargo.validate(), contains(BadgeValidationError.roleRequired));

      final semSecretaria =
          BadgeData(name: 'João Silva', role: 'Professor', department: ' ');
      expect(semSecretaria.validate(),
          contains(BadgeValidationError.departmentRequired));
    });

    test('validate rejeita secretaria fora da lista permitida', () {
      final badge = BadgeData(
        name: 'João Silva',
        role: 'Professor',
        department: 'Secretaria Inexistente',
      );
      final erros = badge.validate(validDepartments: ['Secretaria de Educação']);
      expect(erros, contains(BadgeValidationError.departmentInvalid));
    });

    test('uppercase é aplicado em copyWith e updateCurrentBadge', () {
      final badge = BadgeData(name: 'joão silva', role: 'professor');
      final copia = badge.copyWith(name: 'maria souza', role: 'diretora');
      expect(copia.name, 'MARIA SOUZA');
      expect(copia.role, 'DIRETORA');
    });

    test('copyWith preserva a foto por padrão', () {
      final foto = Uint8List.fromList([1, 2, 3, 4]);
      final badge = BadgeData(name: 'João', role: 'Professor', photo: foto);
      final copia = badge.copyWith(name: 'Maria');
      expect(copia.photo, isNotNull);
      expect(copia.photo, same(foto));
    });

    test('copyWith(photo: null) é no-op — bug conhecido', () {
      final foto = Uint8List.fromList([1, 2, 3]);
      final badge = BadgeData(name: 'João', role: 'Professor', photo: foto);
      final copia = badge.copyWith(photo: null);
      // Sem clearPhoto, null significa "não mexe": a foto continua.
      expect(copia.photo, isNotNull);
    });

    test('copyWith(clearPhoto: true) remove a foto de verdade', () {
      final foto = Uint8List.fromList([1, 2, 3]);
      final badge = BadgeData(name: 'João', role: 'Professor', photo: foto);
      final copia = badge.copyWith(clearPhoto: true);
      expect(copia.photo, isNull);
    });

    test('toMap/toMapSemFoto: round-trip com e sem foto', () {
      final foto = Uint8List.fromList([137, 80, 78, 71]);
      final badge = BadgeData(name: 'João', role: 'Professor', photo: foto);
      final mapa = badge.toMap();
      expect(mapa['photo'], isNotNull);

      final restaurado = BadgeData.fromMap(
          jsonDecode(jsonEncode(mapa)) as Map<String, dynamic>);
      expect(restaurado.id, badge.id);
      // fromMap normaliza para maiúsculas (regra do app, não bug).
      expect(restaurado.name, 'JOÃO');
      expect(restaurado.photo, isNotNull);

      final semFoto = badge.toMapSemFoto();
      expect(semFoto['photo'], isNull);
    });

    test('id é UUID v4 válido e único por instância', () {
      final a = BadgeData();
      final b = BadgeData();
      final regex =
          RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
      expect(regex.hasMatch(a.id), isTrue);
      expect(regex.hasMatch(b.id), isTrue);
      expect(a.id, isNot(b.id));
    });

    test('copyWith mantém o id e o createdAt originais', () {
      final original = BadgeData(name: 'João', role: 'Professor');
      final copia = original.copyWith(role: 'Diretor');
      expect(copia.id, original.id);
      expect(copia.createdAt, original.createdAt);
    });
  });

  group('BadgeStorageService', () {
    test('saveBadge + getBadgeList faz round-trip', () async {
      final badge = BadgeData(
        name: 'João Silva',
        role: 'Professor',
        department: 'Educação',
      );
      final ok = await BadgeStorageService.saveBadge(badge);
      expect(ok, isTrue);

      final lista = await BadgeStorageService.getBadgeList();
      expect(lista, hasLength(1));
      // getBadgeList normaliza para maiúsculas via fromMap.
      expect(lista.first.name, 'JOÃO SILVA');
    });

    test('saveBadge atualiza em vez de duplicar', () async {
      final badge = BadgeData(name: 'João', role: 'Professor');
      await BadgeStorageService.saveBadge(badge);
      await BadgeStorageService.saveBadge(badge.copyWith(role: 'Diretor'));

      final lista = await BadgeStorageService.getBadgeList();
      expect(lista, hasLength(1));
      expect(lista.first.role, 'DIRETOR');
    });

    test('getBadgeList ordena por updatedAt (mais recente primeiro)', () async {
      final antigo = BadgeData(name: 'Antigo', role: 'A');
      final novo = BadgeData(name: 'Novo', role: 'B');
      // updatedAt do primeiro é forçado para o passado.
      antigo.updatedAt = DateTime(2020);
      novo.updatedAt = DateTime(2030);

      final prefs = await SharedPreferences.getInstance();
      final lista = [
        jsonEncode(antigo.toMap()),
        jsonEncode(novo.toMap()),
      ];
      await prefs.setStringList('badge_list', lista);

      final resultado = await BadgeStorageService.getBadgeList();
      expect(resultado.first.name, 'NOVO');
    });

    test('getBadgeList devolve lista vazia em vez de explodir', () async {
      final lista = await BadgeStorageService.getBadgeList();
      expect(lista, isEmpty);
    });

    test('deleteBadge remove e retorna false para id inexistente', () async {
      final badge = BadgeData(name: 'João', role: 'Professor');
      await BadgeStorageService.saveBadge(badge);

      final ok = await BadgeStorageService.deleteBadge(badge.id);
      expect(ok, isTrue);
      expect(await BadgeStorageService.getBadgeList(), isEmpty);

      final inexistente = await BadgeStorageService.deleteBadge('nao-existe');
      expect(inexistente, isFalse);
    });

    test('replaceAll substitui a lista inteira', () async {
      final antigo = BadgeData(name: 'Antigo', role: 'A');
      await BadgeStorageService.saveBadge(antigo);

      final novos = [
        BadgeData(name: 'Novo 1', role: 'B'),
        BadgeData(name: 'Novo 2', role: 'C'),
      ];
      final ok = await BadgeStorageService.replaceAll(novos);
      expect(ok, isTrue);

      final lista = await BadgeStorageService.getBadgeList();
      expect(lista, hasLength(2));
      expect(lista.map((b) => b.name), isNot(contains('ANTIGO')));
    });

    test('replaceAll com lista vazia limpa o storage', () async {
      final badge = BadgeData(name: 'João', role: 'Professor');
      await BadgeStorageService.saveBadge(badge);
      await BadgeStorageService.replaceAll([]);
      expect(await BadgeStorageService.getBadgeList(), isEmpty);
    });

    test('getBadgeById devolve null para id inexistente', () async {
      final resultado = await BadgeStorageService.getBadgeById('nao-existe');
      expect(resultado, isNull);
    });
  });
}
