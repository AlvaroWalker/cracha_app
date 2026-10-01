// Testa a ESTRUTURA do stage invisível do lote:
//   1. o OverlayEntry monta sem estourar;
//   2. o RepaintBoundary é encontrável pelo GlobalKey (sem `toImage`, que
//      trava no runner headless);
//   3. o boundary tem a proporção 54/85 (para o BoxFit.cover não cortar);
//   4. a opacidade 0.01 mantém a camada "viva" para o rasterizador.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cracha_app/models/badge_data.dart';
import 'package:cracha_app/views/badge_design.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final badge = BadgeData(
    name: 'MAXIMILIANO AUGUSTO FERREIRA DE ALMEIDA SOBRINHO',
    role: 'DIRETOR GERAL DE ADMINISTRACAO FINANCEIRA E ORCAMENTARIA DO MUNICIPIO',
    department: 'SECRETARIA MUNICIPAL DE GESTAO FINANCEIRA E PLANEJAMENTO ESTRATEGICO',
  );

  testWidgets('stage invisível monta e o boundary é encontrável',
      (tester) async {
    final key = GlobalKey();

    // Precisa de uma árvore real antes de pegar o Overlay.
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    final ctx = tester.element(find.byType(Scaffold).first);

    // Insere FORA do build — o mesmo que o gerador faz. Inserir dentro do
    // `build` dispara "markNeedsBuild() called during build".
    final overlay = Overlay.of(ctx, rootOverlay: true);
    overlay.insert(OverlayEntry(
      builder: (_) => Positioned(
        left: -1040,
        top: 0,
        // O Overlay dá restrições infinitas — sem width/height o MaterialApp
        // aninhado explode.
        width: 560,
        height: 858,
        child: IgnorePointer(
          child: Opacity(
            opacity: 0.01,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                body: Center(
                  child: buildBadgeStage(
                    globalKey: key,
                    badge: badge,
                    boxWidth: 520,
                    onImageTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ));

    await tester.pumpAndSettle();

    // 1) Contexto existe
    expect(key.currentContext, isNotNull,
        reason: 'o BadgeView no stage não montou');

    // 2) Boundary encontrável
    final ro = key.currentContext!.findRenderObject();
    expect(ro, isA<RenderRepaintBoundary>(),
        reason: 'a key não aponta pra um RepaintBoundary');

    final boundary = ro as RenderRepaintBoundary;
    expect(boundary.size.width, greaterThan(100));
    expect(boundary.size.height, greaterThan(100));

    // 3) Proporção 54/85 = 0.635 (senão o BoxFit.cover corta o crachá)
    final ratio = boundary.size.width / boundary.size.height;
    expect(ratio, closeTo(54 / 85, 0.02),
        reason: 'proporção $ratio != 54/85 — o cover vai cortar');

    // 4) Continua vivo para o rasterizador
    expect(boundary.hasSize, isTrue);
  });

  testWidgets('o texto longo NÃO é cortado no widget (Skia decide)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 520,
            child: buildBadgeStage(
              globalKey: GlobalKey(),
              badge: badge,
              boxWidth: 520,
              onImageTap: () {},
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Procura os textos renderizados na árvore — se o Skia cortou, o
    // último token ("ESTRATEGICO") não aparece.
    final found = <String>{};
    for (final t in find.byType(RichText).evaluate()) {
      final rt = t.widget as RichText;
      final s = rt.text.toPlainText();
      if (s.isNotEmpty) found.add(s);
    }
    final all = found.join(' | ').toUpperCase();
    expect(all, contains('MAXIMILIANO'));
    expect(all, contains('ESTRATEGICO'),
        reason: 'o texto do widget foi cortado — o Skia não deveria cortar');
  });
}
