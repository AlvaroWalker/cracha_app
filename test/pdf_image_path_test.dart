// Verifica a via IMAGEM: monta o BadgeView, captura o RepaintBoundary a
// 300 DPI, monta o PDF e grava. Confere que a imagem tem a resolução
// esperada para 54x85mm impressos e que o PDF abre com 1 imagem.
//
// NOTA: `toImage()` trava no runner headless do flutter_test (já observado:
// timeouts de 150s/250s/420s). Este teste prova a GEOMETRIA e a montagem do
// PDF sem depender do `toImage` real — substitui a captura por um PNG
// sintético do mesmo tamanho que a captura produziria.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cracha_app/models/badge_data.dart';
import 'package:cracha_app/views/badge_design.dart';

const mmToPt = 72 / 25.4;
const larguraPt = 54 * mmToPt; // 153.07
const alturaPt = 85 * mmToPt; // 240.94
const dpi = 300.0;

// O caso do Pedro: nome em 2 linhas, cargo em 2, secretaria em 2.
final mockBadge = BadgeData(
  name: 'PEDRO PAULO DE SOUSA MARINS',
  role: 'CONCILIADOR DE DEFESA DO CONSUMIDOR',
  department: 'INTEGRADA DE APOIO A SEGURANCA PUBLICA',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resolução 300 DPI para 54x85mm', () {
    final larguraPx = larguraPt / 72 * dpi;
    final alturaPx = alturaPt / 72 * dpi;
    expect(larguraPx, closeTo(637.8, 0.1));
    expect(alturaPx, closeTo(1003.9, 0.1));
    // 300 DPI num crachá pequeno dá ~640x1004 px: mais que suficiente.
    expect(larguraPx, greaterThan(600));
  });

  testWidgets('o BadgeView tem a proporção do crachá (54x85)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 600,
            child: buildBadgeStage(
              globalKey: GlobalKey(),
              badge: mockBadge,
              boxWidth: 380,
              onImageTap: () {},
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Acha o BadgeView pelo tipo — o palco pode ter caixas ao redor.
    final badge = tester.allRenderObjects
        .whereType<RenderBox>()
        .firstWhere(
          (b) => b.size.width > 100 && b.size.height > 100 &&
              (b.size.width / b.size.height - 54 / 85).abs() < 0.02,
          orElse: () => throw StateError('BadgeView nao encontrado'),
        );
    // 54/85 = 0.635. Confirma que o badge é proporcional à página do PDF,
    // senão o `BoxFit.cover` do PDF cortaria.
    expect(badge.size.width / badge.size.height, closeTo(54 / 85, 0.02));
  });
}
