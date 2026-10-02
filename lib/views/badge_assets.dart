// ═══════════════════════════════════════════════════════════════════════════
// ASSETS DO CRACHÁ — fundo, foto padrão e conversão bytes → ui.Image.
//
// POR QUE UM CACHE
//
// O PDF vetorial ([CrachaVectorPdfService]) e o preview ([CrachaPainter])
// precisam de `ui.Image`, mas o [BadgeData] guarda a foto do servidor como
// `Uint8List`. Decodificar a cada export custaria uma passada de PNG por
// crachá — num lote de 200, 200 decodificações do placeholder à toa.
//
// `_imagens` guarda as três imagens (fundo, placeholder e a última foto
// convertida) por bytes. Como o placeholder e o fundo são sempre os mesmos,
// na prática só a foto do crachá varia.
//
// Por que o fundo é imagem e não `Image.asset` dentro do PDF: o `dart_pdf`
// não sabe desenhar assets do Flutter. A camada raster do PDF precisa dos
// bytes, e é aqui que eles são obtidos uma única vez.
// ═══════════════════════════════════════════════════════════════════════════
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../models/badge_data.dart';

/// Fundo do crachá. É a MESMA arte do `CRACHA.png` do preview — os dois
/// paths leem este arquivo, então não há como o PDF e o preview divergirem.
const String fundoAsset = 'assets/images/CRACHA.png';

/// Foto usada quando o crachá não tem imagem.
const String fotoPadraoAsset = 'assets/images/placeholder.png';

/// Guardas de assets e FOTOS DECODIFICADAS, memoizadas.
///
/// O valor é o `Future`, não a imagem: duas chamadas concorrentes na mesma
/// foto compartilham a mesma decodificação em vez de duplicá-la.
final Map<Object, Future<ui.Image>> _cache = {};

/// Carrega (e memoiza) uma imagem do bundle.
Future<ui.Image> _doBundle(String path) async {
  final data = await rootBundle.load(path);
  return _decodifica(data.buffer.asUint8List());
}

Future<ui.Image> _decodifica(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}

/// Foto padrão compartilhada.
Future<ui.Image> fotoPadrao() =>
    _cache['padrao'] ??= _doBundle(fotoPadraoAsset);

/// Fundo compartilhado.
Future<ui.Image> fundoDoCracha() =>
    _cache['fundo'] ??= _doBundle(fundoAsset);

/// Converte os bytes da foto do crachá em `ui.Image`.
///
/// Chaveia pelo conteúdo (lista de bytes), então trocar de crachá na galeria
/// não devolve a imagem do anterior.
Future<ui.Image?> fotoDoBadge(BadgeData badge) async {
  final bytes = badge.photo;
  if (bytes == null || bytes.isEmpty) return null;

  // Chaveia pelo conteúdo: trocar de crachá na galeria não pode devolver a
  // imagem do anterior.
  //
  // Não hasheia a foto inteira (centenas de KB) — amostra o começo, o fim e
  // o meio, mais o comprimento. Duas fotos que diferem só no miolo colidem,
  // o que é inofensivo aqui: a colisão mostraria a foto anterior por um
  // instante, e o usuário percebe e troca de novo.
  int amostra = bytes.length;
  for (var i = 0; i < bytes.length; i += 997) {
    amostra = (amostra * 31 + bytes[i]) & 0x1FFFFFFF;
  }
  final chave = Object.hash(amostra, bytes.length, badge.id);
  final existente = _cache[chave];
  if (existente != null) return existente;

  final futuro = _decodifica(bytes);

  // Limite de 3: fundo + placeholder + a foto atual. Fotos antigas de
  // crachás já exportados não precisam ficar na memória.
  if (_cache.length > 3) {
    final descartaveis = _cache.keys
        .where((k) => k != 'fundo' && k != 'padrao')
        .take(_cache.length - 3)
        .toList();
    for (final k in descartaveis) {
      _cache.remove(k);
    }
  }
  _cache[chave] = futuro;
  return futuro;
}

/// Libera as imagens de foto (mantém fundo e placeholder).
void liberarFotos() {
  final descartaveis = _cache.keys
      .where((k) => k != 'fundo' && k != 'padrao')
      .toList();
  for (final k in descartaveis) {
    _cache.remove(k);
  }
}