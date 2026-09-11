import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/badge_data.dart';
import '../views/badge_design.dart';
import '../views/badge_pdf_widget.dart';

// Gerador VETORIAL via BadgePdfWidget (TESTE — branch `teste-pdf-vetorizado`).
//
// Desenha o crachá com primitivas pw (texto selecionável), medindo fontes
// com PdfFont.stringMetrics (autosize manual). Sem screenshot — funciona
// em qualquer tamanho de palco e não depende de GlobalKey.
//
// Mantém o mesmo diálogo de progresso do gerador por captura.
class PdfVectorGenerator {
  static Future<void> generateAndSharePdf(
    BuildContext context, {
    required BadgeData badgeData,
  }) async {
    final progressController = ValueNotifier<double>(0.0);
    final progressTextController =
        ValueNotifier<String>('Iniciando o processo...');

    void updateProgress(double value, String text) {
      if (context.mounted) {
        progressController.value = value;
        progressTextController.value = text;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            content: ValueListenableBuilder<String>(
              valueListenable: progressTextController,
              builder: (context, text, _) {
                return ValueListenableBuilder<double>(
                  valueListenable: progressController,
                  builder: (context, progress, _) {
                    return SizedBox(
                      height: 120,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 4,
                                    backgroundColor: Colors.grey[200],
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Color(0xFF2E7D32)),
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontFamily: 'Rawline',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            text,
                            style: const TextStyle(
                              fontFamily: 'Rawline',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );

    try {
      await Future.delayed(const Duration(milliseconds: 100));

      updateProgress(0.2, 'Carregando fontes e imagens...');

      // Rawline Bold — mesmo arquivo registrado no pubspec.
      final fontData =
          await rootBundle.load('assets/rawline/rawline-700.ttf');
      final rawlineBold = pw.Font.ttf(fontData);

      final cardArtData = await rootBundle.load('assets/images/CRACHA.png');
      final cardArt = pw.MemoryImage(cardArtData.buffer.asUint8List());

      final placeholderData =
          await rootBundle.load('assets/images/placeholder.png');
      final placeholderPhoto =
          pw.MemoryImage(placeholderData.buffer.asUint8List());

      final pw.MemoryImage? photo =
          badgeData.photo != null ? pw.MemoryImage(badgeData.photo!) : null;

      updateProgress(0.5, 'Montando o crachá...');
      await Future.delayed(const Duration(milliseconds: 200));

      final pdf = pw.Document();

      const double mmToPt = 72 / 25.4;
      final pageWidth = 54 * mmToPt;
      final pageHeight = 85 * mmToPt;

      // Escala anisotrópica: o cartão (333.4×523.19) preenche 54×85mm
      // exatos sem cortar nem sobrar margem (distorção < 0.5%).
      final scaleX = pageWidth / BadgeGeometry.cardWidth;
      final scaleY = pageHeight / BadgeGeometry.cardHeight;

      updateProgress(0.7, 'Gerando o documento PDF...');
      await Future.delayed(const Duration(milliseconds: 300));

      pdf.addPage(
        pw.Page(
          pageFormat:
              PdfPageFormat(pageWidth, pageHeight, marginAll: 0),
          build: (pdfContext) => BadgePdfWidget.buildCard(
            context: pdfContext,
            badge: badgeData,
            cardArt: cardArt,
            placeholderPhoto: placeholderPhoto,
            photo: photo,
            rawlineBold: rawlineBold,
            scaleX: scaleX,
            scaleY: scaleY,
          ),
        ),
      );

      updateProgress(0.9, 'Finalizando o documento...');
      await Future.delayed(const Duration(milliseconds: 300));

      final Uint8List pdfBytes = await pdf.save();

      String filename = 'cracha.pdf';
      {
        String name = badgeData.name.trim();
        String department = badgeData.department.trim();

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

        if (name.isNotEmpty && department.isNotEmpty) {
          filename = '${sanitize(name)} - ${sanitize(department)}.pdf';
        } else if (name.isNotEmpty) {
          filename = '${sanitize(name)}.pdf';
        } else if (department.isNotEmpty) {
          filename = '${sanitize(department)}.pdf';
        }
      }

      updateProgress(1.0, 'PDF gerado com sucesso!');
      await Future.delayed(const Duration(milliseconds: 500));

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: filename,
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 10),
                Text(
                  'Erro',
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ocorreu um erro ao gerar o PDF.',
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Detalhes: ${e.toString()}',
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }
}
