import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Dropdown com campo de busca, ideal para listas longas (ex: secretarias).
/// Popup modal com TextField no topo para filtrar opções.
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
    final textColor = theme.textTheme.bodyLarge?.color;
    final hintColor = isDark ? AppColors.darkHint : AppColors.subtitleColor;
    final primary = theme.colorScheme.primary;
    final fillColor = isDark ? AppColors.darkSurfaceVariant : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : Colors.grey.shade200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Text(
            widget.labelText!,
            style: TextStyle(
              fontFamily: 'Rawline',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openPopup,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  if (widget.prefixIcon != null) ...[
                    Icon(widget.prefixIcon, color: primary, size: 22),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      widget.value ?? widget.hintText,
                      style: TextStyle(
                        fontFamily: 'Rawline',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: widget.value != null ? textColor : hintColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded, color: hintColor),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Popup interno do dropdown com busca.
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
    final textColor = theme.textTheme.bodyLarge?.color;
    final hintColor = isDark ? AppColors.darkHint : AppColors.subtitleColor;
    final fillColor = isDark ? AppColors.darkSurfaceVariant : AppColors.backgroundColor;
    final borderColor = isDark ? AppColors.darkBorder : Colors.grey.shade200;
    final selectedBg = primary.withValues(alpha: isDark ? 0.15 : 0.08);
    final dialogBg = theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight + 120),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Campo de busca
              TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearch,
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 14,
                  color: textColor,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  hintStyle: TextStyle(fontFamily: 'Rawline', color: hintColor),
                  prefixIcon: Icon(Icons.search_rounded, color: primary, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: fillColor,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(color: primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Lista filtrada
              Flexible(
                child: _filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Nenhum resultado encontrado.',
                          style: TextStyle(
                            fontFamily: 'Rawline',
                            color: hintColor,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filtered.length,
                        itemBuilder: (context, i) {
                          final item = _filtered[i];
                          final isSelected = item == widget.value;
                          return ListTile(
                            dense: true,
                            selected: isSelected,
                            selectedTileColor: selectedBg,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            title: Text(
                              item,
                              style: TextStyle(
                                fontFamily: 'Rawline',
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected ? primary : textColor,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_rounded, color: primary, size: 20)
                                : null,
                            onTap: () => Navigator.pop(context, item),
                          );
                        },
                      ),
              ),
              // Botão limpar seleção
              if (widget.value != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context, '__clear__'),
                    icon: const Icon(Icons.clear_rounded, size: 16),
                    label: const Text('Limpar seleção',
                        style: TextStyle(fontFamily: 'Rawline', fontSize: 13)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
