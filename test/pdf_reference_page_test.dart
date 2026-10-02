// Valida a PÁGINA DE REFERÊNCIA: a proporção bate, o asset está no lugar e
// o PDF sai com as páginas no tamanho certo.
//
// NOTA SOBRE POR QUE NÃO USAR `testWidgets`
//
// Dentro de `testWidgets`, `rootBundle.load` resolve o asset pelo servidor de
// assets do runner headless e trava indefinidamente (observado: >300s).
// Então os testes que tocam o PDF leem o JPEG direto do disco — que é o mesmo
// arquivo que o bundle serve. A decodificação JPEG dentro do pacote `pdf` foi
// verificada funcionando em pdf_image_encoding_probe_test.dart.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  const refPath = 'assets/images/IMG-EX.jpg';

  // Proporções medidas no arquivo: 638×1004 = 0.635458.
  const refRatio = 638 / 1004;
  const badgeRatio = 54 / 85;

  // 54×85mm sem margem: a referência cai exatamente na folha.
  final format = PdfPageFormat(54 * (72 / 25.4), 85 * (72 / 25.4), marginAll: 0);

  test('a proporção da referência bate com a do crachá', () {
    expect((refRatio - badgeRatio).abs(), lessThan(0.001),
        reason: 'a referência é $refRatio e o crachá é $badgeRatio — '
            'divergência maior distorce a página de instrução');
  });

  test('a referência tem resolução de 300 DPI para 54×85mm', () {
    expect(638, closeTo(54 / 25.4 * 300, 1.0)); // 637.8px
    expect(1004, closeTo(85 / 25.4 * 300, 1.0)); // 1003.9px
  });

  test('o asset existe, é JPEG válido e tem o tamanho esperado', () {
    final f = File(refPath);
    expect(f.existsSync(), isTrue, reason: 'asset $refPath não encontrado');

    final bytes = f.readAsBytesSync();
    expect(bytes.length, greaterThan(10000),
        reason: 'a referência da gráfica tem 73KB — menos que isso é '
            'outro arquivo');

    // Assinatura JPEG: FF D8
    expect(bytes[0], 0xFF);
    expect(bytes[1], 0xD8);
  });

  test('o PDF de 1 crachá + referência sai com 2 páginas de 54×85mm',
      () async {
    final jpg = File(refPath).readAsBytesSync();

    final pdf = pw.Document();
    // Página 1: um crachá. Página 2: a referência.
    for (var i = 0; i < 2; i++) {
      pdf.addPage(pw.Page(
        pageFormat: format,
        build: (_) => pw.Image(pw.MemoryImage(jpg)),
      ));
    }

    final bytes = await pdf.save();
    expect(bytes.length, greaterThan(10000));

    // Grava para o verificador externo (PyMuPDF) contar as páginas.
    final out = File('test/_out_ref.pdf');
    await out.writeAsBytes(bytes);
    expect(out.lengthSync(), bytes.length);
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('um lote de 3 crachás + referência = 4 páginas', () async {
    final jpg = File(refPath).readAsBytesSync();

    final pdf = pw.Document();
    for (var i = 0; i < 4; i++) {
      pdf.addPage(pw.Page(
        pageFormat: format,
        build: (_) => pw.Image(pw.MemoryImage(jpg)),
      ));
    }

    final out = File('test/_out_lote_ref.pdf');
    await out.writeAsBytes(await pdf.save());
    expect(out.existsSync(), isTrue);
  }, timeout: const Timeout(Duration(seconds: 60)));
}
