// Testes do [CrachaLayout] — o núcleo que resolve o bug de texto cortado.
//
// `CrachaLayout` é puro e não depende de PDF nem de imagem: recebe um
// [Medidor] e devolve itens posicionados. É por isso que dá para testar o
// comportamento de quebra/auto-ajuste sem renderizar nada.
//
// O medidor fake é proporcional ao número de caracteres — o suficiente
// para exercitar a política de encolhimento e de máximo de linhas.
import 'package:flutter_test/flutter_test.dart';

import 'package:cracha_app/views/badge_geometry.dart';

/// Medidor fake: largura proporcional ao número de caracteres.
double _medir(String t, int peso, double size) => t.length * size * 0.58;

void main() {
  const dados = CrachaDados(
    nome: 'Pedro Paulo de Sousa Marins',
    cargo: 'Conciliador de Defesa do Consumidor',
    secretaria: 'Secretaria Municipal Integrada de Apoio à Segurança Pública',
  );

  group('CrachaLayout', () {
    test('gera exatamente uma linha divisória', () {
      final itens = CrachaLayout.calcular(dados, _medir);
      expect(itens.whereType<ItemLinha>().length, 1);
    });

    test('aplica maiúsculas quando habilitado', () {
      final itens = CrachaLayout.calcular(dados, _medir);
      for (final t in itens.whereType<ItemTexto>()) {
        expect(t.texto, t.texto.toUpperCase());
      }
    });

    test('respeita largura máxima e região de texto', () {
      final itens = CrachaLayout.calcular(dados, _medir);
      for (final t in itens.whereType<ItemTexto>()) {
        expect(_medir(t.texto, t.peso, t.size), lessThanOrEqualTo(BadgeGeo.textoMaxW));
        expect(t.baseline, lessThanOrEqualTo(BadgeGeo.textoBottom));
      }
    });

    test('textos longos encolhem e continuam dentro da região', () {
      const longo = CrachaDados(
        nome: 'Maria Aparecida Fernandes de Albuquerque Nascimento Souza',
        cargo: 'Coordenadora Executiva de Planejamento Estratégico e Projetos Especiais',
        secretaria: 'Secretaria Municipal de Desenvolvimento Econômico, Turismo, Ciência e Tecnologia',
      );
      final itens = CrachaLayout.calcular(longo, _medir);
      for (final t in itens.whereType<ItemTexto>()) {
        expect(t.baseline, lessThanOrEqualTo(BadgeGeo.textoBottom));
        expect(t.baseline, greaterThanOrEqualTo(BadgeGeo.textoTop));
      }
    });
  });

  group('FotoGeom', () {
    test('zoom 1 sempre cobre a caixa da foto', () {
      final g = FotoGeom.calcular(imgW: 600, imgH: 600, zoom: 1);
      expect(g.w, greaterThanOrEqualTo(BadgeGeo.fotoW));
      expect(g.h, greaterThanOrEqualTo(BadgeGeo.fotoH));
      expect(g.my, closeTo(0, 1e-9)); // imagem quadrada: sem folga vertical
    });
  });

  // ── REGRESSÕES DO BUG ORIGINAL ───────────────────────────────────────────
  // Os dois casos abaixo quebravam no PDF vetorial antigo: a palavra órfã
  // ("E" isolado) e a secretaria inteira desaparecendo quando o nome
  // ocupava duas linhas.
  group('regressões do texto cortado', () {
    test('NENHUMA palavra fica órfã isolada', () {
      // O caso real que produzia "E" sozinho na linha.
      const caso = CrachaDados(
        nome: 'FLAVIA APARECIDA DE OLIVEIRA SOUZA',
        cargo: 'ESPECIALISTA EM GESTÃO DE PESSOAS',
        secretaria: 'SECRETARIA MUNICIPAL DE ADMINISTRAÇÃO',
      );
      final itens = CrachaLayout.calcular(caso, _medir);

      for (final t in itens.whereType<ItemTexto>()) {
        expect(t.texto.trim(), isNotEmpty);
        // "E" sozinho = palavra órfã.
        expect(t.texto.trim().length, greaterThan(1),
            reason: '"${t.texto}" ficou órfão numa linha de ${t.size}px');
      }
    });

    test('a secretaria SEMPRE aparece, mesmo com nome e cargo longos', () {
      const caso = CrachaDados(
        nome: 'MAXIMILIANO AUGUSTO FERREIRA DE ALMEIDA SOBRINHO',
        cargo: 'DIRETOR GERAL DE ADMINISTRACAO FINANCEIRA E ORCAMENTARIA',
        secretaria: 'SECRETARIA MUNICIPAL DE GESTAO FINANCEIRA E PLANEJAMENTO ESTRATEGICO',
      );
      final itens = CrachaLayout.calcular(caso, _medir);
      final todo = itens
          .whereType<ItemTexto>()
          .map((t) => t.texto)
          .join(' ')
          .toUpperCase();

      expect(todo, contains('MAXIMILIANO'));
      expect(todo, contains('ESTRATEGICO'),
          reason: 'a secretaria desapareceu — era o bug do pw.Column abortando');
    });

    test('o último texto cabe ANTES da borda inferior da região', () {
      // Foi o `pw.Column` descartando o excedente por altura. Aqui a
      // garantia é estrutural: o layout não tem budget de altura para
      // estourar, mas mesmo assim nada pode passar de textoBottom.
      const caso = CrachaDados(
        nome: 'JOÃO BATISTA DE OLIVEIRA FILHO SOBRINHO NETO',
        cargo: 'GERENTE DE DEPARTAMENTO DE ASSUNTOS JURÍDICOS',
        secretaria: 'PROCURADORIA GERAL DO MUNICÍPIO',
      );
      final itens = CrachaLayout.calcular(caso, _medir);
      for (final t in itens.whereType<ItemTexto>()) {
        expect(t.baseline, lessThan(BadgeGeo.textoBottom + 1));
      }
      // E a divisória fica entre nome/cargo e secretaria.
      final linha = itens.whereType<ItemLinha>().single;
      final textos = itens.whereType<ItemTexto>().toList();
      final antes = textos.where((t) => t.baseline < linha.y);
      final depois = textos.where((t) => t.baseline > linha.y);
      expect(antes, isNotEmpty, reason: 'nada acima da divisória');
      expect(depois, isNotEmpty, reason: 'nada abaixo da divisória');
    });

    test('texto vazio não gera item', () {
      const vazio = CrachaDados(nome: '', cargo: '', secretaria: '');
      final itens = CrachaLayout.calcular(vazio, _medir);
      expect(itens.whereType<ItemTexto>(), isEmpty);
      // A divisória continua lá, para o layout não desandar.
      expect(itens.whereType<ItemLinha>().length, 1);
    });

    test('nomes giganticamente longos não estouram o piso de 28px', () {
      const absurdo = CrachaDados(
        nome: 'AAAAAAAAAA BBBBBBBBBBBB CCCCCCCCCC DDDDDDDDDD EEEEEEEEEE '
            'FFFFFFFFFF GGGGGGGGGG HHHHHHHHHH IIIIIIIIII',
        cargo: 'JJJJJJJJJJJ KKKKKKKKKK LLLLLLLLLL',
        secretaria: 'MMMMMMMMMMM NNNNNNNNNN OOOOOOOOOO',
      );
      final itens = CrachaLayout.calcular(absurdo, _medir);
      for (final t in itens.whereType<ItemTexto>()) {
        expect(t.size, greaterThanOrEqualTo(28));
      }
    });
  });
}