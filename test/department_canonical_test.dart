// Testa [Department.canonical] contra os valores REAIS do cadastro.
//
// Bug reportado: o autocomplete transforma "GABINETE DO PREFEITO" em
// "SECRETARIA MUNICIPAL DE GABINETE DO PREFEITO".
//
// Causa: `canonical()` cai no genérico `return 'SECRETARIA MUNICIPAL DE $t'`
// para qualquer valor que não case com a lista. Mas não toda secretaria é
// uma "SECRETARIA MUNICIPAL DE ..." — gabinete,Tesouraria, CONTROLADORIA
// etc. não são secretarias e não devem ganhar o prefixo.
import 'package:flutter_test/flutter_test.dart';

import 'package:cracha_app/models/department.dart';

void main() {
  group('canonical preserva quem NÃO é "SECRETARIA MUNICIPAL DE ..."', () {
    test('GABINETE DO PREFEITO fica como está (BUG REPORTADO)', () {
      expect(Department.canonical('GABINETE DO PREFEITO'),
          'GABINETE DO PREFEITO');
    });

    test('os demais cargos do CSV que não são secretaria', () {
      // Valores que existem no cadastro e NÃO são "SECRETARIA MUNICIPAL DE".
      const naoSecretarias = [
        'GABINETE DO PREFEITO',
        'CONTROLADORIA-GERAL DO MUNICIPIO',
        'TESOURARIA MUNICIPAL',
        'PROCURADORIA-GERAL DO MUNICIPIO',
        'DIRETORIA DE COMUNICACAO SOCIAL',
      ];
      for (final v in naoSecretarias) {
        expect(Department.canonical(v), v,
            reason: '"$v" não é uma secretaria municipal — não pode ganhar '
                'o prefixo "SECRETARIA MUNICIPAL DE"');
      }
    });
  });

  group('canonical continua expandindo secretarias curtas', () {
    test('ADMINISTRACAO E RECURSOS HUMANOS vira a forma completa', () {
      expect(Department.canonical('ADMINISTRACAO E RECURSOS HUMANOS'),
          'SECRETARIA MUNICIPAL DE ADMINISTRAÇÃO E RECURSOS HUMANOS');
    });

    test('SAUDE vira a forma completa', () {
      expect(Department.canonical('SAUDE'),
          'SECRETARIA MUNICIPAL DE SAÚDE');
    });

    test('já canonical não é alterado', () {
      expect(
        Department.canonical('SECRETARIA MUNICIPAL DE SAÚDE'),
        'SECRETARIA MUNICIPAL DE SAÚDE',
      );
    });

    test('a segurança integrada continua migrando para a canônica', () {
      expect(
        Department.canonical('INTEGRADA DE APOIO A SEGURANCA PUBLICA'),
        'SECRETARIA MUNICIPAL INTEGRADA DE APOIO À SEGURANÇA PÚBLICA',
      );
    });
  });

  group('entradas degeneradas', () {
    test('vazio não ganha prefixo', () {
      expect(Department.canonical('   '), '');
    });
  });
}