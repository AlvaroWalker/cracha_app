import 'package:flutter/material.dart';

/// Paleta de cores do app Campo Verde — Emissor de Crachás.
///
/// Identidade visual:
/// - brand verde esmeralda (institucional)
/// - accent dourado (uso restrito: brasão)
/// - tons neutros com base slate
class AppColors {
  AppColors._();

  // ===========================================================================
  // BRAND (verde esmeralda)
  // ===========================================================================

  /// Verde esmeralda institucional (modo claro).
  static const Color brandLight = Color(0xFF047857);

  /// Verde esmeralda brilhante (modo escuro).
  static const Color brandDark = Color(0xFF34D399);

  /// Dourado — uso restrito ao brasão.
  static const Color accentGold = Color(0xFFD4AF37);

  // ===========================================================================
  // SUPERFÍCIES
  // ===========================================================================

  /// Background (light) / Background (dark).
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bgDark = Color(0xFF0A0D0F);

  /// Surface (light) / Surface (dark).
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF161B1F);

  /// Border (light) / Border (dark).
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF1E2A33);

  // ===========================================================================
  // TIPOGRAFIA
  // ===========================================================================

  /// Texto primário (light / dark).
  static const Color textLight = Color(0xFF0F172A);
  static const Color textDark = Color(0xFFE2E8F0);

  /// Texto secundário/muted (light / dark).
  static const Color mutedLight = Color(0xFF64748B);
  static const Color mutedDark = Color(0xFF94A3B8);

  // ===========================================================================
  // SEMÂNTICA (compartilhada)
  // ===========================================================================

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ===========================================================================
  // HELPERS DE BRIGHTNESS
  // ===========================================================================

  // Aliases de compatibilidade (legado).
  static const Color primaryColor = brandLight;
  static const Color secondaryColor = brandLight;
  static const Color accentColor = accentGold;

  static const Color textColor = textLight;
  static const Color subtitleColor = mutedLight;
  static const Color backgroundColor = bgLight;
  static const Color cardColor = surfaceLight;
  static const Color borderColor = borderLight;
  static const Color errorColor = danger;
  static const Color successColor = success;
  static const Color warningColor = warning;
  static const Color infoIconLight = info;
  static const Color infoTextLight = info;
  static const Color infoBgLight = surfaceLight;

  static const Color darkPrimary = brandDark;
  static const Color darkSecondary = brandDark;
  static const Color darkAccent = accentGold;
  static const Color darkBackground = bgDark;
  static const Color darkSurface = surfaceDark;
  static const Color darkSurfaceVariant = surfaceDark;
  static const Color darkCard = surfaceDark;
  static const Color darkText = textDark;
  static const Color darkTextSecondary = mutedDark;
  static const Color darkHint = mutedDark;
  static const Color darkBorder = borderDark;
  static const Color darkDivider = borderDark;
  static const Color darkInfoIcon = info;
  static const Color darkInfoText = info;
  static const Color darkInfoBg = surfaceDark;
  static const Color darkCardElevated = surfaceDark;
  static const Color darkBorderHighlight = borderDark;
  static const Color darkStudioBackdrop = bgDark;
  static const Color darkShadow = Color(0xFF000000);

  static const Color lightGreen = Color(0xFFF0F7F1);
  static const Color mediumGreen = brandLight;
  static const Color darkGreen = brandDark;
  static const Color mediumGreen2 = brandLight;
  static const Color surfaceSubtle = surfaceLight;
  static const Color primaryDark = brandDark;
  static const Color mutedColor = mutedLight;
  static const Color studioBackdrop = bgLight;

  /// Sombra padrão (compat). Prefira `AppShadow.md` nos widgets novos.
  static const List<BoxShadow> defaultShadow = [
    BoxShadow(
      color: Color(0x10000000),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
  ];

  /// Sombra dark (compat). Mesmo shape, sem tinta.
  static const List<BoxShadow> darkShadowList = [
    BoxShadow(
      color: Color(0x40000000),
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
  ];
  static Color brand(Brightness b) =>
      b == Brightness.dark ? brandDark : brandLight;

  /// Background para o brightness informado.
  static Color bg(Brightness b) => b == Brightness.dark ? bgDark : bgLight;

  /// Surface para o brightness informado.
  static Color surface(Brightness b) =>
      b == Brightness.dark ? surfaceDark : surfaceLight;

  /// Border para o brightness informado.
  static Color border(Brightness b) =>
      b == Brightness.dark ? borderDark : borderLight;

  /// Texto primário para o brightness informado.
  static Color text(Brightness b) =>
      b == Brightness.dark ? textDark : textLight;

  /// Texto muted para o brightness informado.
  static Color muted(Brightness b) =>
      b == Brightness.dark ? mutedDark : mutedLight;
}
