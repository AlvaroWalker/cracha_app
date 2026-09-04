import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

/// Listener de mudanças de autenticação do Supabase.
/// Detecta token expirado/erro 401 e força logout automático.
class AuthInterceptor {
  static GoTrueClient? _client;
  static bool _initialized = false;

  /// Inicializa o listener de auth.
  static void init() {
    if (_initialized) return;
    _initialized = true;
    _client = Supabase.instance.client.auth;
    _client!.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        // Já foi deslogado manualmente
        return;
      }
      if (event == AuthChangeEvent.tokenRefreshed) {
        return;
      }
    });
  }

  /// Verifica se a sessão atual ainda é válida.
  /// Retorna false se token expirou.
  static bool hasValidSession() {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return false;
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return true;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return expiresAt > now;
  }

  /// Força logout quando token é inválido.
  static Future<void> forceLogout() async {
    await AuthService.signOut();
  }

  /// Hook para ser chamado em erros 401 das requisições.
  /// Retorna true se a sessão foi recuperada (false = precisa relogar).
  static Future<bool> handleAuthError(Object error) async {
    final errorStr = error.toString().toLowerCase();
    final is401 = errorStr.contains('401') ||
        errorStr.contains('unauthorized') ||
        errorStr.contains('jwt') ||
        errorStr.contains('invalid token') ||
        errorStr.contains('token expired');
    if (!is401) return false;

    // Tenta refresh automático
    try {
      final response = await Supabase.instance.client.auth.refreshSession();
      return response.session != null;
    } catch (_) {
      await forceLogout();
      return false;
    }
  }
}
