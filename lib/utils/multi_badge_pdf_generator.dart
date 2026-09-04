import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/badge_data.dart';
import '../views/badge_view.dart';

class MultiBadgePdfGenerator {
  /// Gera um PDF com múltiplos crachás — cada um como uma página.
  /// O layout é idêntico ao PDF individual (widget BadgeView real renderizado como imagem).
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

      // Formato padrão de crachá: 54mm x 85mm
      const pageFormat = PdfPageFormat(
        54 * (72 / 25.4), // largura em pontos
        85 * (72 / 25.4), // altura em pontos
      );

      // Processa cada crachá — renderiza o widget BadgeView real como imagem
      for (int i = 0; i < badges.length; i++) {
        final BadgeData badge = badges[i];

        _updateProgress(
          progressController,
          progressTextController,
          i / badges.length,
          'Renderizando crachá ${i + 1} de ${badges.length}...',
        );

        // Renderiza o BadgeView real e captura como imagem
        final Uint8List badgeImageBytes =
            await _captureBadgeAsImage(badge, context);

        // Adiciona uma página ao PDF com a imagem do crachá
        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            build: (pw.Context pdfContext) => pw.Center(
              child: pw.Image(
                pw.MemoryImage(badgeImageBytes),
                fit: pw.BoxFit.contain,
              ),
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

  /// Renderiza o widget BadgeView real num overlay invisível e captura como imagem.
  static Future<Uint8List> _captureBadgeAsImage(
      BadgeData badge, BuildContext context) async {
    // Dimensões do BadgeView (333.4 x 523.19 conforme o widget)
    const double badgeWidth = 333.4;
    const double badgeHeight = 523.19;

    final completer = Completer<Uint8List>();

    // Cria um overlay entry invisível para renderizar o widget
    late OverlayEntry overlayEntry;

    final badgeWidget = Directionality(
      textDirection: TextDirection.ltr,
      child: Theme(
        data: Theme.of(context),
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            platformBrightness: Brightness.light,
          ),
          child: SizedBox(
            width: badgeWidth,
            height: badgeHeight,
            child: _BadgeCaptureWidget(
              badge: badge,
              onRendered: (bytes) {
                overlayEntry.remove();
                completer.complete(bytes);
              },
            ),
          ),
        ),
      ),
    );

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: MediaQuery.of(context).size.width + 1000,
        top: MediaQuery.of(context).size.height + 1000,
        child: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: badgeWidth,
            height: badgeHeight,
            child: badgeWidget,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    return completer.future;
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

/// Widget interno que renderiza o BadgeView e dispara a captura após o frame.
class _BadgeCaptureWidget extends StatefulWidget {
  final BadgeData badge;
  final ValueChanged<Uint8List> onRendered;

  const _BadgeCaptureWidget({
    required this.badge,
    required this.onRendered,
  });

  @override
  State<_BadgeCaptureWidget> createState() => _BadgeCaptureWidgetState();
}

class _BadgeCaptureWidgetState extends State<_BadgeCaptureWidget> {
  final GlobalKey _captureKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Captura no próximo frame após o widget ser montado
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  Future<void> _capture() async {
    try {
      // Força carregamento da fonte antes de renderizar (essencial para web)
      await _loadFontsAndWait();
      
      final boundary =
          _captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      widget.onRendered(bytes);
    } catch (e) {
      debugPrint('Erro ao capturar crachá: $e');
      widget.onRendered(Uint8List(0));
    }
  }

  /// Carrega fontes e aguarda múltiplos frames para garantir que foram aplicadas.
  Future<void> _loadFontsAndWait() async {
    const weights = [100, 200, 300, 400, 500, 600, 700, 800, 900];
    try {
      final fontLoader = FontLoader('Rawline');
      for (final w in weights) {
        final fontData =
            await rootBundle.load('assets/rawline/rawline-$w.ttf');
        fontLoader.addFont(Future.value(fontData));
      }
      await fontLoader.load();
    } catch (e) {
      debugPrint('Erro ao carregar fonte: $e');
    }
    // Aguarda 3 frames para garantir que a fonte foi aplicada ao texto
    for (int i = 0; i < 3; i++) {
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _captureKey,
      child: BadgeView(
        badgeData: widget.badge,
        onImageTap: () {},
        onNameTap: () {},
        onRoleTap: () {},
        onDepartmentTap: () {},
      ),
    );
  }
}
