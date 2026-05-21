import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/badge_data.dart';

class PdfGenerator {
  static Future<void> generateAndSharePdf(GlobalKey key, BuildContext context,
      {BadgeData? badgeData}) async {
    // Controlador para atualizar o progresso
    final progressController = ValueNotifier<double>(0.0);
    final progressTextController =
        ValueNotifier<String>('Iniciando o processo...');

    // Função para atualizar o progresso
    void updateProgress(double value, String text) {
      if (context.mounted) {
        progressController.value = value;
        progressTextController.value = text;
      }
    }

    // Mostrar diálogo de carregamento com progresso
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
      // Adiciona um pequeno delay para garantir que o diálogo seja exibido
      await Future.delayed(const Duration(milliseconds: 100));

      // Captura a imagem do widget
      updateProgress(0.2, 'Capturando a imagem do crachá...');
      await Future.delayed(const Duration(milliseconds: 300));

      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      updateProgress(0.4, 'Processando a imagem...');
      await Future.delayed(const Duration(milliseconds: 200));

      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List imageBytes = byteData!.buffer.asUint8List();

      // Cria o documento PDF
      updateProgress(0.6, 'Gerando o documento PDF...');
      await Future.delayed(const Duration(milliseconds: 300));

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(54 * (72 / 25.4), 85 * (72 / 25.4)),
          build: (context) => pw.Center(
            child: pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.contain),
          ),
        ),
      );

      // Salva o PDF
      updateProgress(0.8, 'Finalizando o documento...');
      await Future.delayed(const Duration(milliseconds: 300));

      final Uint8List pdfBytes = await pdf.save();

      // Define o nome do arquivo baseado no nome e secretaria do usuário
      String filename = 'cracha.pdf';
      if (badgeData != null) {
        if (badgeData.name.isNotEmpty) {
          String name = badgeData.name.trim();
          String department = badgeData.department.trim();

          // Se ambos nome e secretaria estão presentes
          if (name.isNotEmpty && department.isNotEmpty) {
            filename = '$name - $department.pdf';
          }
          // Se apenas o nome está presente
          else if (name.isNotEmpty) {
            filename = '$name.pdf';
          }
        }
      }

      updateProgress(1.0, 'PDF gerado com sucesso!');
      await Future.delayed(const Duration(milliseconds: 500));

      // Fecha o diálogo de loading
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // Compartilha o PDF com o nome personalizado
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

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
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
                Text(
                  'Ocorreu um erro ao gerar o PDF.',
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
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
                child: Text(
                  'OK',
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2E7D32),
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
