// ═══════════════════════════════════════════════════════════════════════════
// PDF VETORIAL — fundo+foto raster, TEXTO vetorial com a Rawline embutida.
//
// Anatomia da página:
//
//   ┌─ imagem PNG 1273×2004 (fundo + foto recortada, sem texto)
//   └─ CustomPaint do dart_pdf com um `drawString` por ItemTexto
//
// O texto NÃO passa por `pw.Text`. Cada linha já saiu do
// [CrachaLayout.calcular] com texto, peso, tamanho e baseline resolvidos
// pelo Skia — aqui só se desenha o glifo na coordenada.
//
// Por que isso importa: `pw.Text` faria o pacote re-medir e re-quebrar com
// a tabela `hhea`, que é 37,6% mais alta que a `OS/2` usada pelo Skia. Daí
// vinham a palavra órfã, o `TextOverflow.clip` engolindo a continuação e
// o `pw.Column` descartando a secretaria. Aqui não existe etapa capaz de
// cortar: o layout já está resolvido e nada é re-quebrado.
//
// Bônus: o texto volta a ser selecionável e pesquisável, o que a versão
// raster (300 DPI) não permitia.
// ═══════════════════════════════════════════════════════════════════════════
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../views/badge_geometry.dart';
import '../views/cracha_renderer.dart';
import 'pdf_reference_page.dart';

/// Gera o PDF de UM crachá: fundo + foto como imagem, texto vetorial.
final class CrachaVectorPdfService {
  const CrachaVectorPdfService._();

  /// Pesos usados pelo `CrachaLayout` → arquivo correspondente no bundle.
  static const _fontes = <int, String>{
    600: 'assets/rawline/rawline-600.ttf',
    700: 'assets/rawline/rawline-700.ttf',
    800: 'assets/rawline/rawline-800.ttf',
  };

  /// 54mm. A altura segue a proporção do template.
  static const larguraMm = 54.0;

  /// Fator de conversão: px de design → pt.
  static double get k => larguraMm * PdfPageFormat.mm / BadgeGeo.w;

  /// Formato de página de um crachá (54×85mm exatos).
  static PdfPageFormat get pageFormat =>
      PdfPageFormat(BadgeGeo.w * k, BadgeGeo.h * k);

  /// Documento com UMA página de crachá + a folha de referência.
  static Future<Uint8List> gerar({
    required CrachaDados dados,
    required FotoAjuste ajuste,
    required ui.Image fundo,
    required ui.Image foto,
  }) async {
    final doc = pw.Document(
      title: 'Crachá - ${dados.nome.trim()}',
      creator: 'Emissor Digital de Crachás',
    );

    final build = await _montaPagina(
      dados: dados,
      ajuste: ajuste,
      fundo: fundo,
      foto: foto,
    );
    doc.addPage(pw.Page(
      pageFormat: pageFormat,
      margin: pw.EdgeInsets.zero,
      build: build,
    ));

    await appendReferencePage(doc);
    return doc.save();
  }

  /// Anexa N páginas de crachá a um documento existente.
  ///
  /// Usado pelo gerador de lote: um documento, uma página por crachá, sem
  /// criar e salvar um PDF separado para cada um.
  static Future<void> addPage(
    pw.Document doc, {
    required CrachaDados dados,
    required FotoAjuste ajuste,
    required ui.Image fondo,
    required ui.Image foto,
    PdfPageFormat? formato,
  }) async {
    final build = await _montaPagina(
      dados: dados,
      ajuste: ajuste,
      fundo: fondo,
      foto: foto,
    );
    doc.addPage(pw.Page(
      pageFormat: formato ?? pageFormat,
      margin: pw.EdgeInsets.zero,
      build: build,
    ));
  }

  /// Prepara a página e devolve o `build:` de [pw.Page] já pronto.
  ///
  /// [pw.Page.build] é SÍNCRONO, então o `await` (do PNG do fundo+foto e das
  /// fontes do bundle) precisa acontecer fora dele. Por isso isto devolve a
  /// função `build` em vez de um widget: `pw.Font.getFont` só existe dentro
  /// do `build`, com o `Context` do documento.
  ///
  /// Devolve `pw.Widget Function(pw.Context)` — que é exatamente a assinatura
  /// que `pw.Page` espera, então dá para passar direto.
  static Future<pw.Widget Function(pw.Context)> _montaPagina({
    required CrachaDados dados,
    required FotoAjuste ajuste,
    required ui.Image fundo,
    required ui.Image foto,
  }) async {
    final basePng = await CrachaRenderer.baseParaPng(
      fundo: fundo,
      foto: foto,
      ajuste: ajuste,
    );

    final fontes = <int, pw.Font>{};
    for (final e in _fontes.entries) {
      fontes[e.key] = pw.Font.ttf(await rootBundle.load(e.value));
    }

    // O layout é resolvido AQUI, uma vez, com o medidor do Skia. É este
    // cálculo que o preview também usa — daí a identidade entre os dois.
    final itens = CrachaLayout.calcular(dados, CrachaRenderer.medir);

    final escala = k;
    final largura = pageFormat.width;
    final altura = pageFormat.height;

    return (ctx) {
      return pw.Stack(
        children: [
          pw.SizedBox(
            width: largura,
            height: altura,
            child: pw.Image(pw.MemoryImage(basePng), fit: pw.BoxFit.fill),
          ),
          pw.SizedBox(
            width: largura,
            height: altura,
            child: pw.CustomPaint(
              size: PdfPoint(largura, altura),
              painter: (canvas, _) {
                final pdfFontes = {
                  for (final e in fontes.entries) e.key: e.value.getFont(ctx),
                };
                final cor = PdfColor.fromInt(0xFF333333);

                // Origem do PDF é embaixo-esquerda; o layout mede do topo.
                canvas.setFillColor(cor);
                for (final item in itens) {
                  switch (item) {
                    case ItemLinha(:final y):
                      canvas
                        ..drawRect(
                          BadgeGeo.linhaX1 * escala,
                          (BadgeGeo.h - y - BadgeGeo.linhaH) * escala,
                          (BadgeGeo.linhaX2 - BadgeGeo.linhaX1) * escala,
                          BadgeGeo.linhaH * escala,
                        )
                        ..fillPath();
                    case ItemTexto(
                        :final texto,
                        :final peso,
                        :final size,
                        :final baseline,
                      ):
                      // Mesma fonte, mesma medida do preview ->
                      // centralização idêntica.
                      final larguraTexto =
                          CrachaRenderer.medir(texto, peso, size);
                      canvas.drawString(
                        pdfFontes[peso]!,
                        size * escala,
                        texto,
                        (BadgeGeo.textoCx - larguraTexto / 2) * escala,
                        (BadgeGeo.h - baseline) * escala,
                      );
                  }
                }
              },
            ),
          ),
        ],
      );
    };
  }
}