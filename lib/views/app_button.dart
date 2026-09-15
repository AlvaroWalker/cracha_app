import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_tokens.dart';

/// Botão padronizado de alto padrão visual (Linear / Vercel):
/// - primary: Verde esmeralda institucional com alto contraste
/// - secondary: Superfície neutra com borda hairline
/// - accent: Dourado institucional
/// - danger: Ação destrutiva com acabamento polido
/// - text: Botão minimalista
/// - icon: Botão utilitário compacto
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final padding = _getPadding();
    final iconSize = _getIconSize();
    final effectiveCallback = loading ? null : onPressed;

    Widget button;

    if (variant == AppButtonVariant.icon) {
      final fgColor = isDark ? AppColors.textDark : AppColors.textLight;
      final border = BorderSide(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        width: 1,
      );
      final bg = isDark ? const Color(0xFF14191F) : Colors.white;

      button = Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: border,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: effectiveCallback,
          child: Padding(
            padding: EdgeInsets.all(_getIconOnlyPadding()),
            child: loading
                ? SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fgColor,
                    ),
                  )
                : Icon(icon, size: iconSize, color: fgColor),
          ),
        ),
      );

      if (tooltip != null) {
        button = Tooltip(message: tooltip!, child: button);
      }
    } else {
      final buttonStyle = _buildStyle(context);
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
            if (label != null) const SizedBox(width: AppSpace.sm),
          ] else if (icon != null) ...[
            Icon(icon, size: iconSize),
            if (label != null) const SizedBox(width: AppSpace.sm),
          ],
          if (label != null)
            Text(
              label!,
              style: TextStyle(
                fontFamily: 'Rawline',
                fontSize: _getFontSize(),
                fontWeight: FontWeight.w600,
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
          return isDark ? AppColors.mutedDark.withValues(alpha: 0.5) : AppColors.mutedLight.withValues(alpha: 0.5);
        }
        return foregroundColor;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return isDark ? const Color(0xFF161B21) : const Color(0xFFF1F5F9);
        }
        if (states.contains(WidgetState.hovered) && backgroundColor != null) {
          if (variant == AppButtonVariant.secondary) {
            return isDark ? const Color(0xFF1E252D) : const Color(0xFFF1F5F9);
          }
          if (variant == AppButtonVariant.text) {
            return isDark ? const Color(0x18FFFFFF) : const Color(0x0A000000);
          }
          return backgroundColor.withValues(alpha: 0.92);
        }
        return backgroundColor;
      }),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      elevation: const WidgetStatePropertyAll(0),
      side: WidgetStateProperty.resolveWith((states) {
        if (sideColor == null) return null;
        if (states.contains(WidgetState.hovered) && variant == AppButtonVariant.secondary) {
          return BorderSide(
            color: isDark ? AppColors.borderHighlightDark : AppColors.borderHighlightLight,
            width: 1,
          );
        }
        return BorderSide(color: sideColor, width: 1);
      }),
    );
  }

  Color _getForegroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (variant) {
      case AppButtonVariant.primary:
        return isDark ? const Color(0xFF042F2E) : Colors.white;
      case AppButtonVariant.danger:
        return Colors.white;
      case AppButtonVariant.accent:
        return isDark ? Colors.black : const Color(0xFF5E4500);
      case AppButtonVariant.secondary:
        return isDark ? AppColors.textDark : AppColors.textLight;
      case AppButtonVariant.text:
        return isDark ? AppColors.brandDark : AppColors.brandLight;
      case AppButtonVariant.icon:
        return isDark ? AppColors.textDark : AppColors.textLight;
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
        return AppColors.danger;
      case AppButtonVariant.secondary:
        return isDark ? const Color(0xFF14191F) : Colors.white;
      case AppButtonVariant.text:
        return Colors.transparent;
      case AppButtonVariant.icon:
        return isDark ? const Color(0xFF14191F) : Colors.white;
    }
  }

  Color? _getSideColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (variant) {
      case AppButtonVariant.secondary:
        return isDark ? AppColors.borderDark : AppColors.borderLight;
      case AppButtonVariant.accent:
        return isDark ? AppColors.darkAccent : AppColors.accentColor;
      case AppButtonVariant.danger:
        return isDark ? AppColors.danger.withValues(alpha: 0.8) : null;
      default:
        return null;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case AppButtonSize.md:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 11);
      case AppButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    }
  }

  double _getIconOnlyPadding() {
    switch (size) {
      case AppButtonSize.sm:
        return 7;
      case AppButtonSize.md:
        return 9;
      case AppButtonSize.lg:
        return 12;
    }
  }

  double _getFontSize() {
    switch (size) {
      case AppButtonSize.sm:
        return 12.5;
      case AppButtonSize.md:
        return 13.5;
      case AppButtonSize.lg:
        return 15;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.sm:
        return 15;
      case AppButtonSize.md:
        return 17;
      case AppButtonSize.lg:
        return 20;
    }
  }
}

enum AppButtonVariant { primary, secondary, accent, text, danger, icon }

enum AppButtonSize { sm, md, lg }
