import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Helpers de TextStyle usando Rawline com pesos 400/500/600/700
/// e letter-spacing agressivo em title (-0.02em).
///
/// `em` em Flutter é convertido multiplicando pelo fontSize.
/// -0.02em = fontSize * -0.02
class AppTextStyles {
  AppTextStyles._();

  static const String _family = AppTheme.fontFamily;

  // ===========================================================================
  // PESOS BASE
  // ===========================================================================

  /// 400 — Regular (corpo).
  static const FontWeight w400 = FontWeight.w400;

  /// 500 — Medium (ênfase leve).
  static const FontWeight w500 = FontWeight.w500;

  /// 600 — SemiBold (botões, labels).
  static const FontWeight w600 = FontWeight.w600;

  /// 700 — Bold (títulos, destaques).
  static const FontWeight w700 = FontWeight.w700;

  // ===========================================================================
  // TÍTULOS (letter-spacing -0.02em agressivo)
  // ===========================================================================

  /// Display extra grande (48 / w700 / -0.02em).
  static const TextStyle display = TextStyle(
    fontFamily: _family,
    fontSize: 48,
    fontWeight: w700,
    height: 1.05,
    letterSpacing: -0.96, // -0.02em
  );

  /// Display médio (32 / w700 / -0.02em).
  static const TextStyle displayMedium = TextStyle(
    fontFamily: _family,
    fontSize: 32,
    fontWeight: w700,
    height: 1.1,
    letterSpacing: -0.64, // -0.02em
  );

  /// Título principal (24 / w700 / -0.02em).
  static const TextStyle title = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: w700,
    height: 1.2,
    letterSpacing: -0.48, // -0.02em
  );

  /// Subtítulo (18 / w600 / -0.02em).
  static const TextStyle subtitle = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    fontWeight: w600,
    height: 1.25,
    letterSpacing: -0.36, // -0.02em
  );

  /// Section heading (15 / w600 / -0.02em).
  static const TextStyle sectionHeading = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: w600,
    height: 1.3,
    letterSpacing: -0.30, // -0.02em
  );

  // ===========================================================================
  // CORPO
  // ===========================================================================

  /// Corpo padrão (16 / w400).
  static const TextStyle body = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: w400,
    height: 1.45,
    letterSpacing: 0,
  );

  /// Corpo médio (14 / w400).
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: w400,
    height: 1.45,
    letterSpacing: 0,
  );

  /// Corpo pequeno (12 / w400).
  static const TextStyle bodySmall = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: w400,
    height: 1.4,
    letterSpacing: 0.1,
  );

  /// Corpo com ênfase (14 / w500).
  static const TextStyle bodyEmphasis = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: w500,
    height: 1.45,
    letterSpacing: 0,
  );

  // ===========================================================================
  // LABELS / AÇÕES
  // ===========================================================================

  /// Botão / label de ação (14 / w600).
  static const TextStyle button = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: w600,
    height: 1.1,
    letterSpacing: 0,
  );

  /// Label grande (13 / w600).
  static const TextStyle label = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: w600,
    height: 1.2,
    letterSpacing: 0.1,
  );

  /// Label pequeno / tag (11 / w500 / tracking +).
  static const TextStyle labelSmall = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    fontWeight: w500,
    height: 1.2,
    letterSpacing: 0.4,
  );

  /// Caption (12 / w500 / tracking +).
  static const TextStyle caption = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: w500,
    height: 1.3,
    letterSpacing: 0.2,
  );

  // ===========================================================================
  // UTILITÁRIOS
  // ===========================================================================

  /// Aplica cor ao estilo base.
  static TextStyle withColor(TextStyle base, Color color) =>
      base.copyWith(color: color);

  /// Combina com o colorScheme para herdar cor onSurface.
  static TextStyle onSurface(BuildContext context, TextStyle base) =>
      base.copyWith(color: Theme.of(context).colorScheme.onSurface);

  /// Combina com color muted do tema.
  static TextStyle muted(BuildContext context, TextStyle base) =>
      base.copyWith(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF94A3B8)
            : const Color(0xFF64748B),
      );

  // ===========================================================================
  // ALIASES DE COMPATIBILIDADE (legado). BadgeView e demais ainda usam
  // nameStyle/roleStyle/departmentStyle.
  // ===========================================================================

  /// Nome do servidor (legado). Aplicado dentro do BadgeView.
  @Deprecated('Crachá mora em badge_design.dart (BadgeTextStyles.name). '
      'Não usar — risco de quebrar o PDF.')
  static const TextStyle nameStyle = TextStyle(
    fontFamily: _family,
    fontSize: 22,
    fontWeight: w700,
    height: 1.15,
    letterSpacing: 0,
  );

  /// Cargo do servidor (legado). Aplicado dentro do BadgeView.
  @Deprecated('Crachá mora em badge_design.dart (BadgeTextStyles.role). '
      'Não usar — risco de quebrar o PDF.')
  static const TextStyle roleStyle = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: w700,
    height: 1.15,
    letterSpacing: 0,
  );

  /// Secretaria do servidor (legado). Aplicado dentro do BadgeView.
  @Deprecated('Crachá mora em badge_design.dart (BadgeTextStyles.department). '
      'Não usar — risco de quebrar o PDF.')
  static const TextStyle departmentStyle = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: w700,
    height: 1.15,
    letterSpacing: 0.2,
  );
}
