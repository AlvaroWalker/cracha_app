import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/badge_data.dart';
import '../services/badge_manager.dart';
import '../utils/app_colors.dart';
import '../utils/app_snackbar.dart';
import '../utils/app_tokens.dart';
import '../utils/multi_badge_pdf_generator.dart';
import 'app_button.dart';
import 'badge_view.dart';
import 'saved_badges_filter.dart';

/// Galeria e Hub de Gestão de Crachás Emitidos.
///
/// Apresenta interface moderna com estatísticas, busca com debounce, filtros
/// avançados, alternância entre Grade Visual e Tabela Compacta, e ações em lote (PDF e exclusão).
class SavedBadgesPage extends StatefulWidget {
  const SavedBadgesPage({super.key, this.onBack});

  /// Chamado quando o usuário quer voltar ao Emissor.
  /// Se null, usa `Navigator.pop` (comportamento antigo).
  final VoidCallback? onBack;

  @override
  State<SavedBadgesPage> createState() => _SavedBadgesPageState();
}

class _SavedBadgesPageState extends State<SavedBadgesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _secretariaFiltro;
  String _ordenacao = SavedBadgesOptions.ordenacaoPadrao;
  String _periodoData = SavedBadgesOptions.periodoPadrao;
  Timer? _debounce;
  bool _isTableView = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BadgeManager>().initBadges();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
  }

  void _limparFiltros() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _secretariaFiltro = null;
      _ordenacao = SavedBadgesOptions.ordenacaoPadrao;
      _periodoData = SavedBadgesOptions.periodoPadrao;
    });
  }

  bool get _temFiltrosAtivos =>
      _searchQuery.isNotEmpty ||
      _secretariaFiltro != null ||
      _ordenacao != SavedBadgesOptions.ordenacaoPadrao ||
      _periodoData != SavedBadgesOptions.periodoPadrao;

  void _goBack() {
    final onBack = widget.onBack;
    if (onBack != null) {
      onBack();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _voltarParaEdicao(BadgeData badge) {
    context.read<BadgeManager>().setCurrentBadge(badge);
    _goBack();
  }

  void _duplicar(BadgeData badge) {
    context.read<BadgeManager>().duplicateBadge(badge);
    AppSnackbar.showInfo(context, 'Cópia carregada para revisão.');
    _goBack();
  }

  Future<void> _confirmarExclusao(BadgeData badge) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppColors.errorColor, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Excluir Crachá?', style: TextStyle(fontFamily: 'Rawline', fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Deseja excluir o crachá de "${badge.name}"? Esta ação removerá a identificação definitivamente.',
          style: TextStyle(
            fontFamily: 'Rawline',
            color: theme.textTheme.bodyMedium?.color,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          AppButton.text(
            label: 'Cancelar',
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AppButton.danger(
            label: 'Excluir Definitivamente',
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final ok = await context.read<BadgeManager>().deleteBadge(badge.id);
      if (mounted) {
        if (ok) {
          AppSnackbar.showSuccess(context, 'Crachá excluído com sucesso.');
        } else {
          AppSnackbar.showError(context, 'Erro ao excluir crachá.');
        }
      }
    }
  }

  Future<void> _confirmarExclusaoLote(Set<String> selectedIds) async {
    final count = selectedIds.length;
    if (count == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_sweep_rounded, color: AppColors.errorColor, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Exclusão em Lote', style: TextStyle(fontFamily: 'Rawline', fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          'Tem certeza que deseja excluir $count ${count == 1 ? 'crachá selecionado' : 'crachás selecionados'}? Esta ação não pode ser desfeita.',
          style: const TextStyle(fontFamily: 'Rawline', fontSize: 14, height: 1.4),
        ),
        actions: [
          AppButton.text(
            label: 'Cancelar',
            onPressed: () => Navigator.pop(ctx, false),
          ),
          AppButton.danger(
            label: 'Excluir $count ${count == 1 ? 'Crachá' : 'Crachás'}',
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await context.read<BadgeManager>().deleteSelectedBadges();
      if (mounted) {
        AppSnackbar.showSuccess(context, '$count crachás excluídos.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bm = context.watch<BadgeManager>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    final filteredBadges = SavedBadgesFilter.apply(
      bm.badges,
      searchQuery: _searchQuery,
      secretariaFiltro: _secretariaFiltro,
      ordenacao: _ordenacao,
      periodoData: _periodoData,
    );

    final secretariasContagem = SavedBadgesFilter.secretariasComContagem(bm.badges);
    final selectedIds = bm.selectedBadgeIds;
    final hasSelection = selectedIds.isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Biblioteca de Crachás'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Voltar ao Estúdio',
          onPressed: _goBack,
        ),
        actions: [
          IconButton(
            tooltip: _isTableView ? 'Ver em Grade' : 'Ver em Lista / Tabela',
            icon: Icon(_isTableView ? Icons.grid_view_rounded : Icons.view_list_rounded),
            onPressed: () => setState(() => _isTableView = !_isTableView),
          ),
          IconButton(
            tooltip: 'Atualizar Lista',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => bm.initBadges(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Métricas & Estatísticas ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.borderColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildMetricChip(
                  icon: Icons.badge_rounded,
                  label: 'Total',
                  value: '${bm.badges.length}',
                  color: primary,
                  isDark: isDark,
                ),
                const SizedBox(width: AppSpacing.md),
                _buildMetricChip(
                  icon: Icons.account_balance_rounded,
                  label: 'Secretarias',
                  value: '${secretariasContagem.length}',
                  color: isDark ? AppColors.darkAccent : AppColors.accentColor,
                  isDark: isDark,
                ),
                if (hasSelection) ...[
                  const SizedBox(width: AppSpacing.md),
                  _buildMetricChip(
                    icon: Icons.check_circle_rounded,
                    label: 'Selecionados',
                    value: '${selectedIds.length}',
                    color: AppColors.successColor,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),

          // ── Barra de Busca & Filtros ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceSubtle,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.borderColor,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Linha de Busca
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          fontFamily: 'Rawline',
                          fontSize: 14,
                          color: isDark ? AppColors.darkText : AppColors.textColor,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Pesquisar por nome, cargo ou secretaria...',
                          prefixIcon: Icon(Icons.search_rounded, color: primary, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          filled: true,
                          fillColor: isDark ? AppColors.darkSurface : Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primary, width: 1.8),
                          ),
                        ),
                      ),
                    ),
                    if (_temFiltrosAtivos) ...[
                      const SizedBox(width: AppSpacing.sm),
                      AppButton.text(
                        label: 'Limpar',
                        icon: Icons.filter_alt_off_rounded,
                        size: AppButtonSize.sm,
                        onPressed: _limparFiltros,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                // Linha de Filtros (Secretaria, Ordenação, Período)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Filtro Secretaria
                      _buildDropdownFilter<String?>(
                        label: _secretariaFiltro ?? 'Todas as Secretarias',
                        icon: Icons.account_balance_outlined,
                        isActive: _secretariaFiltro != null,
                        isDark: isDark,
                        primary: primary,
                        onTap: () => _showSecretariaPicker(context, secretariasContagem),
                      ),
                      const SizedBox(width: 8),

                      // Filtro Ordenação
                      _buildDropdownFilter<String>(
                        label: 'Ordem: ${SavedBadgesOptions.ordenacaoLabels[_ordenacao]}',
                        icon: Icons.sort_rounded,
                        isActive: _ordenacao != SavedBadgesOptions.ordenacaoPadrao,
                        isDark: isDark,
                        primary: primary,
                        onTap: () => _showOptionsModal(
                          context,
                          title: 'Ordenar por',
                          options: SavedBadgesOptions.ordenacaoLabels,
                          currentValue: _ordenacao,
                          onSelect: (val) => setState(() => _ordenacao = val),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Filtro Período
                      _buildDropdownFilter<String>(
                        label: 'Período: ${SavedBadgesOptions.periodoLabels[_periodoData]}',
                        icon: Icons.date_range_rounded,
                        isActive: _periodoData != SavedBadgesOptions.periodoPadrao,
                        isDark: isDark,
                        primary: primary,
                        onTap: () => _showOptionsModal(
                          context,
                          title: 'Filtrar por data',
                          options: SavedBadgesOptions.periodoLabels,
                          currentValue: _periodoData,
                          onSelect: (val) => setState(() => _periodoData = val),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Barra de Ações em Lote (Fixa quando há seleção) ──
          if (hasSelection)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardElevated : const Color(0xFFE8F5E9),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorderHighlight : AppColors.mediumGreen,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_box_rounded, color: primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${selectedIds.length} selecionado(s)',
                    style: TextStyle(
                      fontFamily: 'Rawline',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.primaryDark,
                    ),
                  ),
                  const Spacer(),
                  // Exportar Selecionados em Lote (PDF)
                  AppButton.primary(
                    label: 'Exportar Lote (PDF)',
                    icon: Icons.picture_as_pdf_rounded,
                    size: AppButtonSize.sm,
                    onPressed: () {
                      final selectedList = bm.selectedBadges;
                      MultiBadgePdfGenerator.generateMultipleBadgesPdf(selectedList, context);
                    },
                  ),
                  const SizedBox(width: 8),
                  // Excluir Selecionados
                  AppButton.danger(
                    label: 'Excluir',
                    icon: Icons.delete_outline_rounded,
                    size: AppButtonSize.sm,
                    onPressed: () => _confirmarExclusaoLote(selectedIds),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Desmarcar todos',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => bm.clearBadgeSelection(),
                  ),
                ],
              ),
            ),

          // ── Lista de Conteúdo (Grade ou Tabela) ──
          Expanded(
            child: bm.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredBadges.isEmpty
                    ? _buildEmptyState(context, isDark)
                    : _isTableView
                        ? _buildTableView(context, filteredBadges, bm)
                        : _buildGridView(context, filteredBadges, bm),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.subtitleColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter<T>({
    required String label,
    required IconData icon,
    required bool isActive,
    required bool isDark,
    required Color primary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? primary.withValues(alpha: isDark ? 0.2 : 0.12)
              : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isActive ? primary : (isDark ? AppColors.darkBorder : AppColors.borderColor),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? primary : (isDark ? AppColors.darkTextSecondary : AppColors.subtitleColor)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Rawline',
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive ? primary : (isDark ? AppColors.darkText : AppColors.textColor),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, size: 18, color: isActive ? primary : AppColors.subtitleColor),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
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
                _temFiltrosAtivos ? Icons.search_off_rounded : Icons.badge_outlined,
                size: 56,
                color: isDark ? AppColors.darkHint : AppColors.subtitleColor,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _temFiltrosAtivos ? 'Nenhum crachá encontrado' : 'Nenhum crachá salvo ainda',
              style: const TextStyle(
                fontFamily: 'Rawline',
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _temFiltrosAtivos
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
            if (_temFiltrosAtivos)
              AppButton.secondary(
                label: 'Limpar todos os filtros',
                icon: Icons.filter_alt_off_rounded,
                onPressed: _limparFiltros,
              )
            else
              AppButton.primary(
                label: 'Criar Novo Crachá',
                icon: Icons.add_rounded,
                onPressed: () {
                  context.read<BadgeManager>().createNewBadge();
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Grade Visual de Crachás ──
  Widget _buildGridView(BuildContext context, List<BadgeData> badges, BadgeManager bm) {
    final sw = MediaQuery.of(context).size.width;
    int crossAxisCount = 1;
    if (sw >= 1400) {
      crossAxisCount = 4;
    } else if (sw >= 1000) {
      crossAxisCount = 3;
    } else if (sw >= 640) {
      crossAxisCount = 2;
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        final isSelected = bm.selectedBadgeIds.contains(badge.id);
        return _BadgeCardGridItem(
          badge: badge,
          isSelected: isSelected,
          onSelectToggle: () => bm.toggleBadgeSelection(badge.id),
          onTap: () => _voltarParaEdicao(badge),
          onDuplicate: () => _duplicar(badge),
          onDelete: () => _confirmarExclusao(badge),
        );
      },
    );
  }

  // ── Tabela Compacta de Crachás ──
  Widget _buildTableView(BuildContext context, List<BadgeData> badges, BadgeManager bm) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: badges.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final badge = badges[index];
        final isSelected = bm.selectedBadgeIds.contains(badge.id);

        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : (isDark ? AppColors.darkBorder : AppColors.borderColor),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isDark ? AppColors.darkShadowList : AppColors.defaultShadow,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: isSelected,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (_) => bm.toggleBadgeSelection(badge.id),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: badge.photo != null
                      ? Image.memory(badge.photo!, width: 40, height: 48, fit: BoxFit.cover)
                      : Container(
                          width: 40,
                          height: 48,
                          color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFE2E8F0),
                          child: const Icon(Icons.person, size: 22, color: Colors.grey),
                        ),
                ),
              ],
            ),
            title: Text(
              badge.name.isEmpty ? 'SEM NOME' : badge.name,
              style: const TextStyle(
                fontFamily: 'Rawline',
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  badge.role.isEmpty ? 'Cargo não informado' : badge.role,
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.subtitleColor,
                  ),
                ),
                Text(
                  badge.department,
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 11,
                    color: isDark ? AppColors.darkHint : AppColors.mutedColor,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => _voltarParaEdicao(badge),
                ),
                IconButton(
                  tooltip: 'Duplicar',
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: () => _duplicar(badge),
                ),
                IconButton(
                  tooltip: 'Excluir',
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.errorColor),
                  onPressed: () => _confirmarExclusao(badge),
                ),
              ],
            ),
            onTap: () => _voltarParaEdicao(badge),
          ),
        );
      },
    );
  }

  // ── Modais de Filtro ──
  void _showSecretariaPicker(BuildContext context, Map<String, int> contagem) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  'Filtrar por Secretaria',
                  style: TextStyle(fontFamily: 'Rawline', fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Todas as Secretarias', style: TextStyle(fontFamily: 'Rawline')),
                selected: _secretariaFiltro == null,
                trailing: _secretariaFiltro == null ? const Icon(Icons.check_rounded) : null,
                onTap: () {
                  setState(() => _secretariaFiltro = null);
                  Navigator.pop(ctx);
                },
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final entry in contagem.entries)
                      ListTile(
                        title: Text(entry.key, style: const TextStyle(fontFamily: 'Rawline', fontSize: 13.5)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${entry.value}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        selected: _secretariaFiltro == entry.key,
                        onTap: () {
                          setState(() => _secretariaFiltro = entry.key);
                          Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showOptionsModal(
    BuildContext context, {
    required String title,
    required Map<String, String> options,
    required String currentValue,
    required ValueChanged<String> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(title, style: const TextStyle(fontFamily: 'Rawline', fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              const Divider(height: 1),
              for (final e in options.entries)
                ListTile(
                  title: Text(e.value, style: const TextStyle(fontFamily: 'Rawline')),
                  selected: e.key == currentValue,
                  trailing: e.key == currentValue ? const Icon(Icons.check_rounded) : null,
                  onTap: () {
                    onSelect(e.key);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Item visual de crachá no Grid.
class _BadgeCardGridItem extends StatelessWidget {
  final BadgeData badge;
  final bool isSelected;
  final VoidCallback onSelectToggle;
  final VoidCallback onTap;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _BadgeCardGridItem({
    required this.badge,
    required this.isSelected,
    required this.onSelectToggle,
    required this.onTap,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(badge.updatedAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? primary
                : (isDark ? AppColors.darkBorder : AppColors.borderColor),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isDark ? AppColors.darkShadowList : AppColors.defaultShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Topo do Card: Seleção + Miniatura
            Expanded(
              child: Stack(
                children: [
                  // Fundo Studio com foto/miniatura
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: isDark
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.darkStudioBackdrop, AppColors.darkSurface],
                            )
                          : LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.studioBackdrop, AppColors.surfaceLight],
                            ),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    ),
                    child: Center(
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AspectRatio(
                          aspectRatio: 54 / 85,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: BadgeView(
                              badgeData: badge,
                              onImageTap: () {},
                              onNameTap: () {},
                              onRoleTap: () {},
                              onDepartmentTap: () {},
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Checkbox de Seleção Rápida
                  Positioned(
                    top: 8,
                    left: 8,
                    child: InkWell(
                      onTap: onSelectToggle,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected ? primary : Colors.white.withValues(alpha: 0.85),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? primary : Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.check,
                          size: 14,
                          color: isSelected ? Colors.white : Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Informações do Servidor
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    badge.name.isEmpty ? 'SEM NOME' : badge.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Rawline',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    badge.role.isEmpty ? 'Cargo não informado' : badge.role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Rawline',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    badge.department,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Rawline',
                      fontSize: 11,
                      color: isDark ? AppColors.darkHint : AppColors.mutedColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontFamily: 'Rawline',
                          fontSize: 10.5,
                          color: isDark ? AppColors.darkHint : AppColors.mutedColor,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            tooltip: 'Duplicar',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            onPressed: onDuplicate,
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.errorColor),
                            tooltip: 'Excluir',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            onPressed: onDelete,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
