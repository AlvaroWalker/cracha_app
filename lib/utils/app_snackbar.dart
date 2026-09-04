import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Snackbars padronizados do app.
/// Cores adaptam ao tema (mais escuras no modo dark).
class AppSnackbar {
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, _successColor(context), Icons.check_circle_rounded);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, AppColors.errorColor, Icons.error_rounded);
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, _infoColor(context), Icons.info_rounded);
  }

  static void showWarning(BuildContext context, String message) {
    _show(context, message, AppColors.warningColor, Icons.warning_rounded);
  }

  static Color _successColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkPrimary : AppColors.primaryColor;
  }

  static Color _infoColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? AppColors.darkInfoIcon : AppColors.infoIconLight;
  }

  static void _show(BuildContext context, String message, Color bg, IconData icon) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(fontFamily: 'Rawline', color: Colors.white)),
          ),
        ]),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
