import 'package:flutter/foundation.dart';
import '../models/badge_data.dart';
import '../services/badge_storage_service.dart';
import 'badge_cloud_service.dart';

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

  // Estado da última sincronização com a nuvem
  bool _cloudAvailable = true;
  bool get cloudAvailable => _cloudAvailable;

  /// Referência da foto no último save bem-sucedido na nuvem.
  /// Se a foto atual for a MESMA instância, o upload é pulado.
  Uint8List? _lastSavedPhoto;
  // Inicialização - carrega os crachás salvos (nuvem primeiro, local como fallback)
  Future<void> initBadges() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Garantir que sempre teremos um currentBadge válido
      _currentBadge = BadgeData(); // Inicializa com um valor padrão

      // Tenta buscar da nuvem (Supabase)
      try {
        _badges = await BadgeCloudService.fetchBadges();
        _cloudAvailable = true;
        // Espelha no local para uso offline
        await BadgeStorageService.replaceAll(_badges);
      } catch (_) {
        _cloudAvailable = false;
        _badges = await BadgeStorageService.getBadgeList();
      }

      // Se houver crachás na lista, define o mais recente como atual
      if (_badges.isNotEmpty) {
        _currentBadge = _badges.first;
      }
      _lastSavedPhoto = _currentBadge?.photo;
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
    _lastSavedPhoto = badge.photo;
    notifyListeners();
  }

  // Criar um novo crachá
  void createNewBadge() {
    _currentBadge = BadgeData();
    _lastSavedPhoto = null;
    notifyListeners();
  }

  /// Duplica um crachá existente (novo ID, mesmos dados).
  /// Não salva — o usuário revisa e salva quando quiser.
  void duplicateBadge(BadgeData badge) {
    _currentBadge = BadgeData(
      name: badge.name,
      role: badge.role,
      department: badge.department,
      photo: badge.photo,
    );
    _lastSavedPhoto = null; // novo ID => precisa subir a foto
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

  /// Remove a foto do crachá atual (ação "Remover" da zona de fotografia).
  /// Método aditivo — não altera nenhum comportamento existente.
  void clearCurrentPhoto() {
    final current = _currentBadge;
    if (current == null) return;
    _currentBadge = BadgeData(
      id: current.id,
      name: current.name,
      role: current.role,
      department: current.department,
      createdAt: current.createdAt,
    );
    notifyListeners();
  }

  // Salvar ou atualizar o crachá atual
  Future<bool> saveCurrentBadge() async {
    if (_currentBadge == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      String? cloudError;
      if (_cloudAvailable) {
        // Nuvem é a fonte da verdade; local é apenas cache offline.
        // Pula o upload se a foto é a mesma do último save (mesma instância).
        final photoUnchanged =
            identical(_currentBadge!.photo, _lastSavedPhoto);
        try {
          await BadgeCloudService.saveBadge(
            _currentBadge!,
            skipPhotoUpload: photoUnchanged,
          );
          _lastSavedPhoto = _currentBadge!.photo;
        } catch (e) {
          debugPrint('Erro ao salvar na nuvem: $e');
          cloudError = e.toString();
        }
      }

      // Espelha no local (pode falhar por cota do localStorage sem invalidar o save)
      final localOk = await BadgeStorageService.saveBadge(_currentBadge!);

      // Sucesso = nuvem OK (local é opcional) OU sem nuvem e local OK
      final success = _cloudAvailable
          ? (cloudError == null)
          : localOk;

      if (_cloudAvailable && localOk) {
        _badges = await BadgeStorageService.getBadgeList();
      } else if (_cloudAvailable) {
        // Local falhou (cota): recarrega a lista direto da nuvem
        try {
          _badges = await BadgeCloudService.fetchBadges();
        } catch (_) {}
      } else if (localOk) {
        _badges = await BadgeStorageService.getBadgeList();
      }

      // Se a nuvem falhou de verdade, derruba para modo local nesta sessão
      if (cloudError != null) _cloudAvailable = false;

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
      bool success;
      if (_cloudAvailable) {
        final badge = _badges.where((b) => b.id == id).firstOrNull;
        if (badge != null) {
          await BadgeCloudService.deleteBadge(badge);
        }
      }
      success = await BadgeStorageService.deleteBadge(id);

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
      final ids = Set<String>.from(_selectedBadgeIds);
      for (final id in ids) {
        if (_cloudAvailable) {
          final badge = _badges.where((b) => b.id == id).firstOrNull;
          if (badge != null) {
            await BadgeCloudService.deleteBadge(badge);
          }
        }
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
