// ═══════════════════════════════════════════════════════════════════════════
// Constrói o crachá DIRETO em widgets pw (vetorial) — sem screenshot.
//
// Reusa BadgeGeometry e BadgeTextStyles de badge_design.dart de propósito:
// aquele arquivo é a fonte única de verdade pro layout. Se alguém mudar um
// número lá pro preview, o PDF acompanha sozinho — não há nenhuma medida
// duplicada aqui.
//
// `_autoSizeText` mede o texto via PdfFont.stringMetrics() pra decidir
// quando reduzir a fonte (equivalente manual do AutoSizeText do Flutter,
// que não existe no pacote `pdf`). VERIFICADO contra o código-fonte real
// de DavBfr/dart_pdf (github.com/DavBfr/dart_pdf):
//   - stringMetrics vive em PdfFont (pdf/lib/src/pdf/obj/font.dart), NÃO
//     em pw.Font — por isso `buildCard` exige um pw.Context: é o que
//     permite resolver `pw.Font.getFont(context) -> PdfFont` uma vez, no
//     topo, antes de medir qualquer linha.
//   - PdfFontMetrics é normalizado a fontSize=1; `.width * fontSize` dá a
//     largura real em pt (confirmado em font_metrics.dart).
// ═══════════════════════════════════════════════════════════════════════════
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'badge_design.dart';
import '../models/badge_data.dart';

class BadgePdfWidget {
  BadgePdfWidget._();

