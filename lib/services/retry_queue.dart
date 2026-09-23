import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tipos de operações que podem ser enfileiradas para retry.
enum PendingOpType { saveBadge, deleteBadge }

/// Operação pendente, reexecutada quando a conectividade volta.
class PendingOperation {
  final String id;
  final PendingOpType type;

  /// Dados da operação. Para `saveBadge`: id/nome/cargo/secretaria.
  /// Para `deleteBadge`: apenas o id do crachá.
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int attempts;
  DateTime? lastAttempt;

  PendingOperation({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
    this.lastAttempt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
        'lastAttempt': lastAttempt?.toIso8601String(),
      };

  factory PendingOperation.fromJson(Map<String, dynamic> json) => PendingOperation(
        id: json['id'] as String,
        type: PendingOpType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => PendingOpType.saveBadge,
        ),
        payload: Map<String, dynamic>.from(json['payload'] as Map? ?? {}),
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
        lastAttempt: json['lastAttempt'] == null
            ? null
            : DateTime.tryParse(json['lastAttempt'] as String),
      );
}

/// Fila persistente de operações para retry quando voltar online.
class RetryQueue {
  static const String _key = 'pending_operations';
  static const int _maxAttempts = 3;

  static List<PendingOperation> _queue = [];
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List<dynamic>;
        final validas = <PendingOperation>[];
        for (final e in list) {
          // Uma entrada corrompida não pode derrubar a fila inteira.
          try {
            validas.add(PendingOperation.fromJson(e as Map<String, dynamic>));
          } catch (_) {
            // ignora só a entrada inválida
          }
        }
        _queue = validas;
      }
      _initialized = true;
    } catch (_) {
      _queue = [];
      _initialized = true;
    }
  }

  static List<PendingOperation> get pending => List.unmodifiable(_queue);
  static int get length => _queue.length;
  static bool get isEmpty => _queue.isEmpty;
  static bool get isNotEmpty => _queue.isNotEmpty;

  static Future<void> add(PendingOperation op) async {
    await init();
    // Uma operação do mesmo tipo para o mesmo crachá substitui a anterior:
    // enfileirar "salvar A" duas vezes é trabalho duplicado à toa.
    _queue.removeWhere((o) => o.id == op.id && o.type == op.type);
    _queue.add(op);
    await _persist();
  }

  static Future<void> remove(String id, {PendingOpType? type}) async {
    await init();
    _queue.removeWhere((o) => o.id == id && (type == null || o.type == type));
    await _persist();
  }

  /// Marca uma tentativa. Remove da fila ao atingir [_maxAttempts] e devolve
  /// se a operação foi abandonada: retry infinito consome cota do browser e
  /// nunca conserta o que é falha permanente (RLS, 400, quota).
  static Future<bool> markAttempt(String id) async {
    await init();
    PendingOperation? op;
    for (final o in _queue) {
      if (o.id == id) {
        op = o;
        break;
      }
    }
    if (op == null) return false;
    op.attempts++;
    op.lastAttempt = DateTime.now();
    final exhausted = op.attempts >= _maxAttempts;
    if (exhausted) {
      _queue.removeWhere((o) => o.id == id);
    }
    await _persist();
    return exhausted;
  }

  /// Operações de um tipo, na ordem de enfileiramento.
  static List<PendingOperation> ofType(PendingOpType type) =>
      _queue.where((o) => o.type == type).toList();

  static Future<void> clear() async {
    _queue.clear();
    await _persist();
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_queue.map((o) => o.toJson()).toList());
      await prefs.setString(_key, json);
    } catch (_) {
      // Falha de persistência não invalida a operação em memória.
    }
  }

  /// Reseta o estado em memória. Usado só entre testes — em produção a fila
  /// vive no SharedPreferences e morre com o app.
  @visibleForTesting
  static void resetForTest() {
    _queue = [];
    _initialized = false;
  }
}
