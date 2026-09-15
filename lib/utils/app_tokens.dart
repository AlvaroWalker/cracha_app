import 'package:flutter/material.dart';

/// Tokens de espaçamento padronizado do app (grid de 4px/8px).
class AppSpace {
  AppSpace._();

  static const double xs = 4;   // 4
  static const double sm = 8;   // 8
  static const double md = 12;  // 12
  static const double lg = 16;  // 16
  static const double xl = 24;  // 24
  static const double xxl = 32; // 32
  static const double xxxl = 48; // 48
  static const double huge = 64; // 64
}

/// Tokens de raio de borda padronizado (Modern SaaS).
class AppRadius {
  AppRadius._();

  static const double xs = 4;
  static const double sm = 6;
  static const double md = 10;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;
  static const double pill = 999;

  /// Alias de compat: código antigo usava `AppRadius.full`.
  static const double full = pill;
}

/// Tokens de sombra elegantes com micro-dispersão e camadas duplas (Linear/Vercel).
class AppShadow {
  AppShadow._();

  /// Sombra sutil para botões, badges, chips e pequenos elementos.
  static List<BoxShadow> sm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return const [
        BoxShadow(
          color: Color(0x60000000),
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
      ];
    }
    return const [
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 3,
        offset: Offset(0, 1),
      ),
      BoxShadow(
        color: Color(0x05000000),
        blurRadius: 1,
        offset: Offset(0, 1),
      ),
    ];
  }

  /// Sombra média — cards, painéis elevados, menus suspensos.
  static List<BoxShadow> md(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return [
        const BoxShadow(
          color: Color(0x70000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF059669).withValues(alpha: 0.04),
          blurRadius: 20,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return const [
      BoxShadow(
        color: Color(0x0D000000),
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
      BoxShadow(
        color: Color(0x05000000),
        blurRadius: 2,
        offset: Offset(0, 1),
      ),
    ];
  }

  /// Sombra grande — modais, popovers suspensos, palco do crachá.
  static List<BoxShadow> lg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return [
        const BoxShadow(
          color: Color(0x90000000),
          blurRadius: 32,
          offset: Offset(0, 12),
        ),
        BoxShadow(
          color: const Color(0xFF10B981).withValues(alpha: 0.08),
          blurRadius: 36,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return const [
      BoxShadow(
        color: Color(0x18000000),
        blurRadius: 24,
        offset: Offset(0, 12),
      ),
      BoxShadow(
        color: Color(0x08000000),
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
    ];
  }

  /// Sombra física realista para o crachá no palco de preview.
  static List<BoxShadow> badgeStage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return [
        const BoxShadow(
          color: Color(0xA0000000),
          blurRadius: 30,
          offset: Offset(0, 12),
        ),
        const BoxShadow(
          color: Color(0x50000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
        BoxShadow(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          blurRadius: 40,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return const [
      BoxShadow(
        color: Color(0x1F000000),
        blurRadius: 24,
        offset: Offset(0, 10),
      ),
      BoxShadow(
        color: Color(0x0F000000),
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
    ];
  }
}

/// Durações de animação padronizadas e curvas naturais.
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 360);

  static const Curve defaultCurve = Curves.easeOutCubic;
}

/// Breakpoints responsivos do app.
class AppBreakpoint {
  AppBreakpoint._();

  /// Largura mínima para o layout desktop com Sidebar lateral completa.
  static const double desktop = 1024;
  static const double tablet = 768;
}

/// Aliases de compatibilidade (legado).
class AppSpacing {
  AppSpacing._();
  static const double xs = AppSpace.xs;
  static const double sm = AppSpace.sm;
  static const double md = AppSpace.md;
  static const double lg = AppSpace.lg;
  static const double xl = AppSpace.xl;
  static const double xxl = AppSpace.xxl;
  static const double xxxl = AppSpace.xxxl;
}

class AppBreakpoints {
  AppBreakpoints._();
  static const double phone = 600;
  static const double desktop = 1024;
}

class AppElevation {
  AppElevation._();
  static const double none = 0;
  static const double sm = 2;
  static const double md = 4;
  static const double lg = 8;
  static const double xl = 16;
}
