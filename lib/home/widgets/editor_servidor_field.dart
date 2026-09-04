import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/badge_data.dart';
import '../../services/badge_form_controller.dart';
import '../../services/badge_manager.dart';
import '../../utils/app_tokens.dart';
import '../../views/servidor_autocomplete_field.dart';

/// Grupo 01 — Identificação.
///
/// Comportamento de autocomplete preservado: o widget
/// [ServidorAutocompleteField] continua dono do campo e da busca no
/// Supabase. Aqui só envelopamos com o visual "Linear-like":
/// - TextField 16px
/// - label flutuante 12px muted
/// - filled bg surface 0.5
/// - radius 10
/// - focus border 1.5 brand
/// - paddings generosos 16/14
class EditorServidorField extends StatelessWidget {
  const EditorServidorField({super.key});

  @override
  Widget build(BuildContext context) {
    // Observa o manager para rebuildar quando o crachá muda.
    context.watch<BadgeManager>();

    // Pega o BadgeFormController via InheritedNotifier (do HomePage).
    final form = BadgeFormProvider.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Nome — autocomplete de servidor.
        _LargeFilledField(
          label: 'Nome',
          controller: form.nameController,
          focusNode: form.nameFocus,
          hint: 'Digite o nome completo',
          prefixIcon: Icons.person_outline_rounded,
          textCapitalization: TextCapitalization.characters,
          semanticsLabel: 'Nome do funcionário, com busca automática de servidores',
          // Sobrepõe a decoração padrão com o autocomplete existente.
          overrideDecoration: false,
          // O autocomplete envolve o TextField com overlay próprio;
          // passamos o controlador para o componente que cuida da busca.
          builder: (context, controller, focusNode) {
            return ServidorAutocompleteField(
              controller: controller,
              focusNode: focusNode,
              servidores: const [],
              onServidorSelecionado: (s) {
                final m = context.read<BadgeManager>();
                m.updateCurrentBadge(
                  name: s.nome,
                  role: s.cargo,
                  department: s.secretaria,
                );
                form.setFieldsFromBadge(m.currentBadge ?? BadgeData());
              },
            );
          },
        ),
        const SizedBox(height: AppSpace.md),
        // Cargo — TextField grande, mesma linguagem.
        _LargeFilledField(
          label: 'Cargo',
          controller: form.roleController,
          hint: 'Ex: AGENTE ADMINISTRATIVO',
          prefixIcon: Icons.work_outline_rounded,
          textCapitalization: TextCapitalization.characters,
          semanticsLabel: 'Cargo ou função (editável)',
        ),
      ],
    );
  }
}

/// TextField "grande" no estilo Linear-like: 16px, floating label
/// 12px muted, filled bg surface 0.5, radius 10, focus border 1.5 brand,
/// paddings generosos 16/14, touch target >= 48px.
///
/// Suporta um [builder] opcional para casos em que o campo precisa de
/// uma widget customizada (ex: autocomplete com overlay).
class _LargeFilledField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final IconData? prefixIcon;
  final TextCapitalization textCapitalization;
  final String? semanticsLabel;

  /// Quando `true`, ignora a decoração interna e usa o [builder].
  final bool overrideDecoration;

  final Widget Function(
    BuildContext,
    TextEditingController,
    FocusNode?,
  )? builder;

  const _LargeFilledField({
    required this.label,
    required this.controller,
    this.hint,
    this.focusNode,
    this.prefixIcon,
    this.textCapitalization = TextCapitalization.none,
    this.semanticsLabel,
    this.overrideDecoration = false,
    this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cs = theme.colorScheme;
    final primary = cs.primary;
    final onSurfaceMuted = isDark
        ? cs.onSurface.withValues(alpha: 0.6)
        : cs.onSurfaceVariant;

    // bg = surface com alpha 0.5 (visual "filled" sutil).
    final fill = cs.surface.withValues(alpha: 0.5);
    final borderIdle = isDark
        ? cs.outlineVariant.withValues(alpha: 0.6)
        : cs.outlineVariant;

    Widget field;
    if (builder != null) {
      // overrideDecoration: o builder é responsável por toda a UI.
      field = Semantics(
        label: semanticsLabel,
        child: builder!(context, controller, focusNode),
      );
    } else {
      // Decoração "Linear-like".
      final decoration = InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Icon(prefixIcon, size: 20, color: onSurfaceMuted),
              )
            : null,
        prefixIconConstraints:
            const BoxConstraints(minWidth: 48, minHeight: 48),
        filled: true,
        fillColor: fill,
        // Floating label 12px muted.
        labelStyle: TextStyle(
          fontFamily: 'Rawline',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: onSurfaceMuted,
          letterSpacing: 0.2,
        ),
        floatingLabelStyle: TextStyle(
          fontFamily: 'Rawline',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: onSurfaceMuted,
          letterSpacing: 0.2,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        // Hint (placeholder) discreto.
        hintStyle: TextStyle(
          fontFamily: 'Rawline',
          fontSize: 16,
          color: isDark
              ? cs.onSurface.withValues(alpha: 0.35)
              : cs.onSurface.withValues(alpha: 0.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        // Borda padrão 1.2.
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderIdle, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderIdle, width: 1.2),
        ),
        // Foco: 1.5 brand.
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        // Erro silencioso (não usamos validação, mas mantemos o padrão).
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: cs.error, width: 1.5),
        ),
      );

      field = TextField(
        controller: controller,
        focusNode: focusNode,
        textCapitalization: textCapitalization,
        style: TextStyle(
          fontFamily: 'Rawline',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: cs.onSurface,
        ),
        decoration: decoration,
      );
    }

    // Wrap em Semantics (caso o builder não tenha aplicado) e em
    // AnimatedSize para microanimação no focus.
    if (builder != null) {
      return field;
    }
    return Semantics(
      label: semanticsLabel,
      textField: true,
      child: field,
    );
  }
}
