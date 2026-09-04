import 'package:flutter/material.dart';

import '../models/badge_data.dart';
import 'badge_manager.dart';
import 'servidor_repository.dart';

/// Gerencia o estado do formulário (text controllers + sincronização com BadgeManager).
///
/// **Fluxo de dados:**
/// - Usuário digita no campo → controller notifica → `updateCurrentBadge` no manager → preview rebuilda
/// - Usuário seleciona servidor no autocomplete → `applyServidor` → manager + controllers atualizam
/// - Usuário clica em "Novo" → `clear()` → controllers vazios + manager reset
class BadgeFormController extends ChangeNotifier {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final FocusNode nameFocus = FocusNode();

  BadgeManager? _manager;
  List<Servidor> _servidores = [];
  List<Servidor> get servidores => _servidores;
  bool _suprimirListeners = false;
  bool _attached = false;

  void setServidores(List<Servidor> list) {
    _servidores = list;
    notifyListeners();
  }

  /// Liga o controller ao BadgeManager.
  /// Após attach, qualquer mudança nos TextEditingControllers
  /// é propagada para o manager e vice-versa.
  void attach(BadgeManager manager) {
    if (_attached && _manager == manager) return;
    _manager = manager;
    _attached = true;
    nameController.addListener(_onNameChanged);
    roleController.addListener(_onRoleChanged);
    // Escuta mudanças no manager para sincronizar campos
    // (ex: quando currentBadge é criado pelo initBadges,
    // ou quando um crachá é carregado da galeria).
    manager.addListener(_onManagerChanged);
    _syncFromManager();
  }

  void _onManagerChanged() {
    final m = _manager;
    if (m == null) return;
    final bd = m.currentBadge;
    if (bd == null) return;
    // Sincroniza controllers com o badge atual (sem disparar listeners)
    if (nameController.text != bd.name || roleController.text != bd.role) {
      setFieldsFromBadge(bd);
    }
  }

  /// Chamado a cada keystroke no campo nome.
  void _onNameChanged() {
    if (_suprimirListeners) return;
    final m = _manager;
    if (m?.currentBadge == null) return;
    final text = nameController.text;
    if (m!.currentBadge!.name != text) {
      m.updateCurrentBadge(name: text.toUpperCase());
    }
  }

  /// Chamado a cada keystroke no campo cargo.
  void _onRoleChanged() {
    if (_suprimirListeners) return;
    final m = _manager;
    if (m?.currentBadge == null) return;
    final text = roleController.text;
    if (m!.currentBadge!.role != text) {
      m.updateCurrentBadge(role: text.toUpperCase());
    }
  }

  void _syncFromManager() {
    final m = _manager;
    if (m?.currentBadge == null) return;
    final bd = m!.currentBadge!;
    setFieldsFromBadge(bd);
  }

  /// Atualiza os controllers a partir de um BadgeData.
  /// Suprime listeners para evitar loops.
  void setFieldsFromBadge(BadgeData bd) {
    _suprimirListeners = true;
    try {
      if (nameController.text != bd.name) {
        nameController.value = TextEditingValue(
          text: bd.name,
          selection: TextSelection.collapsed(offset: bd.name.length),
        );
      }
      if (roleController.text != bd.role) {
        roleController.value = TextEditingValue(
          text: bd.role,
          selection: TextSelection.collapsed(offset: bd.role.length),
        );
      }
    } finally {
      _suprimirListeners = false;
    }
  }

  /// Aplica um servidor selecionado a partir do autocomplete.
  void applyServidor(Servidor s) {
    final m = _manager;
    if (m == null) return;
    m.updateCurrentBadge(
      name: s.nome,
      role: s.cargo,
      department: s.secretaria,
    );
    setFieldsFromBadge(BadgeData(name: s.nome, role: s.cargo, department: s.secretaria));
  }

  void clear() {
    nameController.clear();
    roleController.clear();
  }

  @override
  void dispose() {
    _manager?.removeListener(_onManagerChanged);
    nameController.dispose();
    roleController.dispose();
    nameFocus.dispose();
    super.dispose();
  }
}

/// Provider para acessar o BadgeFormController.
class BadgeFormProvider extends InheritedNotifier<BadgeFormController> {
  const BadgeFormProvider({super.key, required BadgeFormController controller, required super.child})
      : super(notifier: controller);

  static BadgeFormController of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<BadgeFormProvider>();
    assert(provider != null, 'BadgeFormProvider not found in context');
    return provider!.notifier!;
  }
}
