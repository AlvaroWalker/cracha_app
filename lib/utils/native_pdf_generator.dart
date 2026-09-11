import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/badge_data.dart';
import '../views/badge_design.dart';

/// Gerador VETORIAL de PDF (TESTE — branch `teste-pdf-vetorizado`).
///
/// Redesenha o crachá com primitivas do pacote `pdf` (texto real
/// selecionável). Geometria herdada de [BadgeGeometry].
class NativePdfGenerator {
  static Future<void> generateAndSharePdf(BadgeData badgeData) async {
    final bgData = await rootBundle.load('assets/images/CRACHA.png');

    Uint8List photoBytes;
    if (badgeData.photo != null) {
      photoBytes = badgeData.photo!;
    } else {
      final placeholderData =
          await rootBundle.load('assets/images/placeholder.png');
      photoBytes = placeholderData.buffer.asUint8List();
    }

    final fontData = await rootBundle.load('assets/rawline/rawline-700.ttf');

    final pdfBytes = await buildPdfBytes(
      badgeData: badgeData,
      bgBytes: bgData.buffer.asUint8List(),
      photoBytes: photoBytes,
      fontData: fontData,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: _sanitizeFilename(badgeData),
    );
  }

  /// Monta o PDF de forma pura (sem platform channels) — testável.
  static Future<Uint8List> buildPdfBytes({
    required BadgeData badgeData,
    required Uint8List bgBytes,
    required Uint8List photoBytes,
    required ByteData fontData,
  }) async {
    final pdf = pw.Document();

    final bgImage = pw.MemoryImage(bgBytes);
    final photoImage = pw.MemoryImage(photoBytes);
    final rawlineBold = pw.Font.ttf(fontData);

    // Escala: lógica 333.4×523.19 → 54×85mm do PDF.
    const double pdfWidth = 54 * PdfPageFormat.mm;
    const double pdfHeight = 85 * PdfPageFormat.mm;

    const double scaleX = pdfWidth / BadgeGeometry.cardWidth;
    const double scaleY = pdfHeight / BadgeGeometry.cardHeight;

    // Largura interna do cartão branco (trava a quebra de linha dos textos).
    const double infoW = BadgeGeometry.infoWidth * scaleX;

    final bool isNameEmpty = badgeData.name.trim().isEmpty;
    final bool isRoleEmpty = badgeData.role.trim().isEmpty;
    final bool isDeptEmpty = badgeData.department.trim().isEmpty;

    pw.Widget infoText(
      String text, {
      required double fontSize,
      required bool isPlaceholder,
    }) {
      // SizedBox com largura explícita: sem isso o texto não quebra linha
      // dentro do FittedBox (largura solta → 1 linha gigante → encolhe tudo).
      return pw.SizedBox(
        width: infoW,
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          maxLines: 2,
          style: pw.TextStyle(
            font: rawlineBold,
            fontSize: fontSize,
            color: isPlaceholder ? PdfColors.grey400 : PdfColors.black,
          ),
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(pdfWidth, pdfHeight),
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.Stack(
            alignment: pw.Alignment.center,
            children: [
              // Fundo do crachá (CRACHA.png).
              pw.Image(
                bgImage,
                width: pdfWidth,
                height: pdfHeight,
                fit: pw.BoxFit.fill,
              ),

              // Foto.
              pw.Positioned(
                top: BadgeGeometry.photoTop * scaleY,
                child: pw.Container(
                  width: BadgeGeometry.photoWidth * scaleX,
                  height: BadgeGeometry.photoHeight * scaleY,
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(13 * scaleX),
                    border: pw.Border.all(
                      color: PdfColors.white,
                      width: 1.5 * scaleX,
                    ),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 13 * scaleX,
                    verticalRadius: 13 * scaleX,
                    child: pw.Image(
                      photoImage,
                      fit: pw.BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // Cartão branco de informações.
              pw.Positioned(
                bottom: BadgeGeometry.infoBottom * scaleY,
                child: pw.Container(
                  width: BadgeGeometry.infoWidth * scaleX,
                  height: BadgeGeometry.infoHeight * scaleY,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(8 * scaleX),
                  ),
                  // Auto-ajuste (espelha o AutoSizeText da tela): textos
                  // longos encolhem o bloco em vez de cortar. Sem Spacer
                  // (flex explode com altura solta — ver histórico).
                  child: pw.FittedBox(
                    fit: pw.BoxFit.scaleDown,
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        infoText(
                          isNameEmpty
                              ? 'NOME DO FUNCIONÁRIO'
                              : badgeData.name,
                          fontSize: 10,
                          isPlaceholder: isNameEmpty,
                        ),
                        pw.SizedBox(height: 3),
                        infoText(
                          isRoleEmpty ? 'CARGO / FUNÇÃO' : badgeData.role,
                          fontSize: 7,
                          isPlaceholder: isRoleEmpty,
                        ),
                        pw.SizedBox(height: 3),

                        // Divisor (métricas do widget: 2px × indent 15).
                        pw.Divider(
                          color: PdfColors.black,
                          thickness: 2 * scaleY,
                          indent: 15 * scaleX,
                          endIndent: 15 * scaleX,
                        ),
                        pw.SizedBox(height: 3),

                        infoText(
                          isDeptEmpty
                              ? 'SECRETARIA / DEPARTAMENTO'
                              : badgeData.department,
                          fontSize: 7,
                          isPlaceholder: isDeptEmpty,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static String _sanitizeFilename(BadgeData badgeData) {
    String sanitize(String s) => s
        .replaceAll('/', '-')
        .replaceAll('\\', '-')
        .replaceAll(':', '-')
        .replaceAll('*', '-')
        .replaceAll('?', '-')
        .replaceAll('"', '-')
        .replaceAll('<', '-')
        .replaceAll('>', '-')
        .replaceAll('|', '-');

    final name = badgeData.name.trim();
    final department = badgeData.department.trim();
    if (name.isNotEmpty && department.isNotEmpty) {
      return '${sanitize(name)} - ${sanitize(department)}.pdf';
    } else if (name.isNotEmpty) {
      return '${sanitize(name)}.pdf';
    } else if (department.isNotEmpty) {
      return '${sanitize(department)}.pdf';
    }
    return 'cracha.pdf';
  }
}
