import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_tokens.dart';

/// Card padronizado moderno (Linear / Vercel):
/// - Superfície limpa com borda hairline
/// - Micro-sombra elegante em múltiplas camadas
/// - Hover/tap suave
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Color? color;
  final BorderSide? border;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation,
    this.color,
    this.border,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.lg);
    final effectiveBorder = border ??
        BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        );
    final effectiveColor = color ??
        (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    final card = Container(
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: radius,
        border: Border.fromBorderSide(effectiveBorder),
        boxShadow: AppShadow.sm(context),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpace.lg),
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          hoverColor: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.02),
          child: card,
        ),
      );
    }
    return card;
  }
}
