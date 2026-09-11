import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/badge_data.dart';
import '../views/badge_design.dart';

/// Gerador VETORIAL de PDF (TESTE — branch `teste-pdf-vetorizado`).
///
/// Diferença do [PdfGenerator]: em vez de capturar screenshot do widget,
/// redesenha o crachá com primitivas do pacote `pdf` (texto real
/// selecionável, vetores nítidos em qualquer zoom).
///
/// Geometria herdada de [BadgeGeometry] para manter proporção idêntica.
class NativePdfGenerator {
  static Future<void> generateAndSharePdf(BadgeData badgeData) async {
    final pdf = pw.Document();

    // 1. Imagens dos assets (fundo + foto/placeholder).
    final bgImageByteData = await rootBundle.load('assets/images/CRACHA.png');
    final bgImage = pw.MemoryImage(bgImageByteData.buffer.asUint8List());

    pw.ImageProvider photoImage;
    if (badgeData.photo != null) {
      photoImage = pw.MemoryImage(badgeData.photo!);
    } else {
      final placeholderByteData =
          await rootBundle.load('assets/images/placeholder.png');
      photoImage = pw.MemoryImage(placeholderByteData.buffer.asUint8List());
    }

    // 2. Fonte Rawline Bold (mesmo arquivo do pubspec: rawline-700).
    final fontData = await rootBundle.load('assets/rawline/rawline-700.ttf');
    final rawlineBold = pw.Font.ttf(fontData);

    // 3. Escala: lógica 333.4×523.19 → 54×85mm do PDF.
    const double pdfWidth = 54 * PdfPageFormat.mm;
    const double pdfHeight = 85 * PdfPageFormat.mm;

    const double scaleX = pdfWidth / BadgeGeometry.cardWidth;
    const double scaleY = pdfHeight / BadgeGeometry.cardHeight;

    final bool isNameEmpty = badgeData.name.trim().isEmpty;
    final bool isRoleEmpty = badgeData.role.trim().isEmpty;
    final bool isDeptEmpty = badgeData.department.trim().isEmpty;

    // 4. Página com layout espelhado no BadgeView.
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
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Spacer(),

                      // Nome e cargo.
                      pw.Column(
                        children: [
                          pw.Text(
                            isNameEmpty
                                ? 'NOME DO FUNCIONÁRIO'
                                : badgeData.name,
                            textAlign: pw.TextAlign.center,
                            maxLines: 2,
                            style: pw.TextStyle(
                              font: rawlineBold,
                              fontSize: 10,
                              color: isNameEmpty
                                  ? PdfColors.grey400
                                  : PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            isRoleEmpty ? 'CARGO / FUNÇÃO' : badgeData.role,
                            textAlign: pw.TextAlign.center,
                            maxLines: 2,
                            style: pw.TextStyle(
                              font: rawlineBold,
                              fontSize: 7,
                              color: isRoleEmpty
                                  ? PdfColors.grey400
                                  : PdfColors.black,
                            ),
                          ),
                        ],
                      ),

                      pw.Spacer(),

                      // Divisor.
                      pw.Divider(
                        color: PdfColors.black,
                        thickness: 1,
                        indent: 10 * scaleX,
                        endIndent: 10 * scaleX,
                      ),

                      pw.Spacer(),

                      // Secretaria.
                      pw.Text(
                        isDeptEmpty
                            ? 'SECRETARIA / DEPARTAMENTO'
                            : badgeData.department,
                        textAlign: pw.TextAlign.center,
                        maxLines: 2,
                        style: pw.TextStyle(
                          font: rawlineBold,
                          fontSize: 7,
                          color: isDeptEmpty
                              ? PdfColors.grey400
                              : PdfColors.black,
                        ),
                      ),

                      pw.Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // 5. Salva e compartilha.
    final Uint8List pdfBytes = await pdf.save();

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: _sanitizeFilename(badgeData),
    );
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
