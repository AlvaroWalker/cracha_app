// Verifica se o peso 600 da secretaria resolve para a Rawline SemiBold.
//
// O layout pede `peso 600` para a secretaria. No preview isso vira
// `FontWeight.w600` e no PDF vira o arquivo `rawline-600.ttf`. Se o Flutter
// Web não tiver a variante 600 registrada, ele cai para a mais próxima
// disponível (400) e o preview fica com uma fonte diferente da pretendida —
// o sintoma de "a secretaria parece outra fonte".
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cracha_app/views/badge_geometry.dart';
import 'package:cracha_app/views/cracha_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader('Rawline');
    for (final p in [
      'assets/rawline/rawline-400.ttf',
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

  double largura(String t, FontWeight w, double size) {
    final tp = TextPainter(
      text: TextSpan(
        text: t,
        style: TextStyle(fontFamily: 'Rawline', fontWeight: w, fontSize: size),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
    final r = tp.width;
    tp.dispose();
    return r;
  }

  const amostra = 'SECRETARIA MUNICIPAL';

  test('w600 tem largura DISTINTA de w400 (prova que a variante existe)',
      () {
    final w600 = largura(amostra, FontWeight.w600, 60);
    final w400 = largura(amostra, FontWeight.w400, 60);

    expect(w600, greaterThan(w400),
        reason: 'w600 ($w600) deve ser mais larga que w400 ($w400). '
            'Se forem iguais, o Flutter caiu no fallback 400 e o preview '
            'NÃO está usando SemiBold.');
  });

  test('w700 é diferente de w600 (as três variantes do layout existem)', () {
    final w600 = largura(amostra, FontWeight.w600, 60);
    final w700 = largura(amostra, FontWeight.w700, 60);
    final w800 = largura(amostra, FontWeight.w800, 60);

    expect(w700, greaterThan(w600), reason: 'w700 > w600');
    expect(w800, greaterThan(w700), reason: 'w800 > w700');
  });

  test('o layout pede 600 para a secretaria, 700 cargo, 800 nome', () {
    // Documenta a intenção: se alguém mudar, o teste avisa.
    const dados = CrachaDados(
      nome: 'PEDRO PAULO DE SOUSA MARINS',
      cargo: 'CONCILIADOR DE DEFESA DO CONSUMIDOR',
      secretaria: 'SECRETARIA MUNICIPAL DE SAUDE',
    );
    final itens = CrachaLayout.calcular(dados, CrachaRenderer.medir);
    final pesos = itens.whereType<ItemTexto>().map((t) => t.peso).toSet();

    expect(pesos, containsAll(<int>[600, 700, 800]),
        reason: 'esperados 600/700/800, obtidos $pesos');
  });

  test('CrachaRenderer.pesoDe mapeia corretamente', () {
    expect(CrachaRenderer.pesoDe(600), FontWeight.w600);
    expect(CrachaRenderer.pesoDe(700), FontWeight.w700);
    expect(CrachaRenderer.pesoDe(800), FontWeight.w800);
  });
}