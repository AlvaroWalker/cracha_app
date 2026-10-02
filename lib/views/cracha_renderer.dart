// ═══════════════════════════════════════════════════════════════════════════
// DESENHO DO CRACHÁ — usado pelo preview E pela camada raster do PDF.
//
// O ponto central deste arquivo é [CrachaRenderer.medir]: é ele que
// implementa [Medidor] com o `TextPainter` do Skia, e é ELE que o
// `CrachaLayout` usa para quebrar as linhas. O `dart_pdf` nunca mede —
// recebe posições já resolvidas.
//
// Se alguém trocar `medir` por uma medição do dart_pdf, os dois lados
// voltam a divergir em 37,6% e o texto volta a sumir. É o único ponto
// sensível do desenho.
// ═══════════════════════════════════════════════════════════════════════════
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'badge_geometry.dart';

/// Desenho do crachá em coordenadas de design (1273 × 2004).
abstract final class CrachaRenderer {
  CrachaRenderer._();

  static const fontFamily = 'Rawline';
  static const cor = Color(0xFF333333);
  static const _branco = Color(0xFFFFFFFF);

  static FontWeight pesoDe(int p) => switch (p) {
        600 => FontWeight.w600,
        800 => FontWeight.w800,
        _ => FontWeight.w700,
      };

  static TextPainter _textPainter(String texto, int peso, double size) =>
      TextPainter(
        text: TextSpan(
          text: texto,
          style: TextStyle(
            fontFamily: fontFamily,
            fontWeight: pesoDe(peso),
            fontSize: size,
            color: cor,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout();

  /// Implementa [Medidor] com a fonte Rawline real (Skia).
  static double medir(String texto, int peso, double size) {
    final tp = _textPainter(texto, peso, size);
    final largura = tp.width;
    tp.dispose();
    return largura;
  }

  /// Fundo + foto, sem texto.
  static void desenharBase(
    Canvas canvas, {
    required ui.Image fundo,
    required ui.Image foto,
    required FotoAjuste ajuste,
  }) {
    final qualidade = Paint()..filterQuality = FilterQuality.high;
    canvas.drawImageRect(
      fundo,
      Rect.fromLTWH(0, 0, fundo.width.toDouble(), fundo.height.toDouble()),
      const Rect.fromLTWH(0, 0, BadgeGeo.w, BadgeGeo.h),
      qualidade,
    );

    // Apaga o texto-placeholder que vem desenhado no fundo.
    canvas.drawRect(
      const Rect.fromLTWH(
        BadgeGeo.limpezaX,
        BadgeGeo.limpezaY,
        BadgeGeo.limpezaW,
        BadgeGeo.limpezaH,
      ),
      Paint()..color = _branco,
    );

    const caixa = Rect.fromLTWH(
      BadgeGeo.fotoX,
      BadgeGeo.fotoY,
      BadgeGeo.fotoW,
      BadgeGeo.fotoH,
    );
    final g = FotoGeom.calcular(
      imgW: foto.width,
      imgH: foto.height,
      zoom: ajuste.zoom,
    );
    final px = ajuste.px.clamp(-1.0, 1.0).toDouble();
    final py = ajuste.py.clamp(-1.0, 1.0).toDouble();
    final centro = Offset(caixa.center.dx + px * g.mx, caixa.center.dy + py * g.my);

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(caixa, const Radius.circular(BadgeGeo.fotoRaio)),
    );
    canvas.drawRect(caixa, Paint()..color = _branco);
    canvas.drawImageRect(
      foto,
      Rect.fromLTWH(0, 0, foto.width.toDouble(), foto.height.toDouble()),
      Rect.fromCenter(center: centro, width: g.w, height: g.h),
      qualidade,
    );
    canvas.restore();

    // Moldura branca por cima: esconde resíduo cinza do fundo nos cantos.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        caixa.inflate(1),
        const Radius.circular(BadgeGeo.fotoRaio + 1),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = _branco,
    );
  }

  static void desenharTextos(Canvas canvas, List<ItemCracha> itens) {
    final tinta = Paint()..color = cor;
    for (final item in itens) {
      switch (item) {
        case ItemLinha(:final y):
          canvas.drawRect(
            Rect.fromLTWH(
              BadgeGeo.linhaX1,
              y,
              BadgeGeo.linhaX2 - BadgeGeo.linhaX1,
              BadgeGeo.linhaH,
            ),
            tinta,
          );
        case ItemTexto(:final texto, :final peso, :final size, :final baseline):
          final tp = _textPainter(texto, peso, size);
          final distBaseline =
              tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
          tp.paint(
            canvas,
            Offset(BadgeGeo.textoCx - tp.width / 2, baseline - distBaseline),
          );
          tp.dispose();
      }
    }
  }

  /// PNG 1273 × 2004 do fundo + foto (sem texto), para a camada raster do PDF.
  static Future<Uint8List> baseParaPng({
    required ui.Image fundo,
    required ui.Image foto,
    required FotoAjuste ajuste,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      const Rect.fromLTWH(0, 0, BadgeGeo.w, BadgeGeo.h),
    );
    desenharBase(canvas, fundo: fundo, foto: foto, ajuste: ajuste);
    final img = await recorder.endRecording().toImage(
          BadgeGeo.w.toInt(),
          BadgeGeo.h.toInt(),
        );
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    if (bytes == null) throw StateError('Falha ao codificar PNG do crachá');
    return bytes.buffer.asUint8List();
  }
}

/// Preview do crachá.
final class CrachaPainter extends CustomPainter {
  const CrachaPainter({
    required this.fundo,
    required this.foto,
    required this.dados,
    required this.ajuste,
  });

  final ui.Image fundo;
  final ui.Image foto;
  final CrachaDados dados;
  final FotoAjuste ajuste;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / BadgeGeo.w, size.height / BadgeGeo.h);
    CrachaRenderer.desenharBase(canvas, fundo: fundo, foto: foto, ajuste: ajuste);
    CrachaRenderer.desenharTextos(
      canvas,
      CrachaLayout.calcular(dados, CrachaRenderer.medir),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(CrachaPainter old) =>
      old.fundo != fundo ||
      old.foto != foto ||
      old.dados != dados ||
      old.ajuste != ajuste;
}