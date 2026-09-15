import 'package:flutter/material.dart';

/// Paleta de cores do app Campo Verde — Emissor de Crachás.
///
/// Identidade visual: Modern SaaS (Linear / Vercel):
/// - Brand: Verde esmeralda institucional rico e nítido
/// - Accent: Dourado institucional (brasão de Campo Verde)
/// - Neutros: Dark zinc/slate profundo e light ultra-limpo
/// - Superfícies em camadas com bordas hairline translúcidas
class AppColors {
  AppColors._();

  // ===========================================================================
  // BRAND (verde esmeralda institucional)
  // ===========================================================================

  /// Verde esmeralda rico (modo claro) — alto contraste e sofisticação.
  static const Color brandLight = Color(0xFF059669);

  /// Verde esmeralda brilhante (modo escuro) — legibilidade e luminosidade.
  static const Color brandDark = Color(0xFF10B981);

  /// Verde esmeralda neon sutil (para highlights e indicadores ativos).
  static const Color brandAccent = Color(0xFF34D399);

  /// Dourado — uso restrito ao brasão institucional de Campo Verde.
  static const Color accentGold = Color(0xFFD4AF37);

  // ===========================================================================
  // SUPERFÍCIES & BACKGROUNDS (Linear / Vercel style)
  // ===========================================================================

  /// Background base (light / dark).
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bgDark = Color(0xFF080A0C);

  /// Surface primária (light / dark).
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF101418);

  /// Surface elevada / cards de nível 2.
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedDark = Color(0xFF161B20);

  /// Surface de sobreposição / hover / containers compactos.
  static const Color surfaceSubtleLight = Color(0xFFF1F5F9);
  static const Color surfaceSubtleDark = Color(0xFF1D232A);

  /// Bordas hairline elegantes (light / dark).
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF222933);

  /// Bordas de destaque sutil (hover / focus).
  static const Color borderHighlightLight = Color(0xFFCBD5E1);
  static const Color borderHighlightDark = Color(0xFF2F3846);

  // ===========================================================================
  // TIPOGRAFIA
  // ===========================================================================

  /// Texto primário (light / dark).
  static const Color textLight = Color(0xFF0F172A);
  static const Color textDark = Color(0xFFF1F5F9);

  /// Texto secundário/muted (light / dark).
  static const Color mutedLight = Color(0xFF64748B);
  static const Color mutedDark = Color(0xFF94A3B8);

  /// Texto sutil/placeholder.
  static const Color subtleLight = Color(0xFF94A3B8);
  static const Color subtleDark = Color(0xFF64748B);

  // ===========================================================================
  // SEMÂNTICA
  // ===========================================================================

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ===========================================================================
  // GRADIENTES & GLOWS (Modern SaaS)
  // ===========================================================================

  /// Gradiente institucional suave para headers e destaques de marca.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF047857)],
  );

  /// Gradiente para botões primários com acabamento moderno.
  static const LinearGradient buttonPrimaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  /// Brilho radial para painéis de destaque escuros.
  static RadialGradient darkGlowGradient(Color baseBg) => RadialGradient(
    center: const Alignment(0, -0.5),
    radius: 1.1,
    colors: [
      brandDark.withValues(alpha: 0.14),
      baseBg,
    ],
  );

  // ===========================================================================
  // ALIASES DE COMPATIBILIDADE (Legado preservado)
  // ===========================================================================

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
  static const Color darkSurfaceVariant = surfaceElevatedDark;
  static const Color darkCard = surfaceDark;
  static const Color darkText = textDark;
  static const Color darkTextSecondary = mutedDark;
  static const Color darkHint = mutedDark;
  static const Color darkBorder = borderDark;
  static const Color darkDivider = borderDark;
  static const Color darkInfoIcon = info;
  static const Color darkInfoText = info;
  static const Color darkInfoBg = surfaceDark;
  static const Color darkCardElevated = surfaceElevatedDark;
  static const Color darkBorderHighlight = borderHighlightDark;
  static const Color darkStudioBackdrop = bgDark;
  static const Color darkShadow = Color(0xFF000000);

  static const Color lightGreen = Color(0xFFECFDF5);
  static const Color mediumGreen = brandLight;
  static const Color darkGreen = Color(0xFF047857);
  static const Color mediumGreen2 = brandLight;
  static const Color surfaceSubtle = surfaceSubtleLight;
  static const Color primaryDark = brandDark;
  static const Color mutedColor = mutedLight;
  static const Color studioBackdrop = bgLight;

  /// Sombra padrão refinada.
  static const List<BoxShadow> defaultShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 3,
    ),
    BoxShadow(
      color: Color(0x08000000),
      offset: Offset(0, 4),
      blurRadius: 8,
    ),
  ];

  /// Sombra dark refinada.
  static const List<BoxShadow> darkShadowList = [
    BoxShadow(
      color: Color(0x60000000),
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
    BoxShadow(
      color: Color(0x40000000),
      offset: Offset(0, 8),
      blurRadius: 20,
    ),
  ];

  // ===========================================================================
  // HELPERS DINÂMICOS
  // ===========================================================================

  static Color brand(Brightness b) =>
      b == Brightness.dark ? brandDark : brandLight;

  static Color bg(Brightness b) => b == Brightness.dark ? bgDark : bgLight;

  static Color surface(Brightness b) =>
      b == Brightness.dark ? surfaceDark : surfaceLight;

  static Color surfaceElevated(Brightness b) =>
      b == Brightness.dark ? surfaceElevatedDark : surfaceElevatedLight;

  static Color surfaceSubtleColor(Brightness b) =>
      b == Brightness.dark ? surfaceSubtleDark : surfaceSubtleLight;

  static Color border(Brightness b) =>
      b == Brightness.dark ? borderDark : borderLight;

  static Color borderHighlight(Brightness b) =>
      b == Brightness.dark ? borderHighlightDark : borderHighlightLight;

  static Color text(Brightness b) =>
      b == Brightness.dark ? textDark : textLight;

  static Color muted(Brightness b) =>
      b == Brightness.dark ? mutedDark : mutedLight;
}
