import 'package:flutter/foundation.dart';
import '../models/badge_data.dart';
import '../services/badge_storage_service.dart';

class BadgeManager extends ChangeNotifier {
  List<BadgeData> _badges = [];
  BadgeData? _currentBadge;
  bool _isLoading = false;
  Set<String> _selectedBadgeIds = {}; // IDs dos crachás selecionados

  // Getters
  List<BadgeData> get badges => _badges;
  BadgeData? get currentBadge => _currentBadge;
  bool get isLoading => _isLoading;
  Set<String> get selectedBadgeIds => _selectedBadgeIds;
  List<BadgeData> get selectedBadges =>
      _badges.where((badge) => _selectedBadgeIds.contains(badge.id)).toList();
  // Inicialização - carrega os crachás salvos
  Future<void> initBadges() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Garantir que sempre teremos um currentBadge válido
      _currentBadge = BadgeData(); // Inicializa com um valor padrão

      _badges = await BadgeStorageService.getBadgeList();

      // Se houver crachás na lista, define o mais recente como atual
      if (_badges.isNotEmpty) {
        _currentBadge = _badges.first;
      }
      // Se a lista estiver vazia, mantém o BadgeData() que já foi criado
    } catch (e) {
      debugPrint('Erro ao inicializar crachás: $e');
      _currentBadge = BadgeData(); // Mantém o fallback
    }

    _isLoading = false;
    notifyListeners();
  }

  // Definir o crachá atual para edição
  void setCurrentBadge(BadgeData badge) {
    _currentBadge = badge;
    notifyListeners();
  }

  // Criar um novo crachá
  void createNewBadge() {
    _currentBadge = BadgeData();
    notifyListeners();
  }

  // Atualizar propriedades do crachá atual
  void updateCurrentBadge({
    String? name,
    String? role,
    String? department,
    Uint8List? photo,
  }) {
    // Converte nome e cargo para maiúsculas
    final String? upperName = name?.toUpperCase();
    final String? upperRole = role?.toUpperCase();

    // Se não tiver um crachá atual, cria um novo
    if (_currentBadge == null) {
      _currentBadge = BadgeData(
        name: upperName ?? "",
        role: upperRole ?? "",
        department: department ?? "SECRETARIA MUNICIPAL DE EDUCAÇÃO",
        photo: photo,
      );
    } else {
      // Atualiza o crachá existente
      _currentBadge = _currentBadge!.copyWith(
        name: upperName,
        role: upperRole,
        department: department,
        photo: photo,
      );
    }
    notifyListeners();
  }

  // Salvar ou atualizar o crachá atual
  Future<bool> saveCurrentBadge() async {
    if (_currentBadge == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await BadgeStorageService.saveBadge(_currentBadge!);
      if (success) {
        // Recarrega a lista para refletir as mudanças
        _badges = await BadgeStorageService.getBadgeList();
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Excluir um crachá pelo ID
  Future<bool> deleteBadge(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await BadgeStorageService.deleteBadge(id);

      if (success) {
        _badges = await BadgeStorageService.getBadgeList();

        // Se o crachá excluído era o atual, define um novo atual
        if (_currentBadge?.id == id) {
          _currentBadge = _badges.isNotEmpty ? _badges.first : BadgeData();
        }
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Métodos para gerenciar a seleção múltipla de crachás
  void toggleBadgeSelection(String badgeId) {
    if (_selectedBadgeIds.contains(badgeId)) {
      _selectedBadgeIds.remove(badgeId);
    } else {
      _selectedBadgeIds.add(badgeId);
    }
    notifyListeners();
  }

  bool isBadgeSelected(String badgeId) {
    return _selectedBadgeIds.contains(badgeId);
  }

  void selectAllBadges() {
    _selectedBadgeIds = _badges.map((badge) => badge.id).toSet();
    notifyListeners();
  }

  void clearBadgeSelection() {
    _selectedBadgeIds.clear();
    notifyListeners();
  }

  // Excluir os crachás selecionados em lote
  Future<void> deleteSelectedBadges() async {
    if (_selectedBadgeIds.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      for (final id in _selectedBadgeIds) {
        await BadgeStorageService.deleteBadge(id);
      }

      _badges = await BadgeStorageService.getBadgeList();

      // Se o crachá atual foi excluído, atualiza o crachá atual
      if (_selectedBadgeIds.contains(_currentBadge?.id)) {
        _currentBadge = _badges.isNotEmpty ? _badges.first : BadgeData();
      }

      _selectedBadgeIds.clear();
    } catch (e) {
      debugPrint('Erro ao excluir crachás em lote: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
