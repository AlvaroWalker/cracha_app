import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/badge_controller.dart';
import '../../models/badge_data.dart';
import '../../services/badge_manager.dart';
import '../../services/remove_bg_service.dart';
import '../../utils/app_snackbar.dart';
import '../../utils/app_tokens.dart';
import '../../views/photo_edit_dialog.dart';

/// Zona de fotografia do editor (etapa 02 — Fotografia).
///
/// Visual Linear-like: 220px de altura no estado vazio, border dashed
/// 1.5, raio 14, ícone câmera 32px em círculo 56px primary 0.1,
/// "Adicionar fotografia" 14/600 e hint 12/muted.
///
/// Estado preenchido: `Image.memory` 220px + chips arredondados
/// (Alterar, Editar, Remover, Remover fundo) com microanimação 200ms,
/// e indicador "Removendo fundo..." inline com `CircularProgressIndicator`
/// de 12px.
///
/// Comportamentos INTACTOS:
/// - `BadgeController.pickImage` (câmera/galeria + crop)
/// - `showPhotoEditDialog` (ajuste fino)
/// - `RemoveBgService.removeBackground` (3 estados: idle / running / done)
/// - `BadgeManager.clearCurrentPhoto`
///
/// Semantics + touch target >= 48px. 0 hex hardcoded — tudo via
/// `ColorScheme`.
class EditorPhotoCard extends StatefulWidget {
  final BadgeData badge;
  final BadgeController? controller;

  const EditorPhotoCard({super.key, required this.badge, this.controller});

  @override
  State<EditorPhotoCard> createState() => _EditorPhotoCardState();
}

class _EditorPhotoCardState extends State<EditorPhotoCard> {
  late BadgeController _localController;
  bool _ownsController = false;
  bool _removingBg = false;

  @override
  void initState() {
    super.initState();
    _localController = widget.controller ?? BadgeController(widget.badge);
    _ownsController = widget.controller == null;
  }

  void _refreshController() {
    if (!_ownsController || !mounted) return;
    final current = context.read<BadgeManager>().currentBadge;
    if (current != null) {
      setState(() => _localController = BadgeController(current));
    }
  }

  Future<void> _pickPhoto() async {
    final bm = context.read<BadgeManager>();
    final bytes = await _localController.pickImage(context);
    if (bytes != null) {
      bm.updateCurrentBadge(photo: bytes);
      _refreshController();
    }
  }

  Future<void> _editPhoto() async {
    final photo = context.read<BadgeManager>().currentBadge?.photo;
    if (photo == null) return;
    final edited = await showPhotoEditDialog(context, photo);
    if (edited != null && mounted) {
      context.read<BadgeManager>().updateCurrentBadge(photo: edited);
      _refreshController();
    }
  }

  void _removePhoto() {
    context.read<BadgeManager>().clearCurrentPhoto();
    _refreshController();
    AppSnackbar.showInfo(context, 'Fotografia removida.');
  }

