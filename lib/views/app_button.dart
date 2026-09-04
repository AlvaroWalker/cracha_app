import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_tokens.dart';

/// Botão padronizado de alto padrão visual: primário, secundário, acento dourado, texto, ícone.
/// Adapta automaticamente ao tema (claro/escuro).
class AppButton extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool expanded;
  final bool loading;
  final String? tooltip;

  const AppButton({
    super.key,
    this.label,
    this.icon,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.expanded = false,
    this.loading = false,
    this.tooltip,
  });

  const AppButton.primary({
    super.key,
    this.label,
    this.icon,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.expanded = false,
    this.loading = false,
    this.tooltip,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    this.label,
    this.icon,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.expanded = false,
    this.loading = false,
    this.tooltip,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.accent({
    super.key,
    this.label,
    this.icon,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.expanded = false,
    this.loading = false,
    this.tooltip,
  }) : variant = AppButtonVariant.accent;

  const AppButton.text({
    super.key,
    this.label,
    this.icon,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.expanded = false,
    this.loading = false,
    this.tooltip,
  }) : variant = AppButtonVariant.text;

  const AppButton.danger({
    super.key,
    this.label,
    this.icon,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.expanded = false,
    this.loading = false,
    this.tooltip,
  }) : variant = AppButtonVariant.danger;

  const AppButton.icon({
    super.key,
    this.icon,
    required this.onPressed,
    this.size = AppButtonSize.md,
    this.loading = false,
    this.tooltip,
  })  : variant = AppButtonVariant.icon,
        label = null,
        expanded = false;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _buildStyle(context);
    final padding = _getPadding();
    final iconSize = _getIconSize();
    final effectiveCallback = loading ? null : onPressed;

    Widget button;

    if (variant == AppButtonVariant.icon) {
      button = IconButton(
        icon: loading
            ? SizedBox(
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _getForegroundColor(context),
                ),
              )
            : Icon(icon, size: iconSize),
        onPressed: effectiveCallback,
        style: buttonStyle,
        tooltip: tooltip,
      );
    } else {
      final content = Row(
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading) ...[
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _getForegroundColor(context),
              ),
            ),
            if (label != null) const SizedBox(width: AppSpacing.sm),
          ] else if (icon != null) ...[
            Icon(icon, size: iconSize),
            if (label != null) const SizedBox(width: AppSpacing.sm),
          ],
          if (label != null)
            Text(
              label!,
              style: TextStyle(
                fontFamily: 'Rawline',
                fontSize: _getFontSize(),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
        ],
      );

      button = ElevatedButton(
        onPressed: effectiveCallback,
        style: buttonStyle.copyWith(
          padding: WidgetStatePropertyAll(padding),
        ),
        child: content,
      );

      if (tooltip != null) {
        button = Tooltip(message: tooltip!, child: button);
      }
    }

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  ButtonStyle _buildStyle(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final foregroundColor = _getForegroundColor(context);
    final backgroundColor = _getBackgroundColor(context);
    final sideColor = _getSideColor(context);

    return ButtonStyle(
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return isDark ? AppColors.darkHint : AppColors.mutedColor;
        }
        return foregroundColor;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return isDark ? AppColors.darkSurfaceVariant : Colors.grey.shade200;
        }
        if (states.contains(WidgetState.hovered) && backgroundColor != null) {
          return backgroundColor.withValues(alpha: isDark ? 0.88 : 0.92);
        }
        return backgroundColor;
      }),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered) &&
            (variant == AppButtonVariant.primary || variant == AppButtonVariant.accent)) {
          return 3.0;
        }
        return 0.0;
      }),
      side: WidgetStatePropertyAll(
        sideColor != null ? BorderSide(color: sideColor, width: 1.2) : null,
      ),
    );
  }

  Color _getForegroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.darkPrimary : AppColors.primaryColor;
    switch (variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.danger:
        return Colors.white;
      case AppButtonVariant.accent:
        return isDark ? Colors.black : const Color(0xFF5E4500);
      case AppButtonVariant.secondary:
        return primary;
      case AppButtonVariant.text:
        return isDark ? AppColors.darkText : AppColors.textColor;
      case AppButtonVariant.icon:
        return isDark ? AppColors.darkText : AppColors.textColor;
    }
  }

  Color? _getBackgroundColor(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    switch (variant) {
      case AppButtonVariant.primary:
        return theme.colorScheme.primary;
      case AppButtonVariant.accent:
        return isDark ? AppColors.darkAccent : AppColors.accentColor;
      case AppButtonVariant.danger:
        return AppColors.errorColor;
      case AppButtonVariant.secondary:
        return isDark ? AppColors.darkSurfaceVariant : Colors.white;
      case AppButtonVariant.text:
        return Colors.transparent;
      case AppButtonVariant.icon:
        return isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceSubtle;
    }
  }

  Color? _getSideColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (variant) {
      case AppButtonVariant.secondary:
        return isDark ? AppColors.darkBorderHighlight : AppColors.borderColor;
      case AppButtonVariant.accent:
        return isDark ? AppColors.darkAccent : AppColors.accentColor;
      default:
        return null;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8);
      case AppButtonSize.md:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12);
      case AppButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 16);
    }
  }

  double _getFontSize() {
    switch (size) {
      case AppButtonSize.sm:
        return 12.5;
      case AppButtonSize.md:
        return 14;
      case AppButtonSize.lg:
        return 15.5;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.sm:
        return 16;
      case AppButtonSize.md:
        return 18;
      case AppButtonSize.lg:
        return 22;
    }
  }
}

enum AppButtonVariant { primary, secondary, accent, text, danger, icon }

enum AppButtonSize { sm, md, lg }

