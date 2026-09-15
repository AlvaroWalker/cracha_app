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
/// Layout: 2 painéis no desktop (institucional + formulário),
/// vertical compacto no mobile. Lógica de auth intacta.
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
    final isDesktop =
        MediaQuery.of(context).size.width >= AppBreakpoints.desktop;
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        // Command-center: brilho verde sutil no fundo escuro.
        decoration: isDark
            ? BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.4),
                  radius: 1.2,
                  colors: [
                    AppColors.darkPrimary.withValues(alpha: 0.16),
                    theme.scaffoldBackgroundColor,
                  ],
                ),
              )
            : null,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 920 : 440),
              child: isDesktop
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildBrandPanel(context, true)),
                          Expanded(child: _buildFormCard(context)),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildBrandPanel(context, false),
                        _buildFormCard(context),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// Painel institucional (gradiente verde moderno + brasão + crachá vetorial).
  Widget _buildBrandPanel(BuildContext context, bool isDesktop) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: 'Prefeitura de Campo Verde, Emissor de Crachás',
      child: Container(
        padding: const EdgeInsets.all(AppSpace.xxl),
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF064E3B), Color(0xFF022C22)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF047857), Color(0xFF064E3B)],
                ),
          borderRadius: isDesktop
              ? const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.xl))
              : const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.xl)),
          border: Border.all(
            color: isDark ? const Color(0xFF0D5C46) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Semantics(
                  label: 'Brasão do município',
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Image.asset(
                      'assets/brasao.png',
                      height: isDesktop ? 56 : 44,
                      errorBuilder: (_, __, ___) {
                        return const Icon(Icons.account_balance_rounded,
                            color: Colors.white, size: 44);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CAMPO VERDE',
                        style: TextStyle(
                          fontFamily: 'Rawline',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        'Emissor Oficial de Crachás',
                        style: TextStyle(
                          fontFamily: 'Rawline',
                          fontSize: 13,
                          color: Color(0xD9FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            // Representação ABSTRATA de crachá — 100% vetorial, sem PNG.
            Center(
              child: Semantics(
                label: 'Ilustração de um crachá',
                child: _AbstractBadgeArt(compact: !isDesktop),
              ),
            ),
            if (isDesktop) ...[
              const SizedBox(height: AppSpace.xxl),
              _buildBrandItem(context, Icons.badge_rounded,
                  'Busca de servidores integrada à base oficial'),
              const SizedBox(height: AppSpace.md),
              _buildBrandItem(context, Icons.picture_as_pdf_rounded,
                  'Exportação vetorial em PDF pronta para impressão'),
              const SizedBox(height: AppSpace.md),
              _buildBrandItem(
                  context, Icons.cloud_done_rounded, 'Sincronização na nuvem e suporte offline'),
            ] else ...[
              const SizedBox(height: AppSpace.md),
              const Text(
                'Busca integrada • PDF pronto • Nuvem e offline',
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 12,
                  color: Color(0xD9FFFFFF),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBrandItem(BuildContext context, IconData icon, String text) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Rawline',
            fontSize: 13,
            color: Color(0xE6FFFFFF),
          ),
        ),
      ),
    ]);
  }

  /// Card do formulário no padrão Modern SaaS (Linear / Vercel).
  Widget _buildFormCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop =
        MediaQuery.of(context).size.width >= AppBreakpoint.desktop;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF101418) : Colors.white,
        borderRadius: isDesktop
            ? const BorderRadius.horizontal(right: Radius.circular(AppRadius.xl))
            : const BorderRadius.vertical(bottom: Radius.circular(AppRadius.xl)),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: AppShadow.lg(context),
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
                Text(
                  'Acesse sua conta',
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Entre para emitir e gerenciar crachás.',
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 13,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
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
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                    validator: (v) =>
                        (v == null || !v.contains('@')) ? 'Informe um e-mail válido' : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
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
                    onSuffixTap: () => setState(() => _obscure = !_obscure),
                    onSubmitted: (_) => _entrar(),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Digite a senha' : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _erro != null
                      ? Semantics(
                          key: const ValueKey('login-erro'),
                          label: 'Erro: ${_erro!}',
                          liveRegion: true,
                          child: Container(
                            margin: const EdgeInsets.only(
                                top: AppSpacing.sm, bottom: AppSpacing.sm),
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.errorColor
                                  .withValues(alpha: isDark ? 0.14 : 0.08),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: AppColors.errorColor
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    color: AppColors.errorColor, size: 20),
                                const SizedBox(width: AppSpacing.sm),
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
                      : const SizedBox.shrink(key: ValueKey('login-sem-erro')),
                ),
                const SizedBox(height: AppSpacing.lg),
                Semantics(
                  label: _loading ? 'Entrando, aguarde' : 'Botão entrar',
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
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                SizedBox(width: AppSpacing.md),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Crachá abstrato 100% vetorial: cordão + cartão + foto + linhas.
/// Sem nenhum asset PNG novo; usa Container, Gradiente, CustomPaint e ícones.
class _AbstractBadgeArt extends StatelessWidget {
  final bool compact;

  const _AbstractBadgeArt({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final h = compact ? 190.0 : 230.0;
    final w = compact ? 150.0 : 170.0;
    return SizedBox(
      height: h + 44,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Brilho de fundo (vetorial).
          Positioned.fill(
            child: CustomPaint(painter: _BadgeGlowPainter()),
          ),
          // Cordão.
          Positioned(
            top: 0,
            child: CustomPaint(
              size: const Size(72, 44),
              painter: _LanyardPainter(),
            ),
          ),
          // Clipe.
          Positioned(
            top: 38,
            child: Container(
              width: 30,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECEF),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: const Color(0xFF9AA7B2)),
              ),
            ),
          ),
          // Cartão.
          Positioned(
            top: 48,
            child: Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFFFFF), Color(0xFFEAF3EC)],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Faixa superior.
                  Container(
                    height: 34,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F5A29), Color(0xFF1E7A3C)],
                      ),
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppRadius.lg)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_rounded,
                            color: Colors.white, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'CAMPO VERDE',
                          style: TextStyle(
                            fontFamily: 'Rawline',
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Foto abstrata.
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFD7E5DA), Color(0xFFB9D2C0)],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border:
                          Border.all(color: const Color(0xFF0F5A29), width: 2),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Color(0xFF0F5A29), size: 36),
                  ),
                  const SizedBox(height: 8),
                  // Linhas de texto.
                  Container(
                    width: w * 0.62,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: w * 0.44,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3FA562),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Faixa inferior (QR abstrato).
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(
                            4,
                            (i) => Container(
                              width: i.isEven ? 6 : 3,
                              height: 22,
                              margin: const EdgeInsets.only(right: 2),
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const Icon(Icons.verified_rounded,
                            color: Color(0xFF0F5A29), size: 22),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeGlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x55FFFFFF), Color(0x00FFFFFF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.shortestSide * 0.55,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LanyardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xB3FFFFFF)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.15, 0)
      ..quadraticBezierTo(
          size.width / 2, size.height * 1.25, size.width * 0.85, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