  Future<void> _removeBackground() async {
    final bm = context.read<BadgeManager>();
    if (bm.currentBadge?.photo == null || _removingBg) return;
    setState(() => _removingBg = true);
    try {
      final cutout =
          await RemoveBgService.removeBackground(bm.currentBadge!.photo!);
      bm.updateCurrentBadge(photo: cutout);
      _refreshController();
      if (mounted) {
        AppSnackbar.showSuccess(context, 'Fundo removido com sucesso!');
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.showError(context, 'Não foi possível remover o fundo.');
      }
    } finally {
      if (mounted) setState(() => _removingBg = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.badge.photo;
    if (photo == null) {
      return _buildEmptyZone(context);
    }
    return _buildFilledZone(context, photo);
  }

  // ---------------------------------------------------------------------------
  // Estado VAZIO — drop zone 220px, dashed, ícone câmera 32px em círculo 56px.
  // ---------------------------------------------------------------------------

  Widget _buildEmptyZone(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final primary = cs.primary;
    final muted = isDark
        ? cs.onSurface.withValues(alpha: 0.6)
        : cs.onSurfaceVariant;
    final title = cs.onSurface;

    // Cor do border (theme) com alpha 0.5.
    final borderColor = isDark
        ? cs.outlineVariant.withValues(alpha: 0.5)
        : cs.outline.withValues(alpha: 0.5);
    // Background: primary com alpha 0.04.
    final bg = primary.withValues(alpha: 0.04);
    // Halo do ícone: primary 0.1.
    final iconHalo = primary.withValues(alpha: 0.1);

    return Semantics(
      button: true,
      label: 'Adicionar fotografia do servidor',
      hint: 'Toque para escolher uma foto',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _pickPhoto,
          borderRadius: BorderRadius.circular(14),
          child: CustomPaint(
            painter: _DashedRRectPainter(
              color: borderColor,
              strokeWidth: 1.5,
              radius: 14,
            ),
            child: Ink(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Círculo 56px + ícone câmera 32px (primary).
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: iconHalo,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.add_a_photo_rounded,
                        size: 32,
                        color: primary,
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    Text(
                      'Adicionar fotografia',
                      style: TextStyle(
                        fontFamily: 'Rawline',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: title,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Solte um arquivo ou clique para escolher. Foto frontal e bem iluminada.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Rawline',
                        fontSize: 12,
                        color: muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Estado PREENCHIDO — foto 220px + chips arredondados.
  // ---------------------------------------------------------------------------

  Widget _buildFilledZone(BuildContext context, Uint8List photo) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Frame da foto: 220px, raio 14, surface container.
        Semantics(
          label: 'Fotografia atual do servidor',
          image: true,
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              color: isDark
                  ? cs.surfaceContainerHighest
                  : cs.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? cs.outlineVariant.withValues(alpha: 0.5)
                    : cs.outlineVariant,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Center(
                child: Image.memory(
                  photo,
                  fit: BoxFit.contain,
                  height: 204,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),

        // Chips arredondados com microanimação 200ms.
        Wrap(
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            _PhotoChip(
              icon: Icons.swap_horiz_rounded,
              label: 'Alterar',
              onTap: _pickPhoto,
              tone: _PhotoChipTone.idle,
            ),
            _PhotoChip(
              icon: Icons.crop_rotate_rounded,
              label: 'Editar',
              onTap: _editPhoto,
              tone: _PhotoChipTone.idle,
            ),
            _PhotoChip(
              icon: Icons.auto_fix_high_rounded,
              label: 'Remover fundo',
              // O estado "running" substitui o chip por um indicador inline.
              tone: _removingBg
                  ? _PhotoChipTone.running
                  : _PhotoChipTone.brand,
              onTap: _removingBg ? null : _removeBackground,
            ),
            _PhotoChip(
              icon: Icons.delete_outline_rounded,
              label: 'Remover',
              onTap: _removePhoto,
              tone: _PhotoChipTone.danger,
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// _PhotoChip — botão tipo "chip" arredondado, microanimação 200ms.
// =============================================================================

enum _PhotoChipTone { idle, brand, danger, running }

class _PhotoChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final _PhotoChipTone tone;

  const _PhotoChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.tone,
  });

  @override
  State<_PhotoChip> createState() => _PhotoChipState();
}

class _PhotoChipState extends State<_PhotoChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final primary = cs.primary;
    final onSurface = cs.onSurface;

    Color bg;
    Color fg;
    Color border;

    switch (widget.tone) {
      case _PhotoChipTone.idle:
        bg = isDark
            ? cs.surfaceContainerHigh
            : cs.surfaceContainerHigh;
        fg = onSurface;
        border = isDark
            ? cs.outlineVariant
            : cs.outlineVariant;
        break;
      case _PhotoChipTone.brand:
        bg = primary.withValues(alpha: isDark ? 0.16 : 0.1);
        fg = primary;
        border = primary.withValues(alpha: 0.4);
        break;
      case _PhotoChipTone.danger:
        bg = cs.error.withValues(alpha: 0.08);
        fg = cs.error;
        border = cs.error.withValues(alpha: 0.35);
        break;
      case _PhotoChipTone.running:
        bg = primary.withValues(alpha: 0.1);
        fg = primary;
        border = primary.withValues(alpha: 0.4);
        break;
    }

    // Hover: leve escurecimento/clareamento — sempre via ColorScheme.
    if (_hover && widget.onTap != null) {
      bg = Color.alphaBlend(
        cs.onSurface.withValues(alpha: isDark ? 0.06 : 0.04),
        bg,
      );
    }

    final enabled = widget.onTap != null;
    final radius = BorderRadius.circular(AppRadius.pill);

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      height: 48, // touch >= 48
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: enabled ? bg : bg.withValues(alpha: 0.5),
        borderRadius: radius,
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // "Removendo fundo..." inline com CircularProgress 12px.
          if (widget.tone == _PhotoChipTone.running) ...[
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.8,
                valueColor: AlwaysStoppedAnimation<Color>(primary),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
          ] else ...[
            Icon(widget.icon, size: 18, color: enabled ? fg : fg.withValues(alpha: 0.5)),
            const SizedBox(width: AppSpace.sm),
          ],
          Text(
            widget.tone == _PhotoChipTone.running
                ? 'Removendo fundo...'
                : widget.label,
            style: TextStyle(
              fontFamily: 'Rawline',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: enabled ? fg : fg.withValues(alpha: 0.5),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Semantics(
        button: true,
        enabled: enabled,
        label: widget.tone == _PhotoChipTone.running
            ? 'Removendo fundo'
            : widget.label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: radius,
            child: child,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _DashedRRectPainter — desenha borda tracejada (Flutter nativo não tem
// BorderStyle.dashed). Cor vem do ColorScheme (sem hex).
// =============================================================================

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double radius;
  static const double _dashLen = 6;
  static const double _gapLen = 4;

  _DashedRRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final m in metrics) {
      double distance = 0;
      while (distance < m.length) {
        final next = distance + _dashLen;
        canvas.drawPath(
          m.extractPath(distance, next > m.length ? m.length : next),
          paint,
        );
        distance = next + _gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) {
    return old.color != color ||
        old.strokeWidth != strokeWidth ||
        old.radius != radius;
  }
}
