// ═══════════════════════════════════════════════════════════════════════════
// ARQUIVO SAGRADO — NÃO MEXER SEM CONFERIR O PDF
//
// Tudo que define o crachá impresso mora AQUI e SOMENTE aqui:
//  - [BadgeGeometry]: posições e tamanhos (foto, cartão de nome, palco).
//  - [BadgeTextStyles]: fontes do crachá (NÃO usa text_styles.dart global —
//    foi exatamente uma mudança global que encolheu as fontes uma vez).
//  - [BadgeView]: o widget do crachá, pixel a pixel.
//  - [buildBadgeStage]: palco padrão (RepaintBoundary + FittedBox) com a
//    GlobalKey que o PdfGenerator captura.
//
// Se mudar QUALQUER número aqui, regenere o golden
// (`flutter test --update-goldens test/badge_golden_test.dart`),
// confira 1 PDF individual + 1 em lote, e só então publique.
// ═══════════════════════════════════════════════════════════════════════════
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../models/badge_data.dart';

/// Geometria do crachá — espelha a arte `assets/images/CRACHA.png`
/// (1277×2007). Unidade: logical pixels.
class BadgeGeometry {
  BadgeGeometry._();

  /// Tamanho fixo do cartão.
  static const double cardWidth = 333.4;
  static const double cardHeight = 523.19;

  /// Foto: 153×189, topo em 175 (alinha com a moldura escura da arte).
  static const double photoWidth = 153;
  static const double photoHeight = 189;
  static const double photoTop = 175;

  /// Cartão branco de identificação: 280×135, base a 17 do rodapé.
  static const double infoWidth = 280;
  static const double infoHeight = 135;
  static const double infoBottom = 17;

  /// Largura do palco (preview): nunca passa de 340, reduz até 220.
  static const double stageMaxWidth = 340;
  static const double stageMinWidth = 220;
}

/// Fontes do crachá — VALORES DO REPO FUNCIONAL. Não "modernizar".
///
/// Cor fixada em PRETO de propósito: o cartão do crachá é sempre branco,
/// então herdar a cor do tema (branco no modo escuro) apagava os dados
/// e saía branco até no PDF.
class BadgeTextStyles {
  BadgeTextStyles._();

  static const TextStyle name = TextStyle(
    fontFamily: 'Rawline',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: 0,
    color: Colors.black,
  );

  static const TextStyle role = TextStyle(
    fontFamily: 'Rawline',
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: 0,
    color: Colors.black,
  );

  static const TextStyle department = TextStyle(
    fontFamily: 'Rawline',
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: 0.2,
    color: Colors.black,
  );
}

/// Palco padrão do crachá: captura via [globalKey] + redução uniforme.
///
/// Espelha o repo funcional — o crachá NUNCA é cortado, só reduzido.
Widget buildBadgeStage({
  required GlobalKey globalKey,
  required BadgeData badge,
  required double boxWidth,
  required VoidCallback onImageTap,
}) {
  return RepaintBoundary(
    key: globalKey,
    child: SizedBox(
      width: boxWidth.clamp(
        BadgeGeometry.stageMinWidth,
        BadgeGeometry.stageMaxWidth,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: BadgeView(
          badgeData: badge,
          onImageTap: onImageTap,
          onNameTap: () {},
          onRoleTap: () {},
          onDepartmentTap: () {},
        ),
      ),
    ),
  );
}

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

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Sem ClipRRect aqui DE PROPÓSITO: a arte já traz os cantos
        // arredondados de fábrica; clipar de novo mordia os cantos
        // (recorte branco visível no PDF exportado).
        Image.asset(
          'assets/images/CRACHA.png',
          width: BadgeGeometry.cardWidth,
          height: BadgeGeometry.cardHeight,
          fit: BoxFit.contain,
        ),
        Positioned(
          top: BadgeGeometry.photoTop,
          child: _buildPhotoSection(),
        ),
        Positioned(
          bottom: BadgeGeometry.infoBottom,
          child: _buildInfoSection(),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return GestureDetector(
      onTap: onImageTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: badgeData.photo != null
              ? Image.memory(
                  badgeData.photo!,
                  width: BadgeGeometry.photoWidth,
                  height: BadgeGeometry.photoHeight,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  'assets/images/placeholder.png',
                  width: BadgeGeometry.photoWidth,
                  height: BadgeGeometry.photoHeight,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox(
                      width: BadgeGeometry.photoWidth,
                      height: BadgeGeometry.photoHeight,
                      child: Icon(Icons.person, size: 60, color: Colors.grey),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      width: BadgeGeometry.infoWidth,
      height: BadgeGeometry.infoHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Spacer(),
          _buildTextSection(),
          const Spacer(),
          const Divider(
              color: Colors.black, thickness: 2, indent: 15, endIndent: 15),
          const Spacer(),
          _buildDepartmentText(),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTextSection() {
    final bool isNameEmpty = badgeData.name.trim().isEmpty;
    final bool isRoleEmpty = badgeData.role.trim().isEmpty;

    return Flex(
      direction: Axis.vertical,
      spacing: 4,
      children: [
        GestureDetector(
          onTap: onNameTap,
          child: AutoSizeText(
            isNameEmpty ? 'NOME DO FUNCIONÁRIO' : badgeData.name,
            textScaleFactor: 0.9,
            textAlign: TextAlign.center,
            maxLines: 2,
            minFontSize: 8,
            style: isNameEmpty
                ? BadgeTextStyles.name.copyWith(color: Colors.grey.shade400)
                : BadgeTextStyles.name,
          ),
        ),
        GestureDetector(
          onTap: onRoleTap,
          child: AutoSizeText(
            isRoleEmpty ? 'CARGO / FUNÇÃO' : badgeData.role,
            textScaleFactor: 0.9,
            textAlign: TextAlign.center,
            maxLines: 2,
            minFontSize: 8,
            style: isRoleEmpty
                ? BadgeTextStyles.role.copyWith(color: Colors.grey.shade400)
                : BadgeTextStyles.role,
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentText() {
    final bool isDeptEmpty = badgeData.department.trim().isEmpty;

    return GestureDetector(
      onTap: onDepartmentTap,
      child: AutoSizeText(
        isDeptEmpty ? 'SECRETARIA / DEPARTAMENTO' : badgeData.department,
        textAlign: TextAlign.center,
        maxLines: 2,
        minFontSize: 8,
        style: isDeptEmpty
            ? BadgeTextStyles.department.copyWith(color: Colors.grey.shade400)
            : BadgeTextStyles.department,
      ),
    );
  }
}
