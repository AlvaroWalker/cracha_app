import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/badge_manager.dart';
import '../../utils/app_tokens.dart';
import 'editor_photo_card.dart';
import 'editor_secretaria_field.dart';
import 'editor_servidor_field.dart';

/// Painel esquerdo do editor, layout Linear-like.
///
/// Três grupos empilhados em Column scroll:
/// 01 Identificação · 02 Fotografia · 03 Secretaria.
class EditorPanel extends StatelessWidget {
  const EditorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Observa o manager para rebuildar quando o crachá muda.
    final bm = context.watch<BadgeManager>();
    final bd = bm.currentBadge;
    if (bd == null) return const SizedBox.shrink();

    // Cor "muted" derivada do tema (fiel ao ColorScheme, sem hex solto).
    final muted = isDark
        ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
        : theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabeçalho
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dados do Funcionário',
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Siga as etapas — o crachá atualiza em tempo real na pré-visualização.',
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 12.5,
                  color: muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        // Grupo 01 — Identificação
        _GroupTitle(label: 'Identificação', muted: muted),
        const SizedBox(height: AppSpace.md),
        const EditorServidorField(),

        const SizedBox(height: AppSpace.xl),

        // Grupo 02 — Fotografia
        _GroupTitle(label: 'Fotografia', muted: muted),
        const SizedBox(height: AppSpace.md),
        EditorPhotoCard(badge: bd),

        const SizedBox(height: AppSpace.xl),

        // Grupo 03 — Secretaria
        _GroupTitle(label: 'Secretaria', muted: muted),
        const SizedBox(height: AppSpace.md),
        EditorSecretariaField(currentDepartment: bd.department),
      ],
    );
  }
}

/// Título de grupo no padrão Linear-like:
/// 12px w700, tracked +0.1em, cor muted.
class _GroupTitle extends StatelessWidget {
  final String label;
  final Color muted;

  const _GroupTitle({required this.label, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: label,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Rawline',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2, // ~0.1em para 12px
          color: muted,
        ),
      ),
    );
  }
}
