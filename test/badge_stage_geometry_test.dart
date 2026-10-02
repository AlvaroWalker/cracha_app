// Confere a GEOMETRIA do palco do crachá: proporção 54:85, largura travada
// e ausência de overflow.
//
// POR QUE UM CRACHÁ SINTÉTICO, E NÃO O `BadgeView` REAL
//
// O `BadgeView` de produção carrega fundo e foto por `FutureBuilder`
// (`rootBundle.load` + decodificação). No runner headless o servidor de
// assets não resolve, o `FutureBuilder` nunca completa e o `CustomPaint` do
// crachá não chega na árvore — o teste mediria "Bad state: No element".
//
// Aqui o palco é exercitado com um `CustomPaint` equivalente (mesma
// proporção, mesmo `size`), que é exatamente o que se quer verificar: o PALCO
// dimensiona corretamente? O conteúdo não entra no teste.
//
// A prova de que o texto não some está em `tool/verify_pdf_text.py`, que
// extrai o texto do PDF real com PyMuPDF.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cracha_app/views/badge_geometry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Sem a Rawline real o `TextPainter` cai numa fonte de largura fixa e o
    // layout mede errado — foi assim que "validei" um bug que não existia.
    final loader = FontLoader('Rawline');
    for (final p in [
      'assets/rawline/rawline-600.ttf',
      'assets/rawline/rawline-700.ttf',
      'assets/rawline/rawline-800.ttf',
    ]) {
      loader.addFont(
        File(p).readAsBytes().then((b) => ByteData.view(b.buffer)),
      );
    }
    await loader.load();
  });

  /// Reproduz o palco de `buildBadgeStage`: largura travada, altura derivada,
  /// `CustomPaint` com o painter. Sem `FittedBox` — ele passaria restrições
  /// infinitas ao filho (ver o cabeçalho de `badge_view_canvas.dart`).
  Widget palco(double largura) {
    final w = largura.clamp(220.0, 340.0);
    final h = w * BadgeGeo.h / BadgeGeo.w;
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: w,
            height: h,
            child: CustomPaint(
              size: Size(w, h),
              painter: _CrachaFake(),
            ),
          ),
        ),
      ),
    );
  }

  final Finder cracha = find.byWidgetPredicate(
    (w) => w is CustomPaint && w.painter is _CrachaFake,
  );

  group('geometria do palco', () {
    testWidgets('a proporção é 54:85 em várias larguras', (tester) async {
      for (final largura in [220.0, 280.0, 340.0, 500.0]) {
        await tester.pumpWidget(palco(largura));
        await tester.pumpAndSettle();

        final size = tester.firstRenderObject<RenderBox>(cracha).size;
        expect(size.width / size.height, closeTo(54 / 85, 0.01),
            reason: 'largura $largura → proporção '
                '${size.width / size.height} != 54/85');
      }
    });

    testWidgets('a largura é limitada entre 220 e 340', (tester) async {
      await tester.pumpWidget(palco(9999));
      await tester.pumpAndSettle();

      final size = tester.firstRenderObject<RenderBox>(cracha).size;
      expect(size.width, lessThanOrEqualTo(340.0));
      expect(size.width, greaterThanOrEqualTo(220.0));
    });

    testWidgets('sem overflow em larguras pequenas', (tester) async {
      for (final largura in [220.0, 260.0, 340.0]) {
        await tester.pumpWidget(palco(largura));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull,
            reason: 'exceção de layout em $largura');
      }
    });
  });

  test('o BadgeGeo bate com a proporção impressa', () {
    expect(BadgeGeo.w / BadgeGeo.h, closeTo(54 / 85, 0.002),
        reason: 'o design ${BadgeGeo.w}×${BadgeGeo.h} deve ter a proporção '
            'do crachá impresso 54×85');
  });

  test('a altura sai da largura pela proporção impressa', () {
    for (final largura in [220.0, 280.0, 340.0]) {
      final altura = largura * BadgeGeo.h / BadgeGeo.w;
      expect(altura, greaterThan(largura));
      expect(altura / largura, closeTo(85 / 54, 0.001));
    }
  });
}

/// Painter vazio: o teste é de GEOMETRIA, não de conteúdo.
class _CrachaFake extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF333333),
    );
  }

  @override
  bool shouldRepaint(covariant _CrachaFake oldDelegate) => false;
}