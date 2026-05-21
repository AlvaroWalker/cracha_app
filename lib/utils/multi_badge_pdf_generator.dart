import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/badge_data.dart';
import '../utils/app_colors.dart';

class MultiBadgePdfGenerator {
  // Método para gerar um PDF com múltiplos crachás
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
      // Cria o documento PDF
      final pdf = pw.Document();

      // Função para atualizar o progresso
      void updateProgress(double value, String text) {
        if (context.mounted) {
          progressController.value = value;
          progressTextController.value = text;
        }
      }

      // Adiciona um pequeno delay para garantir que o diálogo seja exibido
      await Future.delayed(const Duration(milliseconds: 100));

      // Carregar a imagem do brasão para o PDF
      ByteData brasaoData;
      try {
        brasaoData = await rootBundle.load('assets/brasao.png');
      } catch (e) {
        // Se não conseguir carregar o brasão, continua sem ele
        brasaoData = ByteData(0);
        debugPrint('Não foi possível carregar o brasão: $e');
      }

      final Uint8List brasaoBytes = brasaoData.buffer.asUint8List();
      final brasaoPdf =
          brasaoBytes.isNotEmpty ? pw.MemoryImage(brasaoBytes) : null;

      // Processa cada crachá
      for (int i = 0; i < badges.length; i++) {
        final BadgeData badge = badges[i];

        updateProgress(
          i / badges.length,
          'Processando crachá ${i + 1} de ${badges.length}...',
        );

        // Adiciona uma página ao PDF para cada crachá
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(54 * (72 / 25.4), 85 * (72 / 25.4)),
            build: (pw.Context context) {
              return pw.Column(
                children: [
                  // Cabeçalho com brasão
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    color: PdfColor.fromInt(
                        0xFF2E7D32), // Verde (AppColors.primaryColor)
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        if (brasaoPdf != null) pw.Image(brasaoPdf, height: 40),
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          child: pw.Text(
                            "PREFEITURA MUNICIPAL",
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Foto
                  pw.Expanded(
                    flex: 5,
                    child: pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(8),
                      child: badge.photo != null
                          ? pw.Image(pw.MemoryImage(badge.photo!),
                              fit: pw.BoxFit.contain)
                          : pw.Center(
                              child: pw.Text('Sem foto',
                                  style: pw.TextStyle(
                                    color: PdfColors.grey,
                                    fontSize: 16,
                                  ))),
                    ),
                  ),

                  // Informações do funcionário
                  pw.Expanded(
                    flex: 3,
                    child: pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      color: PdfColor.fromInt(
                          0xFFE8F5E9), // Equivalente a AppColors.lightGreen
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            badge.name,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            badge.role,
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(
                              fontSize: 14,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            badge.department,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }

      updateProgress(0.9, 'Finalizando o documento...');

      // Salva o PDF
      final Uint8List pdfBytes = await pdf.save();

      // Nome do arquivo com a contagem de crachás
      final String filename = 'crachás_${badges.length}.pdf';

      updateProgress(1.0, 'PDF gerado com sucesso!');
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

  // Widget para construir o conteúdo de um crachá
  static Widget buildBadgeContent(BadgeData badge) {
    return Column(
      children: [
        // Cabeçalho com brasão
        Container(
          padding: const EdgeInsets.all(8),
          color: AppColors.primaryColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/brasao.png', height: 40),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "PREFEITURA MUNICIPAL",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Rawline',
                  ),
                ),
              ),
            ],
          ),
        ),

        // Foto
        Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            child: badge.photo != null
                ? Image.memory(badge.photo!, fit: BoxFit.contain)
                : const Icon(Icons.person, size: 100, color: Colors.grey),
          ),
        ),

        // Informações do funcionário
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: AppColors.lightGreen,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  badge.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: 'Rawline',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.role,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Rawline',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.department,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Rawline',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
