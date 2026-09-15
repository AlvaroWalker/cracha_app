import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_tokens.dart';
import 'app_button.dart';

/// Empty-state moderno da galeria de crachás (Linear / Vercel):
/// - Ilustração minimalista com halo esmeralda sutil
/// - Chamada à ação clara
class SavedBadgesEmptyState extends StatelessWidget {
  final bool hasActiveFilters;
  final bool isDark;
  final VoidCallback onClearFilters;
  final VoidCallback onCreateNew;

  const SavedBadgesEmptyState({
    super.key,
    required this.hasActiveFilters,
    required this.isDark,
    required this.onClearFilters,
    required this.onCreateNew,
  });

  @override
  Widget build(BuildContext context) {
    final brand = isDark ? AppColors.brandDark : AppColors.brandLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: brand.withValues(alpha: isDark ? 0.14 : 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(
                    color: brand.withValues(alpha: isDark ? 0.25 : 0.15),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  hasActiveFilters ? Icons.search_off_rounded : Icons.badge_outlined,
                  size: 36,
                  color: brand,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Text(
                hasActiveFilters ? 'Nenhum crachá encontrado' : 'Nenhum crachá salvo ainda',
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                hasActiveFilters
                    ? 'Tente ajustar ou limpar os filtros de busca aplicados.'
                    : 'Emita seu primeiro crachá funcional no estúdio para gerenciar e imprimir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 13,
                  color: muted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              if (hasActiveFilters)
                AppButton.secondary(
                  label: 'Limpar todos os filtros',
                  icon: Icons.filter_alt_off_rounded,
                  onPressed: onClearFilters,
                )
              else
                AppButton.primary(
                  label: 'Emitir Primeiro Crachá',
                  icon: Icons.add_rounded,
                  onPressed: onCreateNew,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
