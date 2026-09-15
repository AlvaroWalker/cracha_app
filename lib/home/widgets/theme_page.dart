import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/theme_notifier.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_tokens.dart';

/// Página de aparência no padrão Modern SaaS (Linear / Vercel):
/// - Seleção de tema por cartões visuais comparativos (Claro vs Escuro)
/// - Indicação ativa com borda verde esmeralda e checkmark
class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeNotifier>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aparência do Sistema',
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Personalize a experiência visual da aplicação. Sua preferência é persistida automaticamente.',
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 13,
                  color: muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Cartões visuais lado a lado
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 500;
                  final cards = [
                    _ThemeCard(
                      label: 'Tema Claro',
                      description: 'Fundo branco limpo com alto contraste para ambientes iluminados.',
                      icon: Icons.light_mode_rounded,
                      isSelected: theme.mode == ThemeMode.light,
                      isTargetDark: false,
                      onTap: () => theme.setMode(ThemeMode.light),
                    ),
                    const SizedBox(width: 16, height: 16),
                    _ThemeCard(
                      label: 'Tema Escuro',
                      description: 'Superfícies profundas OLED/zinc para redução da fadiga visual.',
                      icon: Icons.dark_mode_rounded,
                      isSelected: theme.mode == ThemeMode.dark,
                      isTargetDark: true,
                      onTap: () => theme.setMode(ThemeMode.dark),
                    ),
                  ];

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: cards[0]),
                        cards[1],
                        Expanded(child: cards[2]),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      cards[0],
                      cards[1],
                      cards[2],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final bool isTargetDark;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.label,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.isTargetDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final brand = isDark ? AppColors.brandDark : AppColors.brandLight;
    final borderColor = isSelected
        ? brand
        : (isDark ? AppColors.borderDark : AppColors.borderLight);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: AppShadow.sm(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview Gráfico da Janela
              Container(
                height: 96,
                decoration: BoxDecoration(
                  color: isTargetDark ? const Color(0xFF090D11) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isTargetDark ? const Color(0xFF222933) : const Color(0xFFCBD5E1),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra superior da janela com bolinhas
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF59E0B),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Esqueleto de interface
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isTargetDark ? const Color(0xFF161B20) : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 8,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isTargetDark ? const Color(0xFF202730) : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                height: 26,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isTargetDark ? const Color(0xFF12161A) : Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: (isTargetDark ? AppColors.brandDark : AppColors.brandLight).withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Título + Checkmark
              Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected ? brand : (isDark ? AppColors.textDark : AppColors.textLight),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Rawline',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: brand,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 12,
                  color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
