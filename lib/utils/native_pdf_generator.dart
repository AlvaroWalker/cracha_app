import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/badge_data.dart';
import '../views/badge_design.dart';

/// Gerador VETORIAL de PDF v2 (TESTE — branch `teste-pdf-vetorizado`).
///
/// Versão enviada para teste: fundo `Positioned.fill` + `cover`, fontes
/// Helvetica bold escaladas, sem fonte customizada.
class PdfGeneratorNative {
  static Future<void> generateAndSharePdf(BadgeData badgeData) async {
    final pdf = pw.Document();

    // 1. Carregar imagem de fundo e foto
    final bgData = await rootBundle.load('assets/images/CRACHA.png');
    final bgImage = pw.MemoryImage(bgData.buffer.asUint8List());

    pw.MemoryImage? photoImage;
    if (badgeData.photo != null) {
      photoImage = pw.MemoryImage(badgeData.photo!);
    } else {
      try {
        final placeholderData =
            await rootBundle.load('assets/images/placeholder.png');
        photoImage = pw.MemoryImage(placeholderData.buffer.asUint8List());
      } catch (_) {
        photoImage = null;
      }
    }

    // 2. Dimensões do cartão (54mm x 85mm) e Fatores de Escala
    const double pdfWidth = 54 * PdfPageFormat.mm;
    const double pdfHeight = 85 * PdfPageFormat.mm;

    const double scaleX = pdfWidth / BadgeGeometry.cardWidth;
    const double scaleY = pdfHeight / BadgeGeometry.cardHeight;

    final bool isNameEmpty = badgeData.name.trim().isEmpty;
    final bool isRoleEmpty = badgeData.role.trim().isEmpty;
    final bool isDeptEmpty = badgeData.department.trim().isEmpty;

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(pdfWidth, pdfHeight),
        margin: pw.EdgeInsets.zero,
        build: (pw.Context context) {
          return pw.SizedBox(
            width: pdfWidth,
            height: pdfHeight,
            child: pw.Stack(
              alignment: pw.Alignment.center,
              children: [
                // Imagem de Fundo (CRACHA.png)
                pw.Positioned.fill(
                  child: pw.Image(bgImage, fit: pw.BoxFit.cover),
                ),

                // Seção da Foto
                pw.Positioned(
                  top: BadgeGeometry.photoTop * scaleY,
                  child: pw.Container(
                    width: BadgeGeometry.photoWidth * scaleX,
                    height: BadgeGeometry.photoHeight * scaleY,
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(14 * scaleX),
                      border: pw.Border.all(
                        color: PdfColors.white,
                        width: 1.5 * scaleX,
                      ),
                    ),
                    // pw.ClipRRect NÃO tem borderRadius (só
                    // horizontal/verticalRadius) — ver commit anterior.
                    child: pw.ClipRRect(
                      horizontalRadius: 13 * scaleX,
                      verticalRadius: 13 * scaleX,
                      child: photoImage != null
                          ? pw.Image(photoImage, fit: pw.BoxFit.cover)
                          : pw.Container(color: PdfColors.grey300),
                    ),
                  ),
                ),

                // Seção de Informações (Cartão Branco)
                pw.Positioned(
                  bottom: BadgeGeometry.infoBottom * scaleY,
                  child: pw.Container(
                    width: BadgeGeometry.infoWidth * scaleX,
                    height: BadgeGeometry.infoHeight * scaleY,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(8 * scaleX),
                    ),
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 3,
                    ),
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        // Nome e Cargo
                        pw.Column(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(
                              isNameEmpty
                                  ? 'NOME DO FUNCIONÁRIO'
                                  : badgeData.name,
                              textAlign: pw.TextAlign.center,
                              maxLines: 2,
                              style: pw.TextStyle(
                                fontSize: 10 * scaleY,
                                fontWeight: pw.FontWeight.bold,
                                color: isNameEmpty
                                    ? PdfColors.grey400
                                    : PdfColors.black,
                              ),
                            ),
                            pw.SizedBox(height: 2 * scaleY),
                            pw.Text(
                              isRoleEmpty ? 'CARGO / FUNÇÃO' : badgeData.role,
                              textAlign: pw.TextAlign.center,
                              maxLines: 2,
                              style: pw.TextStyle(
                                fontSize: 7.5 * scaleY,
                                fontWeight: pw.FontWeight.bold,
                                color: isRoleEmpty
                                    ? PdfColors.grey400
                                    : PdfColors.black,
                              ),
                            ),
                          ],
                        ),

                        // Divisor
                        pw.Divider(
                          color: PdfColors.black,
                          thickness: 1 * scaleY,
                          indent: 10 * scaleX,
                          endIndent: 10 * scaleX,
                        ),

                        // Secretaria / Departamento
                        pw.Text(
                          isDeptEmpty
                              ? 'SECRETARIA / DEPARTAMENTO'
                              : badgeData.department,
                          textAlign: pw.TextAlign.center,
                          maxLines: 2,
                          style: pw.TextStyle(
                            fontSize: 7.5 * scaleY,
                            fontWeight: pw.FontWeight.bold,
                            color: isDeptEmpty
                                ? PdfColors.grey400
                                : PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    final Uint8List pdfBytes = await pdf.save();

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: _sanitizeFilename(badgeData.name.trim()),
    );
  }

  static String _sanitizeFilename(String name) {
    final clean = name
        .replaceAll('/', '-')
        .replaceAll('\\', '-')
        .replaceAll(':', '-')
        .replaceAll('*', '-')
        .replaceAll('?', '-')
        .replaceAll('"', '-')
        .replaceAll('<', '-')
        .replaceAll('>', '-')
        .replaceAll('|', '-');
    return clean.isEmpty ? 'cracha.pdf' : '$clean.pdf';
  }
}
