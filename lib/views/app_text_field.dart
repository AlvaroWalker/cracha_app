import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_tokens.dart';

/// TextField padronizado de alta fidelidade visual.
/// Adapta-se automaticamente ao tema claro/escuro.
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? helperText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final int? maxLines;
  final String? Function(String?)? validator;
  final bool autofocus;

  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.maxLines = 1,
    this.validator,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final textColor = theme.textTheme.bodyLarge?.color ?? (isDark ? AppColors.darkText : AppColors.textColor);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.borderColor;
    final disabledColor = isDark ? AppColors.darkSurfaceVariant : const Color(0xFFE2E8F0);
    final fillColor = isDark ? AppColors.darkSurfaceVariant : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: TextStyle(
              fontFamily: 'Rawline',
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          focusNode: focusNode,
          textCapitalization: textCapitalization,
          enabled: enabled,
          maxLines: maxLines,
          validator: validator,
          autofocus: autofocus,
          style: TextStyle(
            fontFamily: 'Rawline',
            fontSize: 14.5,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontFamily: 'Rawline',
              fontSize: 13.5,
              color: isDark ? AppColors.darkHint : AppColors.mutedColor,
            ),
            helperText: helperText,
            helperStyle: TextStyle(
              fontFamily: 'Rawline',
              fontSize: 11.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.subtitleColor,
            ),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: primary, size: 20) : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(suffixIcon, size: 20),
                    onPressed: onSuffixTap,
                    splashRadius: 18,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.subtitleColor,
                  )
                : null,
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: borderColor, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: borderColor, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.errorColor, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.errorColor, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: disabledColor, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
