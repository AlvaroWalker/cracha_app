// ═══════════════════════════════════════════════════════════════════════════
// GERAÇÃO DE PDF EM LOTE COMO IMAGEM (300 DPI).
//
// POR QUE IMAGEM, E NÃO VETORIAL
//
// O `dart_pdf` e o Skia leem tabelas DIFERENTES do mesmo TTF. Medido
// (ver `test/inkbox_probe_test.dart`):
//
//     Skia     ascent 0.7500  descent 0.2500  caixa 1.0000   (OS/2 typo)
//     dart_pdf ascent 1.1279  descent 0.2485  caixa 1.3765   (hhea)
//
// 37.6% de divergência na MESMA fonte. Daí vinham, silenciosamente: palavra
// órfã ("E" isolado), `TextOverflow.clip` engolendo a continuação, e o
// `pw.Column` descartando a secretaria inteira. Nenhum número mágico corrige
// uma divergência entre duas engines de medição.
//
// Montando o [BadgeView] e capturando o [RepaintBoundary], quem decide o
// layout é o Skia — o mesmo motor do preview. A imagem entra no PDF sem
// qualquer medição de texto, então os dois lados não podem divergir.
//
// ── POR QUE PRECISA DE UM STAGE OCULTO ─────────────────────────────────────
// O botão individual já tem o [BadgeView] montado na tela; o lote não. Para
// gerar 200 crachás, cada um precisa EXISTIR na árvore de widgets com layout
// resolvido antes do `toImage()`.
//
// `Offstage`/`Visibility(hidden)` NÃO servem: o Flutter não rasteriza
// widgets fora da tela, e `toImage()` volta vazio. A solução é um
// [Overlay] posicionado FORA da viewport mas ainda "vivo" para o rasterizador
// — com opacidade baixíssima em vez de zero (zero é pulado na composição).
// ═══════════════════════════════════════════════════════════════════════════
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/badge_data.dart';
import '../views/badge_design.dart';

class MultiBadgeImagePdfGenerator {
  /// Largura lógica do palco em px.
  ///
  /// Não é a resolução de saída: o `toImage(pixelRatio: 3.125)` escala. O
  /// que este número define é a PRECISÃO com que o Skia rasteriza antes de
  /// escalar — mais alto = mais nitidez no vetor-&-raster, a custo de memória.
  /// 520px dá 1625px de saída a 300 DPI, folgado para 54×85mm.
  static const double _stageWidth = 520.0;

  /// Altura do palco, derivada da proporção do crachá (54:85).
  static const double _stageHeight = _stageWidth * 85 / 54; // ~818.5

  /// 300 DPI: pixel lógico web = 1/96in → 300/96 = 3.125.
  /// 54×85mm a 300 DPI = 638×1004px.
  static const double _exportPixelRatio = 300 / 96;

  /// Opacidade do stage oculto.
  ///
  /// Não pode ser 0: o compositor descarta totalmente opaco-nulo e o
  /// `toImage()` sai vazio. 0.01 mantém o widget vivo para o rasterizador
  /// sem o usuario enxergar nada.
  static const double _stageOpacity = 0.01;

  static const double _mmToPt = 72 / 25.4;
  static const double _pageWidth = 54 * _mmToPt; // 153.07pt
  static const double _pageHeight = 85 * _mmToPt; // 240.94pt

  /// Gera um PDF com uma página por crachá, cada página sendo a CAPTURA do
  /// [BadgeView] a 300 DPI.
  static Future<void> generateMultipleBadgesPdf(
    List<BadgeData> badges,
    BuildContext context,
  ) async {
    if (badges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum crachá selecionado.')),
      );
      return;
    }

