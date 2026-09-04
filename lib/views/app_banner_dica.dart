import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_tokens.dart';
import 'app_card.dart';

/// Banner de dica/informação usado nos painéis.
/// Adapta cores automaticamente ao tema.
class AppBannerDica extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;
  final Color? textColor;
  final Color? backgroundColor;

  const AppBannerDica({
    super.key,
    this.icon = Icons.info_outline_rounded,
    required this.text,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iColor = iconColor ?? (isDark ? AppColors.darkInfoIcon : AppColors.infoIconLight);
    final tColor = textColor ?? (isDark ? AppColors.darkInfoText : AppColors.infoTextLight);
    final bg = backgroundColor ?? (isDark ? AppColors.darkInfoBg : AppColors.infoBgLight);

    return AppCard(
      color: bg,
      child: Row(children: [
        Icon(icon, size: 18, color: iColor),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontFamily: 'Rawline', fontSize: 12.5, color: tColor),
          ),
        ),
      ]),
    );
  }
}
