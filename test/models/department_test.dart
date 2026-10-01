import 'package:cracha_app/models/department.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Department.canonical', () {
    test('renomeia a secretaria de segurança para o nome oficial', () {
      const novoNome =
          'SECRETARIA MUNICIPAL INTEGRADA DE APOIO À SEGURANÇA PÚBLICA';

      expect(Department.departments, contains(novoNome));
      expect(
        Department.canonical(
          'SECRETARIA MUNICIPAL INTEGRADA DE APOIO À SEGURANÇA',
        ),
        novoNome,
      );
      expect(
        Department.canonical('INTEGRADA DE APOIO A SEGURANCA PUBLICA'),
        novoNome,
      );
    });

    test('devolve inalterado quando já começa com SECRETARIA MUNICIPAL', () {
      expect(
        Department.canonical('SECRETARIA MUNICIPAL DE EDUCAÇÃO'),
        'SECRETARIA MUNICIPAL DE EDUCAÇÃO',
      );
    });

    test('cadastro abreviado de RH vira a forma completa do crachá', () {
      expect(
        Department.canonical('ADMINISTRACAO E RECURSOS HUMANOS'),
        'SECRETARIA MUNICIPAL DE ADMINISTRAÇÃO E RECURSOS HUMANOS',
      );
      expect(
        Department.canonical('ADMINISTRAÇÃO E RECURSOS HUMANOS'),
        'SECRETARIA MUNICIPAL DE ADMINISTRAÇÃO E RECURSOS HUMANOS',
      );
    });

    test('casa versão sem acento com a lista oficial', () {
      expect(
        Department.canonical('SAUDE'),
        'SECRETARIA MUNICIPAL DE SAÚDE',
      );
      expect(
        Department.canonical('EDUCACAO'),
        'SECRETARIA MUNICIPAL DE EDUCAÇÃO',
      );
    });

    test('desconhecida ganha o prefixo (não devolve cru)', () {
      expect(
        Department.canonical('ESPORTE AMADOR'),
        'SECRETARIA MUNICIPAL DE ESPORTE AMADOR',
      );
    });

    test('vazio devolve vazio', () {
      expect(Department.canonical(''), '');
      expect(Department.canonical('   '), '');
    });

    test('toda forma "cadastro" da lista volta para a canônica', () {
      // Garante que para cada secretaria oficial, passar só o nome curto
      // (sem prefixo) retorna a oficial.
      for (final d in Department.departments) {
        final short = d
            .replaceFirst('SECRETARIA MUNICIPAL DE ', '')
            .replaceFirst('SECRETARIA MUNICIPAL ', '');
        final back = Department.canonical(short);
        expect(back, d, reason: 'Falhou para "$short"');
      }
    });
  });
}
