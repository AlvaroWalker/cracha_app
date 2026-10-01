// Testa o PreviewPanel REAL em larguras de breakpoint, procurando overflow
// de RenderFlex. Não replica a fórmula: monta o widget de verdade.
//
// Contexto: o desktop liga em 1024px e divide a linha em flex 3 (editor) /
// flex 4 (preview), com o inspector travado em 320px dentro do preview.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:cracha_app/home/widgets/preview_panel.dart';
import 'package:cracha_app/services/badge_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Sem a fonte real, o flutter_test cai numa fonte de largura FIXA (cada
    // glifo = 1em), que mede "Pré-visualização" em 260px em vez de ~110px.
    // Isso fabrica overflows que não existem no app. Carregamos a Rawline
    // para medir o layout de verdade.
    //
    // As duas variantes entram sob a MESMA família: o Skia escolhe o peso
    // pelos metadados internos do arquivo, não pelo nome do FontLoader.
    final loader = FontLoader('Rawline');
    for (final path in [
      'assets/rawline/rawline-400.ttf',
      'assets/rawline/rawline-700.ttf',
    ]) {
      loader.addFont(
        File(path).readAsBytes().then((b) => ByteData.view(b.buffer)),
      );
    }
    await loader.load();
  });

  // Precisa de um crachá: com `currentBadge == null` o PreviewPanel
  // retorna `SizedBox.shrink()` e não há nada para medir.
  BadgeManager managerWithBadge() {
    final bm = BadgeManager();
    bm.updateCurrentBadge(
      name: 'MARIA APARECIDA DE SOUZA',
      role: 'TÉCNICA ADMINISTRATIVA',
      department: 'SECRETARIA DE SAÚDE',
    );
    return bm;
  }

  Widget app(double width, double height, {bool withInspector = true}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: height,
            child: ChangeNotifierProvider<BadgeManager>.value(
              value: managerWithBadge(),
              child: PreviewPanel(
                globalKey: GlobalKey(),
                inspector: withInspector ? const _FakeInspector() : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('PreviewPanel em larguras reais', () {
    for (final size in const [
      // Mobile: o PreviewPanel vem SEM inspector (home_page.dart:359), e o
      // padding do app é AppSpace.lg=24. O harness abaixo já soma o padding,
      // então a largura do painel é o espaço real útil.
      Size(320, 568), // iPhone SE — o menor viewport aceito
      Size(375, 667), // iPhone 8
      Size(414, 896), // iPhone XR
      Size(768, 1024), // iPad portrait
      // Desktop: com inspector. A coluna do preview é 4/7 da largura útil.
      // 1024 é o menor que liga o desktop.
      Size(1024, 700),
      Size(1024, 768),
      Size(1280, 720), // laptop comum
      Size(1440, 900),
      Size(1920, 1080),
    ]) {
      // Mobile não tem inspector; desktop tem.
      final isDesktop = size.width >= 1024;

      testWidgets('sem overflow em ${size.width.toInt()}×${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // No desktop o preview fica em Expanded(flex:4) com Padding(lg) e
        // o editor em flex:3 — então o painel é ~4/7 da largura, não a
        // largura toda. Reproduzir isso é o que torna o teste válido.
        final panelW = isDesktop
            ? (size.width - 1) * 4 / 7 - 48
            : size.width - 48;

        await tester.pumpWidget(
            app(panelW, size.height, withInspector: isDesktop));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'exceção de layout em ${size.width}×${size.height} '
                '(painel de $panelW px)');
      });
    }
  });

  // Diagnóstico: identifica os pontos de estouro em painel estreito.
  // Em 320-48=272px de painel, o cabeçalho e o botão estouram — o texto do
  // botão ("Exportar Crachá em PDF") não cabe.
  testWidgets('DIAG: quem estoura num painel estreito', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(320 - 48, 568, withInspector: false));
    await tester.pumpAndSettle();

    // O texto do botão é o suspeito: mede se ele cabe na largura do painel.
    final btn = find.text('Exportar Crachá em PDF');
    if (btn.evaluate().isNotEmpty) {
      final size = tester.getSize(btn);
      debugPrint('botão texto: ${size.width.toStringAsFixed(1)}px '
          'em painel de ${(320 - 48)}px');
    }

    // A legenda do header também é rígida.
    final legend = find.text('Atualizado em tempo real');
    if (legend.evaluate().isNotEmpty) {
      debugPrint('legenda: ${tester.getSize(legend).width.toStringAsFixed(1)}px');
    }

    // Mede cada filho do header para achar quem não cede.
    final title = find.text('Pré-visualização');
    debugPrint('titulo: ${tester.getSize(title).width.toStringAsFixed(1)}px');
    debugPrint('painel disponivel: 272px');
  });

  group('alturas baixas (o palco tem altura mínima)', () {
    for (final h in [400.0, 500.0, 560.0, 600.0]) {
      testWidgets('sem overflow em 1280 de altura $h', (tester) async {
        tester.view.physicalSize = Size(1280, h);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        // Desktop: painel = 4/7 da largura útil, com o padding do app.
        final panelW = (1280 - 1) * 4 / 7 - 48;
        await tester.pumpWidget(app(panelW, h, withInspector: true));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'overflow vertical em altura $h');
      });
    }
  });

  testWidgets('o conteúdo essencial aparece em altura baixa',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final panelW = (1024 - 1) * 4 / 7 - 48;
    await tester.pumpWidget(app(panelW, 500, withInspector: true));
    await tester.pumpAndSettle();

    expect(find.text('Exportar Crachá em PDF'), findsOneWidget);
    expect(find.text('Pré-visualização'), findsOneWidget);
    expect(find.text('54 × 85 mm — igual ao impresso'), findsOneWidget);
  });

  testWidgets('mobile: sem inspector, o palco ocupa a coluna inteira',
      (tester) async {
    tester.view.physicalSize = const Size(500, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(500 - 48, 700, withInspector: false));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Exportar Crachá em PDF'), findsOneWidget);
  });
}

class _FakeInspector extends StatelessWidget {
  const _FakeInspector();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: Color(0x11000000),
        child: SizedBox.expand(),
      );
}
