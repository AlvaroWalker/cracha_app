import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_tokens.dart';

/// Dropdown com campo de busca no padrão Linear / Vercel:
/// - Trigger no formato idêntico ao AppTextField
/// - Modal suspenso com cantos suaves, borda hairline e busca com filtro instantâneo
class SearchableDropdownField extends StatefulWidget {
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String hintText;
  final IconData? prefixIcon;
  final String? labelText;
  final double maxHeight;

  const SearchableDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.hintText,
    this.prefixIcon,
    this.labelText,
    this.maxHeight = 380,
  });

  @override
  State<SearchableDropdownField> createState() =>
      _SearchableDropdownFieldState();
}

class _SearchableDropdownFieldState extends State<SearchableDropdownField> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openPopup() async {
    _searchController.clear();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _DropdownPopup(
        items: widget.items,
        value: widget.value,
        hintText: widget.hintText,
        maxHeight: widget.maxHeight,
      ),
    );
    if (result == '__clear__') {
      widget.onChanged(null);
    } else if (result != null) {
      widget.onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final fillColor = isDark ? const Color(0xFF0E1317) : Colors.white;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: TextStyle(
              fontFamily: 'Rawline',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openPopup,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                children: [
                  if (widget.prefixIcon != null) ...[
                    Icon(widget.prefixIcon, color: mutedColor, size: 18),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      widget.value ?? widget.hintText,
                      style: TextStyle(
                        fontFamily: 'Rawline',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: widget.value != null ? textColor : mutedColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.unfold_more_rounded,
                    color: mutedColor,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Modal interno do dropdown com campo de busca
class _DropdownPopup extends StatefulWidget {
  final List<String> items;
  final String? value;
  final String hintText;
  final double maxHeight;

  const _DropdownPopup({
    required this.items,
    required this.value,
    required this.hintText,
    required this.maxHeight,
  });

  @override
  State<_DropdownPopup> createState() => _DropdownPopupState();
}

class _DropdownPopupState extends State<_DropdownPopup> {
  final TextEditingController _searchController = TextEditingController();
  late List<String> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
  }

  void _onSearch(String q) {
    setState(() {
      final query = q.trim().toLowerCase();
      _filtered = query.isEmpty
          ? widget.items
          : widget.items.where((e) => e.toLowerCase().contains(query)).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final dialogBg = isDark ? const Color(0xFF12161B) : Colors.white;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 480,
          maxHeight: widget.maxHeight + 100,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header com Título e Fechar
              Row(
                children: [
                  Text(
                    'Selecionar Secretaria',
                    style: TextStyle(
                      fontFamily: 'Rawline',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.pop(context),
                    splashRadius: 16,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Campo de busca com estilo Linear
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearch,
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 13.5,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Filtrar por nome da secretaria...',
                  hintStyle: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 13,
                    color: mutedColor,
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: mutedColor, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF0A0D10) : const Color(0xFFF8FAFC),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Lista filtrada
              Flexible(
                child: _filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Nenhuma secretaria encontrada.',
                          style: TextStyle(
                            fontFamily: 'Rawline',
                            fontSize: 13,
                            color: mutedColor,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 2),
                        itemBuilder: (context, i) {
                          final item = _filtered[i];
                          final isSelected = item == widget.value;

                          return Material(
                            color: isSelected
                                ? primary.withValues(alpha: isDark ? 0.16 : 0.10)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: InkWell(
                              onTap: () => Navigator.pop(context, item),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              hoverColor: isDark
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.black.withValues(alpha: 0.03),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: TextStyle(
                                          fontFamily: 'Rawline',
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected ? primary : textColor,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_rounded,
                                        size: 16,
                                        color: primary,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
