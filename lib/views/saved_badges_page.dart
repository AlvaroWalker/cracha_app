import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/badge_data.dart';
import '../services/badge_manager.dart';
import '../utils/app_colors.dart';
import '../utils/multi_badge_pdf_generator.dart';

class SavedBadgesPage extends StatefulWidget {
  const SavedBadgesPage({super.key});

  @override
  State<SavedBadgesPage> createState() => _SavedBadgesPageState();
}

class _SavedBadgesPageState extends State<SavedBadgesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    final badgeManager = Provider.of<BadgeManager>(context, listen: false);
    Future.microtask(() => badgeManager.initBadges());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BadgeData> _filterBadges(List<BadgeData> badges) {
    if (_searchQuery.isEmpty) return badges;
    return badges.where((badge) {
      final nameMatch = badge.name.toLowerCase().contains(_searchQuery);
      final roleMatch = badge.role.toLowerCase().contains(_searchQuery);
      final deptMatch = badge.department.toLowerCase().contains(_searchQuery);
      return nameMatch || roleMatch || deptMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BadgeManager>(
      builder: (context, badgeManager, child) {
        final filteredBadges = _filterBadges(badgeManager.badges);
        final bool isSelecting = badgeManager.selectedBadgeIds.isNotEmpty;

        return Scaffold(
          backgroundColor: AppColors.backgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.primaryColor,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Galeria de Funcionários',
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${badgeManager.badges.length} crachás salvos no total',
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            actions: [
              if (badgeManager.badges.isNotEmpty) ...[
                IconButton(
                  icon: Icon(
                    badgeManager.selectedBadgeIds.length == badgeManager.badges.length
                        ? Icons.select_all_rounded
                        : Icons.deselect_rounded,
                    color: Colors.white,
                  ),
                  tooltip: 'Selecionar Todos',
                  onPressed: () {
                    if (badgeManager.selectedBadgeIds.length == badgeManager.badges.length) {
                      badgeManager.clearBadgeSelection();
                    } else {
                      badgeManager.selectAllBadges();
                    }
                  },
                ),
              ],
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  _buildSearchBarContainer(badgeManager),
                  Expanded(
                    child: _buildGalleryContent(filteredBadges, badgeManager),
                  ),
                  // Espaço para a barra flutuante se houver seleção
                  if (isSelecting) const SizedBox(height: 80),
                ],
              ),
              _buildFloatingActionBar(badgeManager),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBarContainer(BadgeManager badgeManager) {
    return Container(
      color: AppColors.primaryColor,
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(
            fontFamily: 'Rawline',
            color: AppColors.textColor,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Buscar por nome, cargo ou secretaria...',
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryColor),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: AppColors.subtitleColor),
                    onPressed: () => _searchController.clear(),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryContent(List<BadgeData> badges, BadgeManager badgeManager) {
    if (badgeManager.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      );
    }

    if (badgeManager.badges.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  size: 80,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Nenhum crachá cadastrado',
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crie e salve crachás na tela inicial para visualizá-los aqui.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 15,
                  color: AppColors.subtitleColor,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Iniciar Primeiro Crachá', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    }

    if (badges.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, size: 64, color: AppColors.subtitleColor),
              const SizedBox(height: 16),
              const Text(
                'Nenhum resultado encontrado',
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tente reescrever o nome ou termo de busca.',
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 14,
                  color: AppColors.subtitleColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileGallery = screenWidth < 600;

    if (isMobileGallery) {
      // On narrow phones, use a simple list for clean vertical scrolling
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: badges.length,
        itemBuilder: (context, index) {
          final badge = badges[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildBadgeProfileCard(badge, badgeManager),
          );
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 420,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 2.3,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        return _buildBadgeProfileCard(badge, badgeManager);
      },
    );
  }

  Widget _buildBadgeProfileCard(BadgeData badge, BadgeManager badgeManager) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
    final bool isSelected = badgeManager.isBadgeSelected(badge.id);
    final bool hasSelection = badgeManager.selectedBadgeIds.isNotEmpty;

    return Card(
      elevation: isSelected ? 4 : 1.5,
      shadowColor: AppColors.primaryColor.withValues(alpha: 0.15),
      color: isSelected ? AppColors.lightGreen : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? AppColors.primaryColor
              : AppColors.accentColor.withValues(alpha: 0.15),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          if (hasSelection) {
            badgeManager.toggleBadgeSelection(badge.id);
          } else {
            // Seleciona para edição e volta
            badgeManager.setCurrentBadge(badge);
            Navigator.of(context).pop();
          }
        },
        onLongPress: () {
          badgeManager.toggleBadgeSelection(badge.id);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox de seleção (se modo de seleção ativo)
              if (hasSelection) ...[
                Checkbox(
                  value: isSelected,
                  activeColor: AppColors.primaryColor,
                  onChanged: (_) => badgeManager.toggleBadgeSelection(badge.id),
                ),
                const SizedBox(width: 4),
              ],
              
              // Thumbnail Foto
              Container(
                width: 65,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryColor : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: badge.photo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(badge.photo!, fit: BoxFit.cover),
                      )
                    : const Icon(Icons.person_rounded, color: Colors.grey, size: 36),
              ),
              const SizedBox(width: 14),

              // Detalhes do Funcionário
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      badge.name.isEmpty ? 'SEM NOME' : badge.name,
                      style: const TextStyle(
                        fontFamily: 'Rawline',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.work_outline_rounded, size: 13, color: AppColors.subtitleColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            badge.role.isEmpty ? 'Sem Cargo' : badge.role,
                            style: const TextStyle(
                              fontFamily: 'Rawline',
                              fontSize: 13,
                              color: AppColors.subtitleColor,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Pílula da Secretaria
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primaryColor.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        badge.department.isEmpty ? 'Sem Secretaria' : badge.department,
                        style: const TextStyle(
                          fontFamily: 'Rawline',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Atualizado: ${formatter.format(badge.updatedAt)}',
                      style: TextStyle(
                        fontFamily: 'Rawline',
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              // Menu de Ações (só quando não estiver selecionando em lote)
              if (!hasSelection)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, color: AppColors.secondaryColor, size: 20),
                      onPressed: () {
                        badgeManager.setCurrentBadge(badge);
                        Navigator.of(context).pop();
                      },
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      onPressed: () => _confirmDelete(badge),
                      tooltip: 'Excluir',
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BadgeData badge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text('Confirmar Exclusão'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Você está prestes a excluir permanentemente o crachá de:',
              style: TextStyle(fontFamily: 'Rawline', fontSize: 14, color: AppColors.textColor),
            ),
            const SizedBox(height: 12),
            Text(
              badge.name.isEmpty ? 'SEM NOME' : badge.name,
              style: const TextStyle(
                fontFamily: 'Rawline',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.primaryColor,
              ),
            ),
            Text(
              badge.role,
              style: const TextStyle(fontFamily: 'Rawline', fontSize: 14, color: AppColors.subtitleColor),
            ),
            const SizedBox(height: 16),
            const Text(
              'Esta ação é definitiva e não poderá ser desfeita.',
              style: TextStyle(fontFamily: 'Rawline', color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontFamily: 'Rawline', fontWeight: FontWeight.bold, color: AppColors.subtitleColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              final badgeManager = Provider.of<BadgeManager>(context, listen: false);
              await badgeManager.deleteBadge(badge.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Crachá excluído com sucesso!'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            child: const Text('Excluir', style: TextStyle(fontFamily: 'Rawline', color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionBar(BadgeManager badgeManager) {
    final count = badgeManager.selectedBadgeIds.length;
    if (count == 0) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobileBar = screenWidth < 420;

    return Positioned(
      bottom: 16,
      left: 12,
      right: 12,
      child: Card(
        color: AppColors.primaryColor,
        elevation: 10,
        shadowColor: AppColors.primaryColor.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.accentColor, width: 1.5),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobileBar ? 12 : 20,
            vertical: isMobileBar ? 10 : 14,
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$count selecionado(s)',
                    style: TextStyle(
                      fontFamily: 'Rawline',
                      fontSize: isMobileBar ? 13 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Excluir selecionados
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 24),
                    tooltip: 'Excluir Selecionados',
                    onPressed: () => _confirmDeleteSelected(badgeManager),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                  const SizedBox(width: 6),
                  // Imprimir selecionados
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobileBar ? 10 : 16,
                        vertical: isMobileBar ? 8 : 12,
                      ),
                    ),
                    icon: Icon(Icons.picture_as_pdf_rounded, color: AppColors.primaryColor, size: isMobileBar ? 18 : 24),
                    label: Text(
                      'PDF Lote',
                      style: TextStyle(
                        fontFamily: 'Rawline',
                        fontWeight: FontWeight.bold,
                        fontSize: isMobileBar ? 12 : 14,
                      ),
                    ),
                    onPressed: () {
                      final selectedBadges = badgeManager.badges
                          .where((b) => badgeManager.selectedBadgeIds.contains(b.id))
                          .toList();
                      MultiBadgePdfGenerator.generateMultipleBadgesPdf(selectedBadges, context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteSelected(BadgeManager badgeManager) {
    final count = badgeManager.selectedBadgeIds.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
            SizedBox(width: 10),
            Text('Excluir Selecionados'),
          ],
        ),
        content: Text(
          'Deseja realmente excluir todos os $count crachás selecionados permanentemente?\n\nEsta operação não pode ser desfeita.',
          style: const TextStyle(fontFamily: 'Rawline', fontSize: 14, color: AppColors.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontFamily: 'Rawline', fontWeight: FontWeight.bold, color: AppColors.subtitleColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              // Faz a exclusão em lote
              await badgeManager.deleteSelectedBadges();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Crachás selecionados excluídos com sucesso!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              'Confirmar Exclusão',
              style: TextStyle(fontFamily: 'Rawline', color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
