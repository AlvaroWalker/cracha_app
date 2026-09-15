import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_colors.dart';
import '../utils/app_tokens.dart';
import '../views/app_button.dart';
import '../views/app_text_field.dart';

/// Serviço central de autenticação e cliente Supabase.
/// Login único: alvarowalker@gmail.com (criado no painel).
class AuthService {
  static SupabaseClient get client => Supabase.instance.client;

  static bool get isSignedIn => client.auth.currentSession != null;

  /// Email salvo para pré-preencher o campo ("sistema de usuário").
  static Future<String> getSavedEmail() async {
    // shared_preferences via supabase (session persistente) — usa o próprio package
    try {
      final session = client.auth.currentSession;
      if (session != null) return session.user.email ?? '';
    } catch (_) {}
    return '';
  }

  static Future<AuthResponse> signIn(String email, String password) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signOut() => client.auth.signOut();

  /// Restaura a sessão salva (mantém logado entre visitas).
  static Stream<AuthState> get onAuthStateChange => client.auth.onAuthStateChange;
}

/// Tela de login — bloqueia o app até autenticar.
///
/// Layout: card único centralizado (max 400px), padrão Modern SaaS
/// (Linear no dark / Vercel no light). Lógica de auth intacta.
class LoginView extends StatefulWidget {
  final Widget child;

  const LoginView({super.key, required this.child});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController(text: 'alvarowalker@gmail.com');
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _loading = false;
  bool _obscure = true;
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      await AuthService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      // AuthGate reage via stream; nada a fazer aqui
    } on AuthApiException catch (e) {
      setState(() {
        _erro = e.message.contains('Invalid login')
            ? 'Email ou senha incorretos.'
            : 'Erro ao entrar: ${e.message}';
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _erro = 'Falha de conexão. Verifique sua internet.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        // Linear: brilho sutil no fundo escuro. Light: limpo (Vercel).
        decoration: isDark
            ? BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.4),
                  radius: 1.2,
                  colors: [
                    AppColors.darkPrimary.withValues(alpha: 0.12),
                    theme.scaffoldBackgroundColor,
                  ],
                ),
              )
            : null,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: AppShadow.md(context),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.xxl),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Marca: brasão compacto + nome.
                          Center(
                            child: Semantics(
                              label: 'Brasão do município',
                              child: Container(
                                padding: const EdgeInsets.all(AppSpace.sm),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : AppColors.surfaceSubtleLight,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 1,
                                  ),
                                ),
                                child: Image.asset(
                                  'assets/brasao.png',
                                  height: 48,
                                  errorBuilder: (_, __, ___) {
                                    return Icon(
                                      Icons.account_balance_rounded,
                                      color: isDark
                                          ? AppColors.textDark
                                          : AppColors.textLight,
                                      size: 40,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpace.lg),
                          Text(
                            'CAMPO VERDE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Rawline',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                              color: mutedColor,
                            ),
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            'Emissor de Crachás',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Rawline',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Text(
                            'Acesse sua conta para continuar.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Rawline',
                              fontSize: 13,
                              color: mutedColor,
                            ),
                          ),
                          const SizedBox(height: AppSpace.xl),
                          Semantics(
                            label: 'Campo de e-mail',
                            textField: true,
                            child: AppTextField(
                              controller: _emailController,
                              hintText: 'E-mail',
                              labelText: 'E-mail',
                              prefixIcon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              focusNode: _emailFocus,
                              onSubmitted: (_) =>
                                  _passwordFocus.requestFocus(),
                              validator: (v) =>
                                  (v == null || !v.contains('@'))
                                      ? 'Informe um e-mail válido'
                                      : null,
                            ),
                          ),
                          const SizedBox(height: AppSpace.lg),
                          Semantics(
                            label: 'Campo de senha',
                            textField: true,
                            child: AppTextField(
                              controller: _passwordController,
                              hintText: 'Senha',
                              labelText: 'Senha',
                              prefixIcon: Icons.lock_outline_rounded,
                              obscureText: _obscure,
                              focusNode: _passwordFocus,
                              suffixIcon: _obscure
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              onSuffixTap: () =>
                                  setState(() => _obscure = !_obscure),
                              onSubmitted: (_) => _entrar(),
                              validator: (v) =>
                                  (v == null || v.isEmpty)
                                      ? 'Digite a senha'
                                      : null,
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _erro != null
                                ? Semantics(
                                    key: const ValueKey('login-erro'),
                                    label: 'Erro: ${_erro!}',
                                    liveRegion: true,
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                          top: AppSpace.lg),
                                      padding:
                                          const EdgeInsets.all(AppSpace.md),
                                      decoration: BoxDecoration(
                                        color: AppColors.errorColor.withValues(
                                            alpha: isDark ? 0.14 : 0.08),
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.md),
                                        border: Border.all(
                                          color: AppColors.errorColor
                                              .withValues(alpha: 0.45),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                              Icons.error_outline_rounded,
                                              color: AppColors.errorColor,
                                              size: 20),
                                          const SizedBox(width: AppSpace.sm),
                                          Expanded(
                                            child: Text(
                                              _erro!,
                                              style: TextStyle(
                                                fontFamily: 'Rawline',
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? const Color(0xFFFCA5A5)
                                                    : const Color(0xFFB91C1C),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(
                                    key: ValueKey('login-sem-erro')),
                          ),
                          const SizedBox(height: AppSpace.xl),
                          Semantics(
                            label:
                                _loading ? 'Entrando, aguarde' : 'Botão entrar',
                            button: true,
                            child: _loading
                                ? SizedBox(
                                    height: 48,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: (isDark
                                                ? AppColors.darkPrimary
                                                : AppColors.primaryColor)
                                            .withValues(alpha: 0.85),
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.md),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Colors.white),
                                            ),
                                          ),
                                          SizedBox(width: AppSpace.md),
                                          Text(
                                            'Entrando...',
                                            style: TextStyle(
                                              fontFamily: 'Rawline',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : AppButton.primary(
                                    label: 'Entrar',
                                    icon: Icons.login_rounded,
                                    onPressed: _entrar,
                                    expanded: true,
                                  ),
                          ),
                          const SizedBox(height: AppSpace.lg),
                          Text(
                            'Acesso restrito • Prefeitura de Campo Verde',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Rawline',
                              fontSize: 11,
                              color: mutedColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gate: mostra LoginView enquanto deslogado; o app quando logado.
class AuthGate extends StatefulWidget {
  final Widget child;

  const AuthGate({super.key, required this.child});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final StreamSubscription<AuthState> _sub;
  bool _checked = false;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
    _signedIn = AuthService.isSignedIn;
    _checked = true;
    _sub = AuthService.onAuthStateChange.listen((state) {
      if (!mounted) return;
      setState(() {
        _signedIn = state.session != null;
        _checked = true;
      });
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _signedIn ? widget.child : const LoginView(child: SizedBox.shrink());
  }
}
