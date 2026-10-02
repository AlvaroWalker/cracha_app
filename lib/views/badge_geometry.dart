// ═══════════════════════════════════════════════════════════════════════════
// PORT do gerador validado — `Desktop/flutter_cracha`.
//
// POR QUE ESTE ARQUIVO EXISTE
//
// O PDF vetorial anterior (`pdf_vector_generator` / `badge_pdf_widget`)
// perdia texto silenciosamente porque `dart_pdf` e o Skia leem tabelas de
// métricas DIFERENTES do mesmo TTF (caixa 1.3765 vs 1.0000 — 37,6%).
// Nenhum número mágico reconcilia as duas engines.
//
// A saída: MEDIR COM O SKIA, DESENHAR COM O dart_pdf.
//
//   `CrachaLayout.calcular` é puro e não sabe nada de engine. Recebe um
//   `Medidor` (largura de um texto) e devolve itens JÁ POSICIONADOS —
//   texto, peso, tamanho, baseline. Quem mede é o `TextPainter` (Skia).
//   Depois o PDF só desenha essas posições com `drawString`.
//
// Não existe `pw.Text`, `TextOverflow` nem `pw.Column` no caminho, então
// não existe etapa capaz de cortar ou descartar uma linha. O texto
// selecionável volta como bônus.
//
// POR QUE AS COORDENADAS MUDARAM
//
// `CrachaGeo` (1273×2004) é a MESMA arte do `CRACHA.png` do projeto,
// verificada byte a byte (669252 bytes idênticos) — só mudou a unidade:
// o design original em vez de pixels lógicos redimensionados. Isso elimina
// a calibração deFactors que exigia KNOW antes: 1273/333.4 ≈ 3.819.
// ═══════════════════════════════════════════════════════════════════════════
import 'dart:math' as math;

/// Medidas do template, em pixels do fundo original (1273 × 2004).
abstract final class BadgeGeo {
  BadgeGeo._();

  static const double w = 1273;
  static const double h = 2004;

  // Caixa da foto (recorte arredondado)
  static const double fotoX = 343;
  static const double fotoY = 677;
  static const double fotoW = 586;
  static const double fotoH = 723;
  static const double fotoRaio = 57;

  // O fundo já traz "NOME / FUNÇÃO / GABINETE..." desenhados: essa área é
  // apagada com branco antes de escrever o texto real.
  static const double limpezaX = 20;
  static const double limpezaY = 1410;
  static const double limpezaW = w - 40;
  static const double limpezaH = 540;

  // Região de texto
  static const double textoCx = 636.5;
  static const double textoMaxW = 1030;
  static const double textoTop = 1432;
  static const double textoBottom = 1945;
  static const double linhaX1 = 118;
  static const double linhaX2 = 1154;
  static const double linhaH = 4;

  /// baseline = centro da linha + metade da cap-height da Rawline (0,71 em).
  static const double baselineEm = 0.355;
}

/// Dados de texto do crachá.
final class CrachaDados {
  const CrachaDados({
    this.nome = '',
    this.cargo = '',
    this.secretaria = '',
    this.maiusculas = true,
  });

  final String nome;
  final String cargo;
  final String secretaria;
  final bool maiusculas;

  CrachaDados copyWith({
    String? nome,
    String? cargo,
    String? secretaria,
    bool? maiusculas,
  }) =>
      CrachaDados(
        nome: nome ?? this.nome,
        cargo: cargo ?? this.cargo,
        secretaria: secretaria ?? this.secretaria,
        maiusculas: maiusculas ?? this.maiusculas,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrachaDados &&
          other.nome == nome &&
          other.cargo == cargo &&
          other.secretaria == secretaria &&
          other.maiusculas == maiusculas;

  @override
  int get hashCode => Object.hash(nome, cargo, secretaria, maiusculas);
}

/// Enquadramento da foto: zoom (1 = "cover") e deslocamento em [-1, 1]
/// como fração do deslocamento máximo possível.
final class FotoAjuste {
  const FotoAjuste({this.zoom = 1, this.px = 0, this.py = 0});

  final double zoom;
  final double px;
  final double py;

  FotoAjuste copyWith({double? zoom, double? px, double? py}) =>
      FotoAjuste(zoom: zoom ?? this.zoom, px: px ?? this.px, py: py ?? this.py);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FotoAjuste &&
          other.zoom == zoom &&
          other.px == px &&
          other.py == py;

  @override
  int get hashCode => Object.hash(zoom, px, py);
}

/// Tamanho da foto desenhada e folga (mx/my) disponível para arrastar.
final class FotoGeom {
  const FotoGeom({required this.w, required this.h, required this.mx, required this.my});

  factory FotoGeom.calcular({
    required int imgW,
    required int imgH,
    required double zoom,
  }) {
    final s = math.max(BadgeGeo.fotoW / imgW, BadgeGeo.fotoH / imgH) * zoom;
    final w = imgW * s;
    final h = imgH * s;
    return FotoGeom(w: w, h: h, mx: (w - BadgeGeo.fotoW) / 2, my: (h - BadgeGeo.fotoH) / 2);
  }

