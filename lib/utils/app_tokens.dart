import 'package:flutter/material.dart';

/// Tokens de espaçamento padronizado do app.
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

/// Tokens de raio de borda padronizado.
class AppRadius {
  AppRadius._();

  static const double sm = 6;
  static const double md = 10;
  static const double lg = 14;
  static const double xl = 20;
  static const double pill = 999;

  /// Alias de compat: código antigo usava `AppRadius.full`.
  static const double full = pill;
}

/// Tokens de sombra com tinta verde sutil (BRAND) e neutra (NEUTRO).
/// Todos carregam um toque verde para reforçar a identidade visual.
class AppShadow {
  AppShadow._();

  /// Sombra pequena — uso geral, chips, tags, ícones em superfícies.
  static List<BoxShadow> sm(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _brandShadow(
      y: 1,
      blur: 3,
      alpha: isDark ? 0.30 : 0.06,
      neutralAlpha: isDark ? 0.40 : 0.04,
    );
  }

  /// Sombra média — cards, painéis, header.
  static List<BoxShadow> md(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _brandShadow(
      y: 4,
      blur: 12,
      alpha: isDark ? 0.28 : 0.08,
      neutralAlpha: isDark ? 0.35 : 0.05,
    );
  }

  /// Sombra grande — modais, dock elevada, dropdowns.
  static List<BoxShadow> lg(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _brandShadow(
      y: 12,
      blur: 32,
      alpha: isDark ? 0.32 : 0.10,
      neutralAlpha: isDark ? 0.45 : 0.06,
    );
  }

  static List<BoxShadow> _brandShadow({
    required double y,
    required double blur,
    required double alpha,
    required double neutralAlpha,
  }) {
    // BRAND tinta verde sutil (#047857) + tinta neutra complementar.
    return <BoxShadow>[
      BoxShadow(
        color: const Color(0xFF047857).withValues(alpha: alpha),
        blurRadius: blur,
        offset: Offset(0, y),
      ),
      BoxShadow(
        color: const Color(0xFF0F172A).withValues(alpha: neutralAlpha),
        blurRadius: blur * 0.4,
        offset: Offset(0, 1),
      ),
    ];
  }
}

/// Durações de animação padronizadas.
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 320);
}

/// Breakpoints responsivos do app.
class AppBreakpoint {
  AppBreakpoint._();

  /// Largura mínima para o layout desktop (dock lateral 56px + conteúdo).
  static const double desktop = 1024;
}

/// Aliases de compatibilidade (legado). Outros módulos ainda referenciam
/// os nomes antigos; enquanto a migração global não acontece, expomos os
/// mesmos símbolos para manter a base compilando.
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
