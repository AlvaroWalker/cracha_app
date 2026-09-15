import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/badge_manager.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_tokens.dart';
import 'editor_photo_card.dart';
import 'editor_secretaria_field.dart';
import 'editor_servidor_field.dart';

/// Painel esquerdo do editor (padrão Linear / Vercel):
/// - Cabeçalho tipográfico nítido
/// - 3 etapas estruturadas:
///   01 Identificação do Servidor
///   02 Fotografia & Remoção de Fundo
///   03 Lotação & Secretaria
class EditorPanel extends StatelessWidget {
  const EditorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bm = context.watch<BadgeManager>();
    final bd = bm.currentBadge;
    if (bd == null) return const SizedBox.shrink();

    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabeçalho de Introdução
        Padding(
          padding: const EdgeInsets.only(top: AppSpace.sm, bottom: AppSpace.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ficha do Servidor',
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                  letterSpacing: -0.4,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Preencha os dados abaixo. O crachá atualiza instantaneamente ao lado.',
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 13,
                  color: muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        // Grupo 01 — Identificação
        _StepGroupHeader(
          step: '01',
          title: 'Identificação',
          subtitle: 'Nome e cargo registrado no quadro da prefeitura',
          muted: muted,
        ),
        const SizedBox(height: AppSpace.md),
        const EditorServidorField(),

        const SizedBox(height: AppSpace.xxl),

        // Grupo 02 — Fotografia
        _StepGroupHeader(
          step: '02',
          title: 'Fotografia Oficial',
          subtitle: 'Foto 3x4 com enquadramento frontal e fundo neutro',
          muted: muted,
        ),
        const SizedBox(height: AppSpace.md),
        EditorPhotoCard(badge: bd),

        const SizedBox(height: AppSpace.xxl),

        // Grupo 03 — Secretaria
        _StepGroupHeader(
          step: '03',
          title: 'Lotação & Secretaria',
          subtitle: 'Secretaria municipal correspondente',
          muted: muted,
        ),
        const SizedBox(height: AppSpace.md),
        EditorSecretariaField(currentDepartment: bd.department),

        const SizedBox(height: AppSpace.xxxl),
      ],
    );
  }
}

/// Cabeçalho estilizado de etapa com badge numérica estilo Linear
class _StepGroupHeader extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;
  final Color muted;

  const _StepGroupHeader({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final brand = isDark ? AppColors.brandDark : AppColors.brandLight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge Numérica
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: brand.withValues(alpha: isDark ? 0.16 : 0.10),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: brand.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Text(
            step,
            style: TextStyle(
              fontFamily: 'Rawline',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: brand,
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Título e Subtítulo
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 11.5,
                  color: muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
