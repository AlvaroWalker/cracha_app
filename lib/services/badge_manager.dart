import 'package:flutter/foundation.dart';

import '../models/badge_data.dart';
import '../services/badge_storage_service.dart';
import 'badge_cloud_service.dart';
import 'retry_queue.dart';

/// Resultado de uma operação de escrita, honesto sobre onde o dado ficou.
enum SaveOutcome {
  /// Salvo na nuvem (e espelhado no cache local).
  synced,

  /// Salvo só no dispositivo; entrou na fila para subir quando houver rede.
  pendingSync,

  /// Nada foi salvo.
  failed,
}

/// Resultado de exclusão em lote: quantos saíram, quantos ficaram.
class BatchDeleteResult {
  final int deleted;
  final int failed;
  final bool cloudPending;

  const BatchDeleteResult({
    required this.deleted,
    required this.failed,
    this.cloudPending = false,
  });

  bool get allOk => failed == 0;
  String get message {
    if (allOk && !cloudPending) return '$deleted crachás excluídos.';
    if (allOk && cloudPending) {
      return '$deleted crachás excluídos neste dispositivo. '
          'A exclusão será concluída na nuvem quando houver conexão.';
    }
    return '$deleted de ${deleted + failed} crachás excluídos. '
        '$failed falharam — tente novamente.';
  }
}

class BadgeManager extends ChangeNotifier {
  List<BadgeData> _badges = [];
  BadgeData? _currentBadge;
  bool _isLoading = false;
  // Final desde que `selectAllBadges` passou a acumular em vez de reatribuir.
  final Set<String> _selectedBadgeIds = {}; // IDs dos crachás selecionados

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

  /// Quantidade de operações aguardando upload/exclusão na nuvem.
  int _pendingOps = 0;
  int get pendingOps => _pendingOps;

  /// Referência da foto no último save bem-sucedido na nuvem.
  /// Se a foto atual for a MESMA instância, o upload é pulado.
  Uint8List? _lastSavedPhoto;

  /// Guarda de reentrância: Home e a galeria chamam `initBadges()` cada um em
  /// post-frame. Sem esta guarda, os dois bootavam em paralelo e baixavam
  /// todas as fotos duas vezes.
  Future<void>? _initInFlight;

  /// Inicializa e carrega os crachás salvos (nuvem primeiro, local como
  /// fallback). Chamadas concorrentes compartilham a mesma promise.
  Future<void> initBadges() {
    final inFlight = _initInFlight;
    if (inFlight != null) return inFlight;
    final future = _loadBadges();
    _initInFlight = future;
    return future.whenComplete(() => _initInFlight = null);
  }

  Future<void> _loadBadges() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Uma sessão nova sempre começa com um crachá em branco. Se já houver
      // uma edição em andamento (por exemplo, um refresh da galeria), ela
      // não deve ser sobrescrita pelo carregamento da lista.
      _currentBadge ??= BadgeData();

      // Tenta buscar da nuvem (Supabase)
      try {
        _badges = await BadgeCloudService.fetchBadges();
        _cloudAvailable = true;
        // Espelha no local para uso offline
        await BadgeStorageService.replaceAll(_badges);
        // Rede voltou: esvazia a fila de operações pendentes.
        await _drainRetryQueue();
      } catch (e) {
        debugPrint('[BadgeManager] Nuvem indisponível no boot: $e');
        _cloudAvailable = false;
        _badges = await BadgeStorageService.getBadgeList();
      }