    final progressValue = ValueNotifier<double>(0.0);
    final progressText = ValueNotifier<String>('Preparando os crachás...');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: ValueListenableBuilder<String>(
            valueListenable: progressText,
            builder: (context, text, _) =>
                ValueListenableBuilder<double>(
              valueListenable: progressValue,
              builder: (context, progress, _) => SizedBox(
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
                              valueColor: const AlwaysStoppedAnimation<Color>(
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
                      style: const TextStyle(fontFamily: 'Rawline', fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    try {
      final pdf = pw.Document();
      final pageFormat =
          PdfPageFormat(_pageWidth, _pageHeight, marginAll: 0);

      // Captura UM por UM: manter 200 widgets montados simultâneos estouraria
      // memória e o compositor nunca pintaria nenhum deles.
      for (var i = 0; i < badges.length; i++) {
        final badge = badges[i];

        progressValue.value = i / badges.length;
        progressText.value =
            'Capturando crachá ${i + 1} de ${badges.length}...';

        final imageBytes = await _captureOne(context, badge);
        if (imageBytes == null) {
          // Um badge que falhou não pode derrubar o lote inteiro — mas o
          // usuário precisa saber. Lançamos para o catch tratar, porque
          // gerar um PDF silenciosamente incompleto é pior que falhar.
          throw StateError(
              'Não foi possível capturar o crachá ${i + 1} (${badge.name}).');
        }

        pdf.addPage(pw.Page(
          pageFormat: pageFormat,
          // COVER e não CONTAIN: a captura já tem a proporção do crachá
          // (54/85 = 0.635, validado em test/pdf_image_path_test.dart), então
          // contain deixaria margem branca. Cover preenche 54×85mm exatos
          // cortando ~0.15mm de margem invisível.
          build: (_) => pw.Image(
            pw.MemoryImage(imageBytes),
            fit: pw.BoxFit.cover,
          ),
        ));
      }

      progressValue.value = 0.95;
      progressText.value = 'Finalizando o documento...';

      final pdfBytes = await pdf.save();

      progressValue.value = 1.0;
      progressText.value = 'PDF gerado!';
      await Future.delayed(const Duration(milliseconds: 400));

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'crachás_${badges.length}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 10),
              Text('Erro'),
            ],
          ),
          content: Text('Não foi possível gerar o PDF: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      progressValue.dispose();
      progressText.dispose();
    }
  }

  /// Monta UM badge num stage invisível, captura a 300 DPI e devolve os bytes.
  ///
  /// O stage vive num [Overlay] fora da viewport mas com opacidade 0.01 —
  /// assim o Flutter o rasteriza (necessário pro `toImage`) sem o usuário
  /// ver. Ver a nota sobre [Overlay] no topo do arquivo.
  static Future<Uint8List?> _captureOne(
    BuildContext context,
    BadgeData badge,
  ) async {
    final key = GlobalKey();

    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (BuildContext overlayContext) => Positioned(
        // Fora da viewport, mas ainda no plano do compositor.
        left: -_stageWidth * 2,
        top: 0,
        // O `Overlay` posiciona os filhos com restrições INFINITAS (ele é um
        // `CustomMultiChildLayoutBox` que se ajusta ao próprio tamanho). Sem
        // largura/altura explícitas, o `MaterialApp` aninhado explode com
        // "given an infinite size during layout".
        width: _stageWidth + 40,
        height: _stageHeight + 40,
        child: IgnorePointer(
          child: Opacity(
            opacity: _stageOpacity,
            child: MaterialApp(
              // MaterialApp isolado: o BadgeView usa Ink/Icon que exigem
              // um Material/Theme/IP ancestors. Reaproveitar o do app real
              // seria mais leve, mas o lote pode ser gerado de qualquer rota.
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                backgroundColor: const Color(0xFFFFFFFF),
                body: Center(
                  child: buildBadgeStage(
                    globalKey: key,
                    badge: badge,
                    boxWidth: _stageWidth,
                    onImageTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // `insert`/`remove` mexem no markNeedsBuild do Overlay. NUNCA podem
    // rodar durante o build de um widget — o Flutter lança
    // "setState() or markNeedsBuild() called during build". Aqui já estamos
    // num callback de botão (fora do build), então é seguro.
    overlay.insert(entry);
    try {
      // O frame precisa PINTAR antes de capturar: `toImage` exige o layout
      // resolvido e a camada já rasterizada. Três frames: o 1º insere o
      // entry, o 2º faz layout da árvore nova, o 3º rasteriza o resultado.
      await _waitFrames(3);

      final boundary = _findBoundary(key);
      if (boundary == null) {
        return null;
      }

      final image = await boundary.toImage(pixelRatio: _exportPixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List();
    } finally {
      entry.remove();
      // Dá um frame pro Overlay processar a remoção antes do próximo badge.
      await _waitFrames(1);
    }
  }

  /// Aguarda N frames renderizados.
  ///
  /// `Future.delayed` sozinho não garante nada: no Flutter web o frame é
  /// agendado no event loop do browser. Esperar `endOfFrame` garante que o
  /// frame passou pelo pipeline completo (layout → paint → composite).
  static Future<void> _waitFrames(int frames) async {
    final binding = SchedulerBinding.instance;
    for (var i = 0; i < frames; i++) {
      await binding.endOfFrame;
    }
  }

  /// Localiza o [RenderRepaintBoundary] sob a [key] do palco.
  static RenderRepaintBoundary? _findBoundary(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null || !ctx.mounted) return null;
    final ro = ctx.findRenderObject();
    return ro is RenderRepaintBoundary ? ro : null;
  }
}
