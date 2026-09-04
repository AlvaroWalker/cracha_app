import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import '../models/badge_data.dart';
import '../services/badge_form_controller.dart';
import '../services/badge_manager.dart';
import '../utils/app_colors.dart';
import '../utils/app_snackbar.dart';
import '../utils/app_tokens.dart';
import '../utils/pdf_generator.dart';
import '../views/app_button.dart';
import '../views/app_card.dart';
import 'widgets/editor_panel.dart';
import 'widgets/preview_panel.dart';

/// Página principal do app após login: workspace "Emissor" (Linear-like).
///
/// Layout desktop (>=1024): Header + Row(Editor 3 / Preview 4 com Inspector).
/// Layout mobile (<1024):   Header + Column com Editor (preview DENTRO, no topo).
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey _globalKey = GlobalKey();
  final BadgeFormController _form = BadgeFormController();

  @override
  void initState() {
    super.initState();
    // Liga o form ao BadgeManager IMEDIATAMENTE para que os listeners
    // já estejam ativos quando os TextFields forem construídos.
    final bm = Provider.of<BadgeManager>(context, listen: false);
    _form.attach(bm);
    // Inicializa crachás (async, não bloqueia).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      bm.initBadges();
    });
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BadgeFormProvider(
      controller: _form,
      child: _HomeContent(globalKey: _globalKey),
    );
  }
}

/// Conteúdo da HomePage. Precisa estar dentro do BadgeFormProvider.
class _HomeContent extends StatelessWidget {
  final GlobalKey globalKey;
  const _HomeContent({required this.globalKey});

  // ── Ações de ciclo de vida ─────────────────────────────────────────────

  Future<void> _saveCurrent(BuildContext context) async {
    final bm = context.read<BadgeManager>();
    final errors = bm.currentBadge?.validate() ?? [];
    if (errors.isNotEmpty) {
      AppSnackbar.showError(context, errors.first.message);
      return;
    }
    final ok = await bm.saveCurrentBadge();
    if (!context.mounted) return;
    if (ok) {
      AppSnackbar.showSuccess(context, 'Crachá salvo com sucesso!');
    } else {
      AppSnackbar.showError(context, 'Erro ao salvar o crachá.');
    }
  }

  void _newBadge(BuildContext context) {
    context.read<BadgeManager>().createNewBadge();
    context.read<BadgeFormController>().clear();
    AppSnackbar.showInfo(context, 'Novo crachá iniciado!');
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<BadgeManager>(
      builder: (context, bm, _) {
        if (bm.currentBadge == null) {
          return _LoadingSplash();
        }
        return _Workspace(
          globalKey: globalKey,
          onSave: () => _saveCurrent(context),
          onNew: () => _newBadge(context),
        );
      },
    );
  }
}

// ============================================================================
// Splash minimal: CircularProgress 28 brand + 'Carregando crachás' 13/muted
// ============================================================================

