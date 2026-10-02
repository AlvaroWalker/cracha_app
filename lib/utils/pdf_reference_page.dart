// ═══════════════════════════════════════════════════════════════════════════
// PÁGINA DE REFERÊNCIA — imagem enviada pela gráfica.
//
//POR QUE ISSO EXISTE
//
// A imagem (`assets/images/IMG-EX.jpg`) é a FOLHA DE INSTRUÇÃO da gráfica:
// mostra o crachá pronto sobre fundo verde, com a faixa "ATENÇÃO — NÃO
// REMOVER A BORDA BRANCA". Ela vai junto do PDF para que quem imprimir saiba
// exatamente o resultado esperado e não corte a margem.
//
// A imagem mede 638×1004px = 54×85mm a 300 DPI — a MESMA resolução da
// captura do crachá. Então a proporção bate (0.6353 vs 0.6355) e a página
// sai nas mesmas dimensões, sem distorção nem recorte.
//
// NOTA: a imagem JÁ contém a faixa de instrução embutida. Por isso ela é
// inserida como imagem crua, sem texto ou mouldura por cima — qualquer
// acréscimo competiria com o aviso que a gráfica quer que seja lido.
// ═══════════════════════════════════════════════════════════════════════════
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Caminho do asset. Declarado no `pubspec.yaml` em `assets:`.
const String referenceImageAsset = 'assets/images/IMG-EX.jpg';

/// Bytes da referência, carregados uma única vez por sessão.
///
/// A imagem tem 73KB; recarregar por exportação custaria I/O repetido sem
/// ganho. O `Future` é memoizado porque o app gera vários PDFs seguidos
/// (lote de 200 crachás = 200 documentos, mas só 1 download do asset).
Future<Uint8List>? _cachedReference;

Future<Uint8List> loadReferenceImage() {
  return _cachedReference ??= rootBundle
      .load(referenceImageAsset)
      .then((data) => data.buffer.asUint8List());
}

/// Adiciona a página de referência ao documento, como ÚLTIMA página.
///
/// No fim, e não no começo, porque quem abre o PDF quer os crachá�� prontos
/// primeiro; a instrução é consultada antes de mandar imprimir.
///
/// Se o asset não estiver no bundle, a página é omitida em vez de derrubar a
/// exportação — perder a referência é um inconveniente, perder os crachás
/// seria inutilizar o trabalho.
Future<void> appendReferencePage(pw.Document pdf) async {
  Uint8List bytes;
  try {
    bytes = await loadReferenceImage();
  } catch (_) {
    // Asset ausente: segue sem a referência.
    return;
  }

  // Mesmo formato de página dos crachás (54×85mm), SEM margem: a imagem cai
  // exatamente na folha. `PdfPageFormat` não aceita `marginAll` nesta versão
  // do pacote `pdf` — a margem vai no construtor.
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat(54 * (72 / 25.4), 85 * (72 / 25.4), marginAll: 0),
      build: (_) => pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
    ),
  );
}
