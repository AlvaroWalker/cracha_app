import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tipos de operações que podem ser enfileiradas para retry.
enum PendingOpType { saveBadge, deleteBadge }

/// Operação pendente para ser reexecutada quando voltar online.
class PendingOperation {
  final String id;
  final PendingOpType type;
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
        type: PendingOpType.values.firstWhere((e) => e.name == json['type']),
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
        attempts: json['attempts'] as int? ?? 0,
        lastAttempt: json['lastAttempt'] != null ? DateTime.parse(json['lastAttempt'] as String) : null,
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
            validas.add(
                PendingOperation.fromJson(e as Map<String, dynamic>));
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

  static Future<void> add(PendingOperation op) async {
    await init();
    _queue.add(op);
    await _persist();
  }

  static Future<void> remove(String id) async {
    await init();
    _queue.removeWhere((op) => op.id == id);
    await _persist();
  }

  static Future<void> markAttempt(String id) async {
    await init();
    final op = _queue.firstWhere(
      (o) => o.id == id,
      orElse: () => PendingOperation(id: '', type: PendingOpType.saveBadge, payload: {}, createdAt: DateTime.now()),
    );
    if (op.id.isEmpty) return;
    op.attempts++;
    op.lastAttempt = DateTime.now();
    // Remove se excedeu tentativas
    if (op.attempts >= _maxAttempts) {
      _queue.removeWhere((o) => o.id == id);
    }
    await _persist();
  }

  static Future<void> clear() async {
    _queue.clear();
    await _persist();
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(_queue.map((o) => o.toJson()).toList());
      await prefs.setString(_key, json);
    } catch (_) {}
  }
}
