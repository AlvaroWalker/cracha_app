import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_tokens.dart';

/// Card padronizado moderno com elevação, borda sutil e padding consistentes.
/// Adapta-se ao tema (claro/escuro).
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
          color: isDark ? AppColors.darkBorder : AppColors.borderColor,
          width: 1,
        );
    final effectiveColor = color ??
        (isDark ? AppColors.darkCard : AppColors.cardColor);

    final card = Container(
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: radius,
        border: Border.fromBorderSide(effectiveBorder),
        boxShadow: isDark ? AppColors.darkShadowList : AppColors.defaultShadow,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: card,
        ),
      );
    }
    return card;
  }
}