      // A lista carregada pertence à galeria. O emissor não seleciona nenhum
      // registro automaticamente: os dados só entram por ação explícita de
      // edição ou duplicação.
      _lastSavedPhoto = _currentBadge?.photo;
    } catch (e) {
      debugPrint('Erro ao inicializar crachás: $e');
      _currentBadge = BadgeData(); // Mantém o fallback
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Esvazia a fila de operações pendentes chamando a nuvem.
  /// Best-effort: falha mantém a fila intacta para a próxima tentativa.
  Future<void> _drainRetryQueue() async {
    // Carrega a fila persistida ANTES de ler `isEmpty`/`ofType`.
    //
    // `RetryQueue.add`/`remove` chamam `init()` sozinhos, mas a leitura é
    // síncrona e não carrega nada. Sem esta linha, `_queue` nasce vazia no
    // boot, o drain retorna cedo e as operações da sessão anterior nunca
    // sobem: o usuário vê "salvo neste dispositivo" e o dado fica preso no
    // local indefinidamente.
    await RetryQueue.init();
    if (RetryQueue.isEmpty) {
      _pendingOps = 0;
      return;
    }
    final saves = RetryQueue.ofType(PendingOpType.saveBadge);
    final deletes = RetryQueue.ofType(PendingOpType.deleteBadge);

    // Exclusões primeiro: um crachá excluído não deve ser recriado por um
    // save enfileirado antes dele.
    for (final op in [...deletes, ...saves]) {
      try {
        if (op.type == PendingOpType.deleteBadge) {
          await BadgeCloudService.deleteBadge(
            BadgeData(id: op.id),
          );
        } else {
          final badge = BadgeData(
            id: op.id,
            name: op.payload['nome'] as String? ?? '',
            role: op.payload['cargo'] as String? ?? '',
            department: op.payload['secretaria'] as String? ?? '',
          );
          await BadgeCloudService.saveBadge(badge);
        }
        await RetryQueue.remove(op.id, type: op.type);
      } catch (e) {
        debugPrint('[BadgeManager] Retry falhou para ${op.id}: $e');
        final exhausted = await RetryQueue.markAttempt(op.id);
        if (exhausted) {
          debugPrint(
              '[BadgeManager]_operation ${op.id} descartada após 3 tentativas.');
        }
        // Para de tentar este lote: a rede ainda está ruim.
        break;
      }
    }
    _pendingOps = RetryQueue.length;
  }

  /// Reprocessa a fila de pendências. Público para a UI oferecer um
  /// "Tentar sincronizar agora".
  Future<void> retryPendingSync() async {
    if (!_cloudAvailable) return;
    _isLoading = true;
    notifyListeners();
    try {
      await _drainRetryQueue();
      _badges = await BadgeCloudService.fetchBadges();
      await BadgeStorageService.replaceAll(_badges);
    } catch (e) {
      debugPrint('[BadgeManager] Retry manual falhou: $e');
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
    bool clearPhoto = false,
  }) {
    // Converte nome e cargo para maiúsculas
    final String? upperName = name?.toUpperCase();
    final String? upperRole = role?.toUpperCase();

    // Se não tiver um crachá atual, cria um novo
    if (_currentBadge == null) {
      _currentBadge = BadgeData(
        name: upperName ?? "",
        role: upperRole ?? "",
        department: department ?? "",
        photo: photo,
      );
    } else {
      // Atualiza o crachá existente
      _currentBadge = _currentBadge!.copyWith(
        name: upperName,
        role: upperRole,
        department: department,
        photo: photo,
        clearPhoto: clearPhoto,
      );
    }
    notifyListeners();
  }

  /// Remove a foto do crachá atual (ação "Remover" da zona de fotografia).
  void clearCurrentPhoto() {
    final current = _currentBadge;
    if (current == null) return;
    _currentBadge = current.copyWith(clearPhoto: true);
    // A foto mudou de instância: o próximo save precisa reenviar/limpar.
    _lastSavedPhoto = null;
    notifyListeners();
  }

  /// Payload mínimo para a fila de retry (sem bytes de foto).
  Map<String, dynamic> _payloadFor(BadgeData badge) => {
        'nome': badge.name,
        'cargo': badge.role,
        'secretaria': badge.department,
      };

  // Salvar ou atualizar o crachá atual
  Future<SaveOutcome> saveCurrentBadge() async {
    final badge = _currentBadge;
    if (badge == null) return SaveOutcome.failed;

    _isLoading = true;
    notifyListeners();

    // Nuvem é a fonte da verdade; local é apenas cache offline.
    // Pula o upload se a foto é a mesma do último save (mesma instância).
    final photoUnchanged = identical(badge.photo, _lastSavedPhoto);
    var cloudError = false;

    if (_cloudAvailable) {
      try {
        await BadgeCloudService.saveBadge(badge,
            skipPhotoUpload: photoUnchanged);
        _lastSavedPhoto = badge.photo;
        await RetryQueue.remove(badge.id, type: PendingOpType.saveBadge);
      } catch (e) {
        debugPrint('[BadgeManager] Erro ao salvar na nuvem: $e');
        cloudError = true;
        // Só enfileira se a falha for transitória. RLS/permissão não melhora
        // com retry — enfileirar seria só spam com 3 tentativas inúteis.
        if (e is CloudUnavailableException) {
          await RetryQueue.add(PendingOperation(
            id: badge.id,
            type: PendingOpType.saveBadge,
            payload: _payloadFor(badge),
            createdAt: DateTime.now(),
          ));
          _pendingOps = RetryQueue.length;
        }
      }
    } else {
      // Sem nuvem: enfileira para subir no próximo boot com rede.
      await RetryQueue.add(PendingOperation(
        id: badge.id,
        type: PendingOpType.saveBadge,
        payload: _payloadFor(badge),
        createdAt: DateTime.now(),
      ));
      _pendingOps = RetryQueue.length;
    }

    // Espelha no local (pode falhar por cota do localStorage sem invalidar
    // o save na nuvem).
    final localOk = await BadgeStorageService.saveBadge(badge);

    if (localOk) {
      _badges = await BadgeStorageService.getBadgeList();
    } else if (_cloudAvailable && !cloudError) {
      // Local falhou (cota): recarrega a lista direto da nuvem
      try {
        _badges = await BadgeCloudService.fetchBadges();
      } catch (_) {}
    }

    // Se a nuvem falhou de verdade, derruba para modo local nesta sessão
    if (cloudError) _cloudAvailable = false;

    _isLoading = false;
    notifyListeners();

    if (_cloudAvailable && !cloudError) return SaveOutcome.synced;
    if (localOk) return SaveOutcome.pendingSync;
    return SaveOutcome.failed;
  }

  // Excluir um crachá pelo ID
  Future<bool> deleteBadge(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      var cloudError = false;
      final badge = _badges.where((b) => b.id == id).firstOrNull;
      if (_cloudAvailable && badge != null) {
        try {
          await BadgeCloudService.deleteBadge(badge);
          await RetryQueue.remove(id, type: PendingOpType.deleteBadge);
        } catch (e) {
          debugPrint('[BadgeManager] Erro ao excluir na nuvem: $e');
          cloudError = true;
          if (e is CloudUnavailableException) {
            await RetryQueue.add(PendingOperation(
              id: id,
              type: PendingOpType.deleteBadge,
              payload: const {},
              createdAt: DateTime.now(),
            ));
            _pendingOps = RetryQueue.length;
          }
        }
      }
      if (cloudError) _cloudAvailable = false;

      final success = await BadgeStorageService.deleteBadge(id);
      if (success) {
        _badges = await BadgeStorageService.getBadgeList();
        _selectedBadgeIds.remove(id);

        // Se o crachá excluído era o atual, define um novo atual
        if (_currentBadge?.id == id) {
          _currentBadge = _badges.isNotEmpty ? _badges.first : BadgeData();
          _lastSavedPhoto = _currentBadge?.photo;
        }
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint('[BadgeManager] Erro ao excluir: $e');
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

  /// Seleciona os crachás atualmente visíveis na lista.
  ///
  /// [visibleBadges] é a lista JÁ filtrada pela tela. Sem este parâmetro o
  /// método seleciona a coleção inteira: com um filtro de secretaria ativo,
  /// "Selecionar Todos" marcava os 17 crachás enquanto a tela mostrava 3 —
  /// e a exclusão em lote apagava exatamente o que o usuário não via.
  ///
  /// Selecionar não desmarca: trocas de filtro preservam a seleção anterior,
  /// permitindo montar um lote atravessando vários filtros.
  void selectAllBadges(List<BadgeData> visibleBadges) {
    // Acumula, não substitui: trocar de filtro preserva a seleção anterior,
    // permitindo montar um lote atravessando vários filtros.
    _selectedBadgeIds.addAll(visibleBadges.map((badge) => badge.id));
    notifyListeners();
  }

  void clearBadgeSelection() {
    _selectedBadgeIds.clear();
    notifyListeners();
  }

  /// Exclui os crachás selecionados, um a um, reportando o quanto deu
  /// certo. Antes isso engole a exceção e a UI mentia "N excluídos" mesmo
  /// com tudo falhado.
  Future<BatchDeleteResult> deleteSelectedBadges() async {
    final ids = Set<String>.from(_selectedBadgeIds);
    if (ids.isEmpty) {
      return const BatchDeleteResult(deleted: 0, failed: 0);
    }

    _isLoading = true;
    notifyListeners();

    var deleted = 0;
    var failed = 0;
    var cloudPending = false;

    for (final id in ids) {
      final badge = _badges.where((b) => b.id == id).firstOrNull;
      if (badge != null && _cloudAvailable) {
        try {
          await BadgeCloudService.deleteBadge(badge);
          await RetryQueue.remove(id, type: PendingOpType.deleteBadge);
        } catch (e) {
          debugPrint('[BadgeManager] Lote: falha na nuvem em $id: $e');
          cloudPending = true;
          if (e is CloudUnavailableException) {
            await RetryQueue.add(PendingOperation(
              id: id,
              type: PendingOpType.deleteBadge,
              payload: const {},
              createdAt: DateTime.now(),
            ));
          }
        }
      } else if (badge != null) {
        // Sem nuvem: garante que a exclusão suba depois.
        await RetryQueue.add(PendingOperation(
          id: id,
          type: PendingOpType.deleteBadge,
          payload: const {},
          createdAt: DateTime.now(),
        ));
        cloudPending = true;
      }

      final localOk = await BadgeStorageService.deleteBadge(id);
      if (localOk) {
        deleted++;
      } else {
        failed++;
      }
    }

    _pendingOps = RetryQueue.length;
    if (cloudPending) _cloudAvailable = false;

    _badges = await BadgeStorageService.getBadgeList();
    _selectedBadgeIds.clear();

    // Se o crachá atual foi excluído, aponta para outro.
    if (ids.contains(_currentBadge?.id)) {
      _currentBadge = _badges.isNotEmpty ? _badges.first : BadgeData();
      _lastSavedPhoto = _currentBadge?.photo;
    }

    _isLoading = false;
    notifyListeners();
    return BatchDeleteResult(
      deleted: deleted,
      failed: failed,
      cloudPending: cloudPending,
    );
  }
}
