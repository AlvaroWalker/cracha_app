import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

/// Temas claro e escuro do app Campo Verde — Emissor de Crachás.
///
/// Diretrizes:
/// - Material 3
/// - Cor de marca verde esmeralda
/// - Botões: filledButton com radius 10, padding 14/20, fonte 14/600
/// - Cards: elevation 0, borda hairline, radius 14
/// - Inputs: filled surface, borda 1, focus 1.5 brand
/// - Divider: cor border 0.5
/// - Fonte Rawline aplicada em todo o textTheme
class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Rawline';

  // ===========================================================================
  // LIGHT
  // ===========================================================================

  static ThemeData get light => _buildTheme(Brightness.light);

  // ===========================================================================
  // DARK
  // ===========================================================================

  static ThemeData get dark => _buildTheme(Brightness.dark);

  // ===========================================================================
  // BUILD
  // ===========================================================================

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final brand = isDark ? AppColors.brandDark : AppColors.brandLight;
    final bg = isDark ? AppColors.bgDark : AppColors.bgLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final text = isDark ? AppColors.textDark : AppColors.textLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: brand,
      onPrimary: isDark ? AppColors.bgDark : Colors.white,
      primaryContainer: brand.withValues(alpha: 0.12),
      onPrimaryContainer: brand,
      secondary: brand,
      onSecondary: isDark ? AppColors.bgDark : Colors.white,
      secondaryContainer: brand.withValues(alpha: 0.10),
      onSecondaryContainer: brand,
      tertiary: AppColors.accentGold,
      onTertiary: isDark ? AppColors.bgDark : Colors.white,
      error: AppColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: text,
      surfaceContainerHighest: isDark
          ? const Color(0xFF1C2329)
          : const Color(0xFFF1F5F9),
      outline: border,
      outlineVariant: border.withValues(alpha: 0.5),
    );

    final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      brightness: brightness,
      colorScheme: colorScheme,
      primaryColor: brand,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      dividerColor: border.withValues(alpha: 0.5),
      dividerTheme: DividerThemeData(
        color: border.withValues(alpha: 0.5),
        thickness: 0.5,
        space: 0.5,
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: border.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: isDark ? AppColors.bgDark : Colors.white,
          disabledBackgroundColor: brand.withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.1,
            letterSpacing: 0,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: isDark ? AppColors.bgDark : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brand,
          side: BorderSide(color: border, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hoverColor: border.withValues(alpha: 0.15),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: muted,
        ),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: muted,
        ),
        prefixIconColor: muted,
        suffixIconColor: muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border.withValues(alpha: 0.5), width: 1),
        ),
      ),
      iconTheme: IconThemeData(color: text, size: 20),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: text,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      textTheme: _buildTextTheme(text, muted),
      primaryTextTheme: _buildTextTheme(
        isDark ? AppColors.bgDark : Colors.white,
        isDark ? Colors.white70 : Colors.white70,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: -0.2,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: brand,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: brand.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: fontFamily,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? brand : muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? brand : muted,
            size: 22,
          );
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: border, width: 0.5),
        ),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: text,
          height: 1.2,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: text,
          height: 1.4,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: text,
        behavior: SnackBarBehavior.floating,
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: isDark ? AppColors.bgDark : Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: text,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: TextStyle(
          fontFamily: fontFamily,
          color: isDark ? AppColors.bgDark : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        waitDuration: const Duration(milliseconds: 400),
      ),
      splashColor: brand.withValues(alpha: 0.08),
      highlightColor: brand.withValues(alpha: 0.04),
    );
  }

  static TextTheme _buildTextTheme(Color text, Color muted) {
    return TextTheme(
      // display
      displayLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 1.05,
        letterSpacing: -0.96,
        color: text,
      ),
      displayMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.1,
        letterSpacing: -0.72,
        color: text,
      ),
      displaySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -0.56,
        color: text,
      ),
      // title
      titleLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.44, // -0.02em
        color: text,
      ),
      titleMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.36, // -0.02em
        color: text,
      ),
      titleSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: -0.30, // -0.02em
        color: text,
      ),
      // body
      bodyLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.45,
        letterSpacing: 0,
        color: text,
      ),
      bodyMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        letterSpacing: 0,
        color: text,
      ),
      bodySmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
        letterSpacing: 0.1,
        color: muted,
      ),
      // label
      labelLarge: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: 0,
        color: text,
      ),
      labelMedium: TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: 0.1,
        color: text,
      ),
      labelSmall: TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.2,
        letterSpacing: 0.2,
        color: muted,
      ),
    );
  }
}
