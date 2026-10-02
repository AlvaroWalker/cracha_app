import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/badge_data.dart';
import '../views/badge_assets.dart';
import '../views/badge_geometry.dart' show CrachaDados, FotoAjuste;
import 'cracha_vector_pdf_service.dart';
import 'pdf_reference_page.dart';

class PdfGenerator {
  /// Gera o PDF vetorial de um crachá (usado pelo botão de exportar).
  ///
  /// Encaminha para [CrachaVectorPdfService], que resolve o layout com o
  /// Skia e desenha o texto como vetor — sem `pw.Text`, sem `pw.Column`,
  /// sem nada que possa descartar uma linha.
  static Future<Uint8List> gerarVetorial(BadgeData badge) async {
    // `await` nos dois: o serviço recebe `ui.Image`, mas o cache devolve o
    // Future memoizado. Sem o await o compilador rejeita — e sem ele o PDF
    // receberia um Future no lugar da imagem.
    final fundo = await fundoDoCracha();
    final foto = await fotoDoBadge(badge) ?? await fotoPadrao();

    return CrachaVectorPdfService.gerar(
      dados: CrachaDados(
        nome: badge.name.trim().isEmpty ? 'NOME DO SERVIDOR' : badge.name.trim(),
        cargo: badge.role.trim().isEmpty ? 'CARGO DO SERVIDOR' : badge.role.trim(),
        secretaria: badge.department.trim().isEmpty
            ? 'SECRETARIA'
            : badge.department.trim(),
      ),
      ajuste: const FotoAjuste(),
      fundo: fundo,
      foto: foto,
    );
  }

  /// Nome do arquivo: "Nome - Secretaria.pdf", sanitizado.
  static String _filenameFor(BadgeData badge) {
    final nome = badge.name.trim();
    final dept = badge.department.trim();

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

    if (nome.isNotEmpty && dept.isNotEmpty) {
      return '${sanitize(nome)} - ${sanitize(dept)}.pdf';
    }
    if (nome.isNotEmpty) return '${sanitize(nome)}.pdf';
    if (dept.isNotEmpty) return '${sanitize(dept)}.pdf';
    return 'cracha.pdf';
  }
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
          // PDF VETORIAL: fundo+foto raster, texto vetorial. Ver
          // `cracha_vector_pdf_service.dart`.
          //
          // Não precisa mais do RepaintBoundary: o layout vem do `CrachaLayout`
          // (medido com o Skia) e o texto sai como `drawString`. `key` fica no
          // contrato porque [buildBadgePdfBytes] ainda usa.
          updateProgress(0.3, 'Preparando o documento...');
          await Future.delayed(const Duration(milliseconds: 200));

          final alvo = badgeData ?? BadgeData();
          final pdfBytes = await gerarVetorial(alvo);

          updateProgress(1.0, 'PDF gerado com sucesso!');
          await Future.delayed(const Duration(milliseconds: 400));

          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          await Printing.sharePdf(
            bytes: pdfBytes,
            filename: _filenameFor(alvo),
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

  /// Captura o crachá e monta o PDF, devolvendo os bytes (sem diálogos).
  ///
  /// Usado pelo preview antes de compartilhar. Separado de
  /// [generateAndSharePdf] de propósito para não mexer no fluxo que
  /// já funciona.
  static Future<Uint8List> buildBadgePdfBytes(
    GlobalKey key, {
    BadgeData? badgeData,
  }) async {
    RenderRepaintBoundary? boundary;
    for (int i = 0; i < 20; i++) {
      final ctx = key.currentContext;
      if (ctx != null && ctx.mounted) {
        final ro = ctx.findRenderObject();
        if (ro is RenderRepaintBoundary) {
          boundary = ro;
          break;
        }
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (boundary == null) {
      throw Exception('Não foi possível capturar o crachá. Tente novamente.');
    }

    // 300 DPI (mesmo padrão do compartilhamento).
    const exportPixelRatio = 300 / 96;
    final ui.Image image =
        await boundary.toImage(pixelRatio: exportPixelRatio);
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List imageBytes = byteData!.buffer.asUint8List();

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(54 * (72 / 25.4), 85 * (72 / 25.4)),
        build: (context) => pw.Center(
          child: pw.Image(pw.MemoryImage(imageBytes), fit: pw.BoxFit.cover),
        ),
      ),
    );
    await appendReferencePage(pdf);
    return pdf.save();
  }
}
