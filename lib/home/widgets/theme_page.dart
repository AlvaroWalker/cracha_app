import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/theme_notifier.dart';

/// Página simples de tema: claro / escuro. Sem enfeite.
class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeNotifier>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Aparência',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Escolha entre tema claro ou escuro. A preferência fica salva.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: RadioGroup<ThemeMode>(
            groupValue: theme.mode,
            onChanged: (m) {
              if (m != null) theme.setMode(m);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                RadioListTile<ThemeMode>(
                  title: Text('Claro'),
                  secondary: Icon(Icons.light_mode_outlined),
                  value: ThemeMode.light,
                ),
                Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: Text('Escuro'),
                  secondary: Icon(Icons.dark_mode_outlined),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