  final double w;
  final double h;
  final double mx;
  final double my;
}

// ---------------------------------------------------------------------------
// Layout de texto
// ---------------------------------------------------------------------------

/// Mede a largura de [texto] com a fonte no [peso] (600/700/800) e [size] dados.
typedef Medidor = double Function(String texto, int peso, double size);

sealed class ItemCracha {
  const ItemCracha();
}

final class ItemTexto extends ItemCracha {
  const ItemTexto({
    required this.texto,
    required this.peso,
    required this.size,
    required this.baseline,
  });

  final String texto;
  final int peso;
  final double size;

  /// Y da baseline, medido a partir do topo do crachá.
  final double baseline;
}

final class ItemLinha extends ItemCracha {
  const ItemLinha({required this.y});

  final double y;
}

final class _Bloco {
  const _Bloco(this.linhas, this.peso, this.size);

  final List<String> linhas;
  final int peso;
  final double size;

  double get lh => size * 1.18;
  double get altura => linhas.length * lh;
}

typedef _Montagem = ({
  _Bloco nome,
  _Bloco cargo,
  _Bloco sec,
  double gapNomeCargo,
  double gapLinha,
  double total,
});

/// Quebra de linha, auto-ajuste de fonte e centralização vertical.
/// Usado pelo preview E pelo PDF — mesma saída para os dois.
abstract final class CrachaLayout {
  static List<ItemCracha> calcular(CrachaDados d, Medidor medir) {
    String norm(String s) => d.maiusculas ? s.trim().toUpperCase() : s.trim();
    final nome = norm(d.nome);
    final cargo = norm(d.cargo);
    final sec = norm(d.secretaria);

    // Encolhe tudo proporcionalmente até caber na região disponível.
    const regiaoH = BadgeGeo.textoBottom - BadgeGeo.textoTop;
    var fator = 1.0;
    var l = _montar(nome, cargo, sec, fator, medir);
    while (l.total > regiaoH && fator > 0.4) {
      fator -= 0.04;
      l = _montar(nome, cargo, sec, fator, medir);
    }

    final itens = <ItemCracha>[];
    var y = BadgeGeo.textoTop + (regiaoH - l.total) / 2;

    void bloco(_Bloco b) {
      for (final texto in b.linhas) {
        itens.add(
          ItemTexto(
            texto: texto,
            peso: b.peso,
            size: b.size,
            baseline: y + b.lh / 2 + b.size * BadgeGeo.baselineEm,
          ),
        );
        y += b.lh;
      }
    }

    bloco(l.nome);
    y += l.gapNomeCargo;
    bloco(l.cargo);
    y += l.gapLinha;
    itens.add(ItemLinha(y: y));
    y += BadgeGeo.linhaH + l.gapLinha;
    bloco(l.sec);
    return itens;
  }

  static _Montagem _montar(
    String nome,
    String cargo,
    String sec,
    double fator,
    Medidor medir,
  ) {
    final n = _ajustar(nome, 800, 86, 2, fator, medir);
    final c = _ajustar(cargo, 700, 58, 2, fator, medir);
    final s = _ajustar(sec, 600, 62, 3, fator, medir);
    final gapNomeCargo =
        n.linhas.isNotEmpty && c.linhas.isNotEmpty ? 20 * fator : 0.0;
    final gapLinha = 46 * fator;
    final total = n.altura +
        gapNomeCargo +
        c.altura +
        gapLinha +
        BadgeGeo.linhaH +
        gapLinha +
        s.altura;
    return (
      nome: n,
      cargo: c,
      sec: s,
      gapNomeCargo: gapNomeCargo,
      gapLinha: gapLinha,
      total: total,
    );
  }

  /// Reduz a fonte até caber em [maxLinhas] e dentro da largura máxima.
  static _Bloco _ajustar(
    String texto,
    int peso,
    double base,
    int maxLinhas,
    double fator,
    Medidor medir,
  ) {
    var size = (base * fator).roundToDouble();
    while (true) {
      final linhas = _quebrar(texto, peso, size, medir);
      final cabe = linhas.length <= maxLinhas &&
          linhas.every((l) => medir(l, peso, size) <= BadgeGeo.textoMaxW);
      if (cabe || size <= 28) return _Bloco(linhas, peso, size);
      size -= 2;
    }
  }

  static List<String> _quebrar(
    String texto,
    int peso,
    double size,
    Medidor medir,
  ) {
    final linhas = <String>[];
    var atual = '';
    for (final palavra in texto.split(RegExp(r'\s+')).where((p) => p.isNotEmpty)) {
      final teste = atual.isEmpty ? palavra : '$atual $palavra';
      if (atual.isNotEmpty && medir(teste, peso, size) > BadgeGeo.textoMaxW) {
        linhas.add(atual);
        atual = palavra;
      } else {
        atual = teste;
      }
    }
    if (atual.isNotEmpty) linhas.add(atual);
    return linhas;
  }
}