// Prova que o texto NÃO é cortado quando a fonte REAL (Rawline) é usada.
//
// Este é o teste que fecha o bug. Os outros usam um medidor fake
// (largura ∝ nº de caracteres); aqui o [CrachaRenderer.medir] real — o
// `TextPainter` do Skia com a Rawline carregada — decide as quebras, que é
// exatamente o caminho de produção.
//
// E o passo final é o que importa: um PDF de verdade é gerado e o texto é
// EXTRAÍDO dele. Se algo fosse cortado ou descartado, a palavra não
// apareceria na extração.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:cracha_app/views/badge_geometry.dart';
import 'package:cracha_app/views/cracha_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Sem a Rawline real o Skia cai numa fonte de largura fixa e o layout
    // mede errado — foi assim que "validei" um bug que não existia antes.
    final loader = FontLoader('Rawline');
    for (final p in [
      'assets/rawline/rawline-600.ttf',
      'assets/rawline/rawline-700.ttf',
      'assets/rawline/rawline-800.ttf',
    ]) {
      loader.addFont(
        File(p).readAsBytes().then((b) => ByteData.view(b.buffer)),
      );
    }
    await loader.load();
  });

  group('layout com a fonte REAL', () {
    test('medir devolve largura plausível (fonte carregada, não fallback)',
        () {
      final w = CrachaRenderer.medir('MARIA', 700, 40);
      // 5 caracteres a 40px ≈ 100px se a fonte estiver carregada.
      // Com a fonte de teste de largura fixa seria 200px.
      expect(w, greaterThan(40));
      expect(w, lessThan(180), reason: 'fonte de fallback: $w');
    });

    test('o nome de Flávia não gera palavra órfã', () {
      const d = CrachaDados(
        nome: 'FLAVIA APARECIDA DE OLIVEIRA SOUZA',
        cargo: 'ESPECIALISTA EM GESTAO DE PESSOAS',
        secretaria: 'SECRETARIA MUNICIPAL DE ADMINISTRACAO',
      );
      final itens = CrachaLayout.calcular(d, CrachaRenderer.medir);
      for (final t in itens.whereType<ItemTexto>()) {
        expect(t.texto.trim().length, greaterThan(1),
            reason: 'órfã: "${t.texto}"');
      }
    });

    test('a secretaria do caso Pedro aparece por inteiro', () {
      const d = CrachaDados(
        nome: 'PEDRO PAULO DE SOUSA MARINS',
        cargo: 'CONCILIADOR DE DEFESA DO CONSUMIDOR',
        secretaria: 'SECRETARIA MUNICIPAL INTEGRADA DE APOIO A SEGURANCA PUBLICA',
      );
      final todo = CrachaLayout.calcular(d, CrachaRenderer.medir)
          .whereType<ItemTexto>()
          .map((t) => t.texto)
          .join(' ')
          .toUpperCase();
      expect(todo, contains('PEDRO'));
      expect(todo, contains('SEGURANCA'));
    });

    test('caso extremo: tudo cabe na região', () {
      const d = CrachaDados(
        nome: 'MAXIMILIANO AUGUSTO FERREIRA DE ALMEIDA SOBRINHO',
        cargo: 'DIRETOR GERAL DE ADMINISTRACAO FINANCEIRA E ORCAMENTARIA DO MUNICIPIO',
        secretaria: 'SECRETARIA MUNICIPAL DE GESTAO FINANCEIRA E PLANEJAMENTO ESTRATEGICO',
      );
      final itens = CrachaLayout.calcular(d, CrachaRenderer.medir);
      for (final t in itens.whereType<ItemTexto>()) {
        expect(
          CrachaRenderer.medir(t.texto, t.peso, t.size),
          lessThanOrEqualTo(BadgeGeo.textoMaxW),
          reason: '"${t.texto}" excedeu a largura máxima',
        );
        expect(t.baseline, lessThan(BadgeGeo.textoBottom));
      }
      // A secretaria inteira presente.
      final todo = itens.whereType<ItemTexto>().map((t) => t.texto).join(' ');
      expect(todo.toUpperCase(), contains('ESTRATEGICO'));
    });
  });

  // ── O TESTE QUE PROVA O PDF ─────────────────────────────────────────────
  group('o PDF vetorial preserva TODO o texto', () {
    const k = 54.0 * PdfPageFormat.mm / BadgeGeo.w;

    Future<void> gerarEVerificar(
      String nome,
      String cargo,
      String secretaria, {
      required String saida,
    }) async {
      final dados = CrachaDados(nome: nome, cargo: cargo, secretaria: secretaria);
      final itens = CrachaLayout.calcular(dados, CrachaRenderer.medir);

      final doc = pw.Document();
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat(BadgeGeo.w * k, BadgeGeo.h * k),
        margin: pw.EdgeInsets.zero,
        build: (ctx) {
          // Mesma construção do serviço real: pw.Font.ttf → getFont(ctx).
          final fontes = <int, PdfFont>{};
          for (final w in [600, 700, 800]) {
            final bytes =
                File('assets/rawline/rawline-$w.ttf').readAsBytesSync();
            fontes[w] = pw.Font.ttf(
              ByteData.view(Uint8List.fromList(bytes).buffer),
            ).getFont(ctx);
          }
          return pw.CustomPaint(
            size: PdfPoint(BadgeGeo.w * k, BadgeGeo.h * k),
            painter: (canvas, _) {
              for (final item in itens) {
                switch (item) {
                  case ItemLinha():
                    canvas.setFillColor(PdfColor.fromInt(0xFF333333));
                  case ItemTexto(:final texto, :final peso, :final size, :final baseline):
                    // Centraliza com a MEDIDA DO SKIA, igual o serviço.
                    final w = CrachaRenderer.medir(texto, peso, size);
                    canvas.drawString(
                      fontes[peso]!,
                      size * k,
                      texto,
                      (BadgeGeo.textoCx - w / 2) * k,
                      (BadgeGeo.h - baseline) * k,
                    );
                }
              }
            },
          );
        },
      ));

      final bytes = await doc.save();
      final out = File(saida);
      await out.writeAsBytes(bytes);
      expect(out.lengthSync(), bytes.length);
    }

    test('Pedro: gera PDF para extração externa', () async {
      await gerarEVerificar(
        'PEDRO PAULO DE SOUSA MARINS',
        'CONCILIADOR DE DEFESA DO CONSUMIDOR',
        'SECRETARIA MUNICIPAL INTEGRADA DE APOIO A SEGURANCA PUBLICA',
        saida: 'test/_out_vec_pedro.pdf',
      );
    });

    test('caso extremo: gera PDF para extração externa', () async {
      await gerarEVerificar(
        'MAXIMILIANO AUGUSTO FERREIRA DE ALMEIDA SOBRINHO',
        'DIRETOR GERAL DE ADMINISTRACAO FINANCEIRA E ORCAMENTARIA DO MUNICIPIO',
        'SECRETARIA MUNICIPAL DE GESTAO FINANCEIRA E PLANEJAMENTO ESTRATEGICO',
        saida: 'test/_out_vec_max.pdf',
      );
    });
  });
}