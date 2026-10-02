// ═══════════════════════════════════════════════════════════════════════════
// BADGEVIEW — preview do crachá, com a estrutura do gerador validado.
//
// ADOTADO do fragmento `Desktop/flutter_cracha`, que já funciona.
//
// POR QUE A ESTRUTURA É ESTA, E NÃO OUTRA
//
// A tentativa anterior usava `FittedBox` para caber o crachá na caixa e
// `AspectRatio` para travar a proporção. `FittedBox` passa restrições
// INFINITAS ao filho, então o `CustomPaint` recebia largura/altura infinitas
// e o Flutter reclamava a cada frame:
//
//     BoxConstraints forces an infinite width and infinite height.
//
// O fragmento não tem `FittedBox`: usa `AspectRatio` (que resolve a altura a
// partir da largura) e passa `LayoutBuilder.biggest` ao `CustomPaint`. É a
// mesma técnica, e funciona.
//
// `CrachaRenderer` não sabe de constraints — só desenha no `size` que recebe
// e escala por `size.width / BadgeGeo.w`. Por isso o mesmo painter serve ao
// preview e ao PDF.
// ═══════════════════════════════════════════════════════════════════════════
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/badge_data.dart';
import 'badge_assets.dart';
import 'badge_geometry.dart';
import 'cracha_renderer.dart';

/// Largura do palco (preview). Mantém os mesmos limites de antes.
const double kStageMaxWidth = 340;
const double kStageMinWidth = 220;

class BadgeView extends StatelessWidget {
  final BadgeData badgeData;
  final VoidCallback onImageTap;
  final VoidCallback onNameTap;
  final VoidCallback onRoleTap;
  final VoidCallback onDepartmentTap;

  const BadgeView({
    super.key,
    required this.badgeData,
    required this.onImageTap,
    required this.onNameTap,
    required this.onRoleTap,
    required this.onDepartmentTap,
  });

  /// Converte o modelo do app no modelo do layout.
  ///
  /// Vira MAIÚSCULAS por padrão: é o padrão do crachá impresso e o que o
  /// gerador validado usa. Campos vazios ganham o texto de exemplo, como no
  /// preview antigo.
  CrachaDados get _dados {
    final nome = badgeData.name.trim();
    final cargo = badgeData.role.trim();
    final dept = badgeData.department.trim();
    return CrachaDados(
      nome: nome.isEmpty ? 'NOME DO SERVIDOR' : nome,
      cargo: cargo.isEmpty ? 'CARGO DO SERVIDOR' : cargo,
      secretaria: dept.isEmpty ? 'SECRETARIA' : dept,
      maiusculas: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fundo e placeholder são os mesmos para todo crachá; só a foto muda. O
    // cache em `badge_assets` evita redecodificar a cada rebuild.
    return FutureBuilder<(ui.Image, ui.Image, FotoAjuste)>(
      future: _imagens(),
      builder: (context, snap) {
        final dados = snap.data;
        if (dados == null) {
          // Enquanto decodifica, o `AspectRatio` abaixo ainda não existe —
          // o preview ocupa a área quando o Future resolve.
          return const SizedBox.shrink();
        }
        return _Desenho(
          fundo: dados.$1,
          foto: dados.$2,
          ajuste: dados.$3,
          dados: _dados,
          onImageTap: onImageTap,
        );
      },
    );
  }

  Future<(ui.Image, ui.Image, FotoAjuste)> _imagens() async {
    final fundo = await fundoDoCracha();
    final foto = await fotoDoBadge(badgeData) ?? await fotoPadrao();
    return (fundo, foto, const FotoAjuste());
  }
}

/// O desenho: `AspectRatio` + `CustomPaint`, com o toque na foto por cima.
class _Desenho extends StatelessWidget {
  final ui.Image fundo;
  final ui.Image foto;
  final FotoAjuste ajuste;
  final CrachaDados dados;
  final VoidCallback onImageTap;

  const _Desenho({
    required this.fundo,
    required this.foto,
    required this.ajuste,
    required this.dados,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    // Sem `AspectRatio` aqui: `buildBadgeStage` já entrega largura E altura
    // calculadas (o palco está dentro de um `SingleChildScrollView` no
    // mobile, onde as duas viriam infinitas e o `AspectRatio` estouraria).
    // Este widget ocupa o que o pai deu.
    return LayoutBuilder(
      builder: (context, c) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onImageTap,
          child: CustomPaint(
            // `c.biggest` é finito porque quem restringe é o `SizedBox` do
            // palco. É este detalhe que impede
            // "BoxConstraints forces an infinite width and infinite height".
            size: c.biggest,
            painter: CrachaPainter(
              fundo: fundo,
              foto: foto,
              dados: dados,
              ajuste: ajuste,
            ),
          ),
        );
      },
    );
  }
}

/// Palco do crachá: RepaintBoundary com largura E altura travadas.
///
/// SEM `FittedBox` de propósito — ele passa restrições infinitas ao filho e
/// o `CustomPaint` explode (ver o cabeçalho).
///
/// Por que `width` E `height`: o `AspectRatio` do `BadgeView` resolve a
/// altura a partir da largura, mas só quando pelo menos UM dos dois é
/// finito. Com as duas infinitas (que é o que o preview mobile entrega,
/// dentro de um `SingleChildScrollView`) ele estoura com
/// "RenderAspectRatio has unbounded constraints". Calcular a altura aqui
/// dá o número pronto e elimina a dependência.
Widget buildBadgeStage({
  required GlobalKey globalKey,
  required BadgeData badge,
  required double boxWidth,
  required VoidCallback onImageTap,
}) {
  final largura = boxWidth.clamp(kStageMinWidth, kStageMaxWidth);
  final altura = largura * BadgeGeo.h / BadgeGeo.w;

  return RepaintBoundary(
    key: globalKey,
    child: SizedBox(
      width: largura,
      height: altura,
      child: BadgeView(
        badgeData: badge,
        onImageTap: onImageTap,
        onNameTap: () {},
        onRoleTap: () {},
        onDepartmentTap: () {},
      ),
    ),
  );
}