import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/badge_controller.dart';
import '../../models/badge_data.dart';
import '../../services/badge_manager.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_tokens.dart';
import '../../utils/pdf_generator.dart';
import '../../utils/pdf_vector_generator.dart';
import '../../views/badge_design.dart';

/// Pré-visualização do crachá (Linear-like).
///
/// API mínima:
///   - [globalKey]: a [GlobalKey] que envelopa o [BadgeView] — usada pelo
///     [PdfGenerator] para gerar o PDF. **Nunca** troque esta chave em runtime.
///   - [inspector]: coluna lateral opcional (inspector desktop) renderizada à
///     direita do crachá quando o painel tem espaço.
///
/// O layout é estritamente Column com `mainAxisAlignment: center` e
/// `crossAxisAlignment: stretch`, com `padding 24`. A largura do crachá é
/// calculada por [LayoutBuilder] a partir da altura disponível e presa entre
/// 320 e 560 px. A proporção é fixa 54:85 (mm).
class PreviewPanel extends StatelessWidget {
  final GlobalKey globalKey;
  final Widget? inspector;

  const PreviewPanel({
    super.key,
    required this.globalKey,
    this.inspector,
  });

  @override
  Widget build(BuildContext context) {
    final bm = context.watch<BadgeManager>();
    final bd = bm.currentBadge;
    if (bd == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark
        ? AppColors.mutedDark
        : AppColors.mutedLight;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header mini ────────────────────────────────────────────────
        _PreviewHeader(muted: muted),
        const SizedBox(height: AppSpace.lg),

        // ── Card do crachá (com inspector à direita, se houver) ────────
        Expanded(
          child: _BadgeStage(
            globalKey: globalKey,
            badge: bd,
            inspector: inspector,
            onImageTap: () => _onImageTap(context, bd),
          ),
        ),

        const SizedBox(height: AppSpace.md),

        // ── Legenda dimensional ────────────────────────────────────────
        Text(
          '54 × 85 mm — igual ao impresso',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Rawline',
            fontSize: 11,
            color: muted,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: AppSpace.md),

        // ── Botão Gerar PDF (filled, brand, full-width) ───────────────
        _PdfButton(
          globalKey: globalKey,
          badge: bd,
        ),
      ],
    );
  }

  Future<void> _onImageTap(BuildContext context, BadgeData bd) async {
    final controller = BadgeController(bd);
    final picked = await controller.pickImage(context);
    if (picked != null && context.mounted) {
      context.read<BadgeManager>().updateCurrentBadge(photo: picked);
    }
  }
}

// ============================================================================
// Header mini: 'Pré-visualização' + dot pulsante + legenda
// ============================================================================

class _PreviewHeader extends StatelessWidget {
  final Color muted;

  const _PreviewHeader({required this.muted});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        // Título 16/700
        Text(
          'Pré-visualização',
          style: TextStyle(
            fontFamily: 'Rawline',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: AppSpace.sm),

        // Indicador "ao vivo" estático (sem animação — simples de propósito)
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpace.sm),

        // Legenda 12/muted
        Flexible(
          child: Text(
            'Atualizado em tempo real',
            style: TextStyle(
              fontFamily: 'Rawline',
              fontSize: 12,
              color: muted,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Palco do crachá: grid sutil + sombra dupla + AspectRatio 54/85 + inspector
// ============================================================================

class _BadgeStage extends StatelessWidget {
  final GlobalKey globalKey;
  final BadgeData badge;
  final Widget? inspector;
  final VoidCallback onImageTap;

  const _BadgeStage({
    required this.globalKey,
    required this.badge,
    required this.onImageTap,
    this.inspector,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Sombra dupla com tons derivados do tema — sem hex hardcoded.
    final shadowColor = theme.colorScheme.shadow
        .withValues(alpha: isDark ? 0.50 : 0.12);
    final badgeShadow = <BoxShadow>[
      BoxShadow(
        color: shadowColor.withValues(alpha: isDark ? 0.28 : 0.10),
        blurRadius: 20,
        offset: const Offset(0, 5),
      ),
      BoxShadow(
        color: shadowColor.withValues(alpha: isDark ? 0.40 : 0.18),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ];

    return LayoutBuilder(
      builder: (context, cons) {
        // Largura disponível do palco (desconta o inspector no desktop).
        final maxW = cons.maxWidth.isFinite ? cons.maxWidth : 600.0;
        final stageW = inspector != null
            ? (maxW - AppSpace.lg - 320).clamp(160.0, double.infinity)
            : maxW;
        // Palco sagrado (badge_design.dart): captura via GlobalKey + FittedBox.
        // Não reinventar aqui — qualquer ajuste de geometria vai no kit.
        final body = _BadgeFrame(
          shadow: badgeShadow,
          child: buildBadgeStage(
            globalKey: globalKey,
            badge: badge,
            boxWidth: stageW,
            onImageTap: onImageTap,
          ),
        );

        if (inspector == null) {
          return Center(child: body);
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(child: body),
            ),
            const SizedBox(width: AppSpace.lg),
            SizedBox(width: 320, child: inspector),
          ],
        );
      },
    );
  }
}

// ============================================================================
// Quadro: fundo quadriculado sutil + sombra dupla envolvendo o crachá
// ============================================================================

class _BadgeFrame extends StatelessWidget {
  final List<BoxShadow> shadow;
  final Widget child;

  const _BadgeFrame({
    required this.shadow,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gridColor =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: CustomPaint(
          painter: _GridPainter(
            color: gridColor,
            cellSize: 8,
          ),
          child: child,
        ),
      ),
    );
  }
}

// ============================================================================
// CustomPainter — grid 8px sutil para o fundo do palco
// ============================================================================

class _GridPainter extends CustomPainter {
  final Color color;
  final double cellSize;

  _GridPainter({required this.color, required this.cellSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Linhas verticais
    for (double x = 0; x <= size.width; x += cellSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Linhas horizontais
    for (double y = 0; y <= size.height; y += cellSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.color != color || old.cellSize != cellSize;
}

// ============================================================================
// Botão Gerar PDF — filled brand, radius 10, full-width
// ============================================================================

class _PdfButton extends StatelessWidget {
  final GlobalKey globalKey;
  final BadgeData badge;

  const _PdfButton({required this.globalKey, required this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final brand = isDark ? AppColors.brandDark : AppColors.brandLight;
    final onBrand = isDark ? AppColors.textDark : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: Material(
            color: brand,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () => PdfGenerator.generateAndSharePdf(
                globalKey,
                context,
                badgeData: badge,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, size: 18, color: onBrand),
                    const SizedBox(width: AppSpace.sm),
                    Text(
                      'Gerar PDF',
                      style: TextStyle(
                        fontFamily: 'Rawline',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: onBrand,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // TESTE (branch teste-pdf-vetorizado): PDF vetorial lado a lado.
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => PdfVectorGenerator.generateAndSharePdf(
            context,
            badgeData: badge,
          ),
          icon: const Icon(Icons.description_outlined, size: 18),
          label: const Text('PDF Vetor (TESTE)'),
        ),
      ],
    );
  }
}
