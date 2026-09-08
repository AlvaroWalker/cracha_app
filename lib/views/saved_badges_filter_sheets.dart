import 'package:flutter/material.dart';

import '../utils/app_tokens.dart';

/// Bottom-sheets de filtro da galeria (visual idêntico ao original).
///
/// Extraído de `SavedBadgesPage`: seleção sai por callbacks e o sheet
/// fecha sozinho — sem `setState` vazando pra fora.
class SavedBadgesSheets {
  /// Seletor de secretaria com contagem por item.
  static Future<void> showSecretariaPicker(
    BuildContext context, {
    required Map<String, int> contagem,
    required String? selecionada,
    required ValueChanged<String?> onSelect,
  }) {
    return showModalBottomSheet(
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
                selected: selecionada == null,
                trailing: selecionada == null ? const Icon(Icons.check_rounded) : null,
                onTap: () {
                  onSelect(null);
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
                        selected: selecionada == entry.key,
                        onTap: () {
                          onSelect(entry.key);
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

  /// Seletor genérico (ordenação, período).
  static Future<void> showOptionsModal(
    BuildContext context, {
    required String title,
    required Map<String, String> options,
    required String currentValue,
    required ValueChanged<String> onSelect,
  }) {
    return showModalBottomSheet(
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
