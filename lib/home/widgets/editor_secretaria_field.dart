import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/department.dart';
import '../../services/badge_manager.dart';
import '../../views/searchable_dropdown_field.dart';

/// Grupo 03 — Secretaria.
///
/// Usa o [SearchableDropdownField] existente (comportamento de busca
/// preservado) com a label "Secretaria" e hint "Busque por secretaria".
class EditorSecretariaField extends StatelessWidget {
  final String currentDepartment;
  const EditorSecretariaField({super.key, required this.currentDepartment});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Secretaria, com pesquisa',
      child: SearchableDropdownField(
        value: currentDepartment,
        items: Department.departments,
        labelText: 'Secretaria',
        hintText: 'Busque por secretaria',
        prefixIcon: Icons.account_balance_outlined,
        onChanged: (v) {
          if (v != null) {
            context.read<BadgeManager>().updateCurrentBadge(department: v);
          }
        },
      ),
    );
  }
}
