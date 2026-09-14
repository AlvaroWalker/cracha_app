import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/badge_data.dart';
import '../views/badge_design.dart';
import '../views/badge_pdf_widget.dart';

class MultiBadgePdfGenerator {
  /// Gera um PDF com múltiplos crachás — cada um como uma página vetorial.
  ///
  /// Igual ao individual vetorial ([PdfVectorGenerator]): cada página usa
  /// [BadgePdfWidget.buildCard] (fonte única de verdade do layout). Sem
  /// screenshot/overlay — mais rápido e com texto selecionável.
  static Future<void> generateMultipleBadgesPdf(
      List<BadgeData> badges, BuildContext context) async {
    if (badges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum crachá selecionado.')),
      );
      return;
    }

    // Controlador para atualizar o progresso
    final progressController = ValueNotifier<double>(0.0);
    final progressTextController =
        ValueNotifier<String>('Preparando os crachás...');

    // Mostrar diálogo de progresso
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
      // Assets compartilhados (1× p/ o lote): mesma fonte/arte do individual.
      final fontData =
          await rootBundle.load('assets/rawline/rawline-700.ttf');
      final rawlineBold = pw.Font.ttf(fontData);

      final cardArtData = await rootBundle.load('assets/images/CRACHA.png');
      final cardArt = pw.MemoryImage(cardArtData.buffer.asUint8List());

      final placeholderData =
          await rootBundle.load('assets/images/placeholder.png');
      final placeholderPhoto =
          pw.MemoryImage(placeholderData.buffer.asUint8List());

      // Cria o documento PDF
      final pdf = pw.Document();

      // Formato padrão de crachá: 54mm x 85mm (igual ao individual vetorial).
      const mmToPt = 72 / 25.4;
      final pageWidth = 54 * mmToPt;
      final pageHeight = 85 * mmToPt;
      final pageFormat = PdfPageFormat(pageWidth, pageHeight, marginAll: 0);
      final scaleX = pageWidth / BadgeGeometry.cardWidth;
      final scaleY = pageHeight / BadgeGeometry.cardHeight;

      // Uma página vetorial por crachá — sem captura de tela.
      for (int i = 0; i < badges.length; i++) {
        final BadgeData badge = badges[i];

        _updateProgress(
          progressController,
          progressTextController,
          i / badges.length,
          'Montando crachá ${i + 1} de ${badges.length}...',
        );

        final pw.MemoryImage? photo =
            badge.photo != null ? pw.MemoryImage(badge.photo!) : null;

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            build: (pw.Context pdfContext) => BadgePdfWidget.buildCard(
              context: pdfContext,
              badge: badge,
              cardArt: cardArt,
              placeholderPhoto: placeholderPhoto,
              photo: photo,
              rawlineBold: rawlineBold,
              scaleX: scaleX,
              scaleY: scaleY,
            ),
          ),
        );
      }

      _updateProgress(progressController, progressTextController, 0.9,
          'Finalizando o documento...');

      // Salva o PDF
      final Uint8List pdfBytes = await pdf.save();

      // Nome do arquivo com a contagem de crachás
      final String filename = 'crachás_${badges.length}.pdf';

      _updateProgress(
          progressController, progressTextController, 1.0, 'PDF gerado!');
      await Future.delayed(const Duration(milliseconds: 500));

      // Fecha o diálogo de loading
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Compartilha o PDF
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: filename,
      );
    } catch (e) {
      // Fecha o diálogo de loading em caso de erro
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!context.mounted) return;

      // Mostra mensagem de erro
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 10),
                const Text('Erro'),
              ],
            ),
            content: Text('Não foi possível gerar o PDF: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  /// Atualiza o progresso do diálogo.
  static void _updateProgress(
    ValueNotifier<double> controller,
    ValueNotifier<String> textController,
    double value,
    String text,
  ) {
    controller.value = value;
    textController.value = text;
  }
}