class _LoadingSplash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: isDark ? AppColors.brandDark : AppColors.brandLight,
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Text(
              'Carregando crachás',
              style: TextStyle(
                fontFamily: 'Rawline',
                fontSize: 13,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Workspace (header + corpo responsivo)
// ============================================================================

class _Workspace extends StatelessWidget {
  final GlobalKey globalKey;
  final VoidCallback onSave;
  final VoidCallback onNew;

  const _Workspace({
    required this.globalKey,
    required this.onSave,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WorkspaceHeader(onNew: onNew, onSave: onSave),
          Expanded(
            child: LayoutBuilder(
              builder: (context, cons) {
                final isDesktop = cons.maxWidth >= AppBreakpoint.desktop;
                if (isDesktop) {
                  return _DesktopBody(globalKey: globalKey);
                }
                return _MobileBody(globalKey: globalKey);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Header: 'Emissor' 22/700 + subtítulo 13/muted + refresh + more
// ============================================================================

class _WorkspaceHeader extends StatelessWidget {
  final VoidCallback onNew;
  final VoidCallback onSave;

  const _WorkspaceHeader({required this.onNew, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.sm,
        AppSpace.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Emissor',
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Crie e edite crachás institucionais',
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 13,
                    color: muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          AppButton.secondary(
            label: 'Novo',
            icon: Icons.add_rounded,
            onPressed: onNew,
          ),
          const SizedBox(width: 8),
          AppButton.primary(
            label: 'Salvar',
            icon: Icons.save_outlined,
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Desktop: Editor (flex 3, scroll) | Preview (flex 4, sem scroll) + Inspector
// ============================================================================

class _DesktopBody extends StatelessWidget {
  final GlobalKey globalKey;
  const _DesktopBody({required this.globalKey});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Editor (flex 3) com scroll próprio ─────────────────────
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.lg,
              0,
              AppSpace.lg,
              AppSpace.lg,
            ),
            child: const EditorPanel(),
          ),
        ),
        // ── Divisor vertical 1px (Container, não VerticalDivider) ─
        Container(
          width: 1,
          color: theme.dividerColor,
        ),
        // ── Preview (flex 4) sem scroll + Inspector ───────────────
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: PreviewPanel(
              globalKey: globalKey,
              inspector: _InspectorPanel(globalKey: globalKey),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Mobile: Editor com Preview DENTRO no topo
// ============================================================================

class _MobileBody extends StatelessWidget {
  final GlobalKey globalKey;
  const _MobileBody({required this.globalKey});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview no topo (dentro do editor/mobile).
          LayoutBuilder(
            builder: (context, cons) {
              return SizedBox(
                height: 480,
                child: PreviewPanel(globalKey: globalKey),
              );
            },
          ),
          const SizedBox(height: AppSpace.lg),
          // Editor (sem preview, sem inspector).
          const EditorPanel(),
        ],
      ),
    );
  }
}

// ============================================================================
// _InspectorPanel — card Ações + card Status
// ============================================================================

class _InspectorPanel extends StatelessWidget {
  final GlobalKey globalKey;
  const _InspectorPanel({required this.globalKey});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InspectorActionsCard(globalKey: globalKey),
          const SizedBox(height: AppSpace.md),
          const _InspectorStatusCard(),
        ],
      ),
    );
  }
}

// ---------- card Ações ----------------------------------------------------

class _InspectorActionsCard extends StatelessWidget {
  final GlobalKey globalKey;
  const _InspectorActionsCard({required this.globalKey});

  Future<void> _onPdf(BuildContext context) async {
    final bm = context.read<BadgeManager>();
    final bd = bm.currentBadge;
    if (bd == null) return;
    await PdfGenerator.generateAndSharePdf(
      globalKey,
      context,
      badgeData: bd,
    );
  }

  void _onDuplicate(BuildContext context) {
    final bm = context.read<BadgeManager>();
    final bd = bm.currentBadge;
    if (bd == null) return;
    bm.duplicateBadge(bd);
    context.read<BadgeFormController>().clear();
    AppSnackbar.showInfo(context, 'Crachá duplicado. Edite e salve quando quiser.');
  }

  Future<void> _onDelete(BuildContext context) async {
    final bm = context.read<BadgeManager>();
    final bd = bm.currentBadge;
    if (bd == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text(
          'Excluir crachá?',
          style: TextStyle(fontFamily: 'Rawline'),
        ),
        content: Text(
          'Esta ação remove o crachá "${bd.name.isEmpty ? "sem nome" : bd.name}". '
          'Não dá pra desfazer.',
          style: const TextStyle(fontFamily: 'Rawline', fontSize: 13),
        ),
        actions: [
          AppButton.text(
            label: 'Cancelar',
            onPressed: () => Navigator.pop(c, false),
          ),
          AppButton.danger(
            label: 'Excluir',
            onPressed: () => Navigator.pop(c, true),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await bm.deleteBadge(bd.id);
    if (!context.mounted) return;
    if (success) {
      AppSnackbar.showSuccess(context, 'Crachá excluído.');
    } else {
      AppSnackbar.showError(context, 'Erro ao excluir o crachá.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitle(label: 'Ações'),
          const SizedBox(height: AppSpace.sm),
          AppButton.primary(
            label: 'Gerar PDF',
            icon: Icons.picture_as_pdf_rounded,
            expanded: true,
            onPressed: () => _onPdf(context),
          ),
          const SizedBox(height: AppSpace.sm),
          AppButton.secondary(
            label: 'Duplicar',
            icon: Icons.content_copy_rounded,
            expanded: true,
            onPressed: () => _onDuplicate(context),
          ),
          const SizedBox(height: AppSpace.sm),
          AppButton.danger(
            label: 'Excluir',
            icon: Icons.delete_outline_rounded,
            expanded: true,
            onPressed: () => _onDelete(context),
          ),
        ],
      ),
    );
  }
}

// ---------- card Status ---------------------------------------------------

class _InspectorStatusCard extends StatelessWidget {
  const _InspectorStatusCard();

  String _formatLastSave(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'agora mesmo';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    return DateFormat('dd/MM HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final bm = context.watch<BadgeManager>();
    final bd = bm.currentBadge;
    final online = bm.cloudAvailable;
    final count = bm.badges.length;
    final lastSave = bd?.updatedAt;

    return AppCard(
      padding: const EdgeInsets.all(AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _CardTitle(label: 'Status'),
          const SizedBox(height: AppSpace.sm),
          // Chip cloud / local
          Row(
            children: [
              _CloudChip(online: online),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          // Contador de badges
          Row(
            children: [
              Icon(Icons.style_rounded, size: 16, color: muted),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  '$count crachá${count == 1 ? '' : 's'} salvos',
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          // Último save
          Row(
            children: [
              Icon(Icons.history_rounded, size: 16, color: muted),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  lastSave == null
                      ? 'Sem save ainda'
                      : 'Último save: ${_formatLastSave(lastSave)}',
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 12,
                    color: muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------- subwidgets compartilhados -------------------------------------

class _CardTitle extends StatelessWidget {
  final String label;
  const _CardTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Rawline',
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: muted,
      ),
    );
  }
}

class _CloudChip extends StatelessWidget {
  final bool online;
  const _CloudChip({required this.online});

  @override
  Widget build(BuildContext context) {
    final color = online ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            online ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            online ? 'Nuvem' : 'Local',
            style: TextStyle(
              fontFamily: 'Rawline',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