  /// Constrói o cartão do crachá em pt, escalado ANISOTROPICAMENTE
  /// (scaleX/scaleY independentes) para preencher exatamente a página
  /// alvo sem cortar nem sobrar margem — troca-off deliberado no lugar do
  /// BoxFit.cover usado na captura antiga (ver comentário no chamador).
  static pw.Widget buildCard({
    required pw.Context context,
    required BadgeData badge,
    required pw.MemoryImage cardArt,
    required pw.MemoryImage placeholderPhoto,
    pw.MemoryImage? photo,
    required pw.Font rawlineBold,
    required double scaleX,
    required double scaleY,
  }) {
    // Resolve o PdfFont UMA vez aqui — stringMetrics vive nele, não em
    // pw.Font (ver nota no topo do arquivo).
    final PdfFont metricsFont = rawlineBold.getFont(context);

    double pxW(double v) => v * scaleX;
    double pxH(double v) => v * scaleY;
    // Pra raios/bordas (elementos "redondos"), usa a média — a diferença
    // entre scaleX e scaleY tende a ser < 0.5%, não dá pra notar.
    final radiusScale = (scaleX + scaleY) / 2;
    double pxR(double v) => v * radiusScale;

    final cardWidth = pxW(BadgeGeometry.cardWidth);
    final cardHeight = pxH(BadgeGeometry.cardHeight);
    final photoWidth = pxW(BadgeGeometry.photoWidth);
    final photoHeight = pxH(BadgeGeometry.photoHeight);
    final infoWidth = pxW(BadgeGeometry.infoWidth);
    final infoHeight = pxH(BadgeGeometry.infoHeight);

    final bool isNameEmpty = badge.name.trim().isEmpty;
    final bool isRoleEmpty = badge.role.trim().isEmpty;
    final bool isDeptEmpty = badge.department.trim().isEmpty;

    // Largura útil de texto dentro do cartão de info (desconta padding
    // lateral equivalente ao que o Divider aplicava com indent/endIndent).
    // O Container do cartão branco (_buildInfoSection no original) não
    // tem padding horizontal — e o widget deixa o texto vazar ~5px p/
    // cada lado sobre o fundo branco (invisível). Aqui a tolerância é
    // maior (+12px/lado) porque as métricas do pacote pdf medem a Rawline
    // um pouco mais larga que o Flutter — sem isso o nome quebra em
    // 2 linhas onde na tela cabe 1.
    final textMaxWidth = infoWidth + pxW(24);

    return pw.SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: pw.Stack(
        children: [
          // Arte de fundo (já traz os cantos arredondados de fábrica —
          // mesma regra do BadgeView: nenhum ClipRRect por cima dela).
          pw.Positioned(
            left: 0,
            top: 0,
            child: pw.Image(
              cardArt,
              width: cardWidth,
              height: cardHeight,
              fit: pw.BoxFit.contain,
            ),
          ),

          // Foto (+4px só no vetor — ajuste fino; a tela segue BadgeGeometry puro).
          pw.Positioned(
            top: pxH(BadgeGeometry.photoTop + 2),
            left: (cardWidth - photoWidth) / 2,
            child: pw.Container(
              width: photoWidth,
              height: photoHeight,
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(pxR(14)),
                border: pw.Border.all(
                  color: PdfColors.white,
                  width: pxR(1.5),
                ),
              ),
              child: pw.ClipRRect(
                horizontalRadius: pxR(13),
                verticalRadius: pxR(13),
                child: pw.Image(
                  photo ?? placeholderPhoto,
                  width: photoWidth,
                  height: photoHeight,
                  fit: pw.BoxFit.cover,
                ),
              ),
            ),
          ),

          // Cartão branco de identificação
          pw.Positioned(
            bottom: pxH(BadgeGeometry.infoBottom),
            left: (cardWidth - infoWidth) / 2,
            child: pw.Container(
              width: infoWidth,
              height: infoHeight,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(pxR(8)),
              ),
              padding: pw.EdgeInsets.symmetric(vertical: pxH(8)),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  _autoSizeText(
                    text: isNameEmpty ? 'NOME DO FUNCIONÁRIO' : badge.name,
                    styleFont: rawlineBold,
                    metricsFont: metricsFont,
                    // textScaleFactor: 0.9 do AutoSizeText original
                    maxFontSize: pxR(BadgeTextStyles.name.fontSize! * 0.9),
                    minFontSize: pxR(8),
                    maxWidth: textMaxWidth,
                    maxLines: 2,
                    color: isNameEmpty ? PdfColors.grey400 : PdfColors.black,
                  ),
                  _autoSizeText(
                    text: isRoleEmpty ? 'CARGO / FUNÇÃO' : badge.role,
                    styleFont: rawlineBold,
                    metricsFont: metricsFont,
                    maxFontSize: pxR(BadgeTextStyles.role.fontSize! * 0.9),
                    minFontSize: pxR(8),
                    maxWidth: textMaxWidth,
                    maxLines: 2,
                    color: isRoleEmpty ? PdfColors.grey400 : PdfColors.black,
                  ),
                  // Respiro extra entre cargo e divisória (só vetor; a tela
                  // distribui via spaceAround e não tem esse respiro).
                  pw.Padding(
                    padding: pw.EdgeInsets.only(top: pxH(5)),
                    child: pw.Container(
                      margin: pw.EdgeInsets.symmetric(horizontal: pxW(15)),
                      height: pxH(2),
                      color: PdfColors.black,
                    ),
                  ),
                  _autoSizeText(
                    text: isDeptEmpty
                        ? 'SECRETARIA / DEPARTAMENTO'
                        : badge.department,
                    styleFont: rawlineBold,
                    metricsFont: metricsFont,
                    // department não tem textScaleFactor no original (1.0)
                    maxFontSize: pxR(BadgeTextStyles.department.fontSize!),
                    minFontSize: pxR(8),
                    maxWidth: textMaxWidth,
                    maxLines: 2,
                    letterSpacing:
                        pxR(BadgeTextStyles.department.letterSpacing ?? 0),
                    color: isDeptEmpty ? PdfColors.grey400 : PdfColors.black,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Autosize manual: reduz a fonte em passos de 0.5pt até o texto caber
  /// em [maxLines] linhas dentro de [maxWidth], sem passar de [minFontSize].
  ///
  /// [lineHeightScale] encolhe a entrelinha (1.0 = natural do pacote pdf,
  /// que avança a caixa em cheia ascent+descent + lineSpacing 0).
  static pw.Widget _autoSizeText({
    required String text,
    required pw.Font styleFont,
    required PdfFont metricsFont,
    required double maxFontSize,
    required double minFontSize,
    required double maxWidth,
    required int maxLines,
    required PdfColor color,
    double letterSpacing = 0,
    double lineHeightScale = 0.8,
  }) {
    const step = 0.5;
    double fontSize = maxFontSize;

    // O stringMetrics retorna 0.0 para ESPAÇO (probe: A=0.663, sp=0.0) —
    // sem compensar, textos com muitos espaços passam no fits() e
    // estouram no render (cauda cortada). Espaço de grotesca ≈ 0.3em.
    const spaceFactor = 0.3;

    double lineWidth(String line, double size) {
      // stringMetrics é normalizado a fontSize=1 — width * size = pt real.
      final metrics = metricsFont.stringMetrics(line);
      final spaces = line.runes.where((r) => r == 0x20).length;
      return metrics.width * size +
          spaces * size * spaceFactor +
          (line.isEmpty ? 0 : (line.length - 1)) * letterSpacing;
    }

    List<String> wrap(double size) {
      final words = text.split(' ');
      final lines = <String>[];
      var current = '';
      for (final word in words) {
        final candidate = current.isEmpty ? word : '$current $word';
        if (lineWidth(candidate, size) <= maxWidth || current.isEmpty) {
          current = candidate;
        } else {
          lines.add(current);
          current = word;
        }
      }
      if (current.isNotEmpty) lines.add(current);
      return lines;
    }

    bool fits(List<String> lines, double size) {
      if (lines.length > maxLines) return false;
      return lines.every((l) => lineWidth(l, size) <= maxWidth);
    }

    var lines = wrap(fontSize);
    while (!fits(lines, fontSize) && fontSize > minFontSize) {
      fontSize -= step;
      lines = wrap(fontSize);
    }
    if (fontSize < minFontSize) fontSize = minFontSize;

    // Entrelinha −10%: avanço natural = caixa em cheia (ascent+descent,
    // tightBounds=false) + lineSpacing 0. O lineSpacing negativo tira a
    // fração (1-scale) exata dessa caixa, proporcional à fonte final.
    var emBox = metricsFont.ascent + metricsFont.descent.abs();
    if (emBox <= 0 || emBox > 2) emBox = 1.0;
    final gapTweak = (lineHeightScale - 1) * emBox * fontSize;

    return pw.Text(
      lines.join('\n'),
      maxLines: maxLines,
      textAlign: pw.TextAlign.center,
      overflow: pw.TextOverflow.clip,
      style: pw.TextStyle(
        font: styleFont,
        fontSize: fontSize,
        color: color,
        letterSpacing: letterSpacing,
        lineSpacing: gapTweak,
      ),
    );
  }
}
