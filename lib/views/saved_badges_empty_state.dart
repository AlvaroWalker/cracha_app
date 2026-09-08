import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_tokens.dart';
import 'app_button.dart';

/// Empty-state da galeria de crachás.
///
/// Extraído de `SavedBadgesPage` (visual idêntico): dois modos —
/// com filtros ativos ("nada encontrado" + limpar) e sem nada salvo
/// ("criar novo"). Navegação sai por callbacks (funciona em aba e em rota).
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceSubtle),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasActiveFilters ? Icons.search_off_rounded : Icons.badge_outlined,
                size: 56,
                color: isDark ? AppColors.darkHint : AppColors.subtitleColor,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              hasActiveFilters ? 'Nenhum crachá encontrado' : 'Nenhum crachá salvo ainda',
              style: const TextStyle(
                fontFamily: 'Rawline',
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hasActiveFilters
                  ? 'Tente ajustar ou limpar os filtros de busca aplicados.'
                  : 'Crie seu primeiro crachá funcional no estúdio para gerenciar e imprimir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Rawline',
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.subtitleColor,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (hasActiveFilters)
              AppButton.secondary(
                label: 'Limpar todos os filtros',
                icon: Icons.filter_alt_off_rounded,
                onPressed: onClearFilters,
              )
            else
              AppButton.primary(
                label: 'Criar Novo Crachá',
                icon: Icons.add_rounded,
                onPressed: onCreateNew,
              ),
          ],
        ),
      ),
    );
  }
}
