import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home/home_page.dart';
import 'home/widgets/account_page.dart';
import 'home/widgets/app_shell.dart';
import 'home/widgets/theme_page.dart';
import 'services/auth_service.dart';
import 'services/badge_manager.dart';
import 'services/theme_notifier.dart';
import 'utils/app_theme.dart';
import 'views/saved_badges_page.dart';
import 'views/tutorial_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await _loadRawlineFonts();
  await Supabase.initialize(
    url: 'https://yppdlqxniiwhnldhhucz.supabase.co',
    publishableKey: 'sb_publishable_nBTqlyVuJGrd9nnu5RJPEg__ohQHCiC',
  );
  final themeNotifier = ThemeNotifier();
  await themeNotifier.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BadgeManager()),
        ChangeNotifierProvider.value(value: themeNotifier),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _loadRawlineFonts() async {
  const weights = [100, 200, 300, 400, 500, 600, 700, 800, 900];
  try {
    final fontLoader = FontLoader('Rawline');
    for (final w in weights) {
      final fontData = await rootBundle.load('assets/rawline/rawline-$w.ttf');
      fontLoader.addFont(Future.value(fontData));
    }
    await fontLoader.load();
  } catch (e) {
    debugPrint('Erro ao carregar fonte Rawline: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (ctx, theme, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Campo Verde — Emissor de Crachás',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: theme.mode,
        home: const AuthGate(child: _BootShell()),
      ),
    );
  }
}

/// Shell bootstrap com navegação real por abas.
///
/// Troca o conteúdo do [AppShell] conforme a rota selecionada na
/// dock/barra inferior. Simples de propósito: sem rotas nomeadas,
/// sem pacotes extras — só `setState`.
class _BootShell extends StatefulWidget {
  const _BootShell();

  @override
  State<_BootShell> createState() => _BootShellState();
}

class _BootShellState extends State<_BootShell> {
  String _route = 'emissor';

  void _go(String route) => setState(() => _route = route);
  void _goEmissor() => setState(() => _route = 'emissor');

  @override
  Widget build(BuildContext context) {
    return AppShell(
      currentRoute: _route,
      onNavigate: _go,
      child: switch (_route) {
        'crachas' => SavedBadgesPage(onBack: _goEmissor),
        'tutorial' => TutorialView(onClose: _goEmissor),
        'tema' => const ThemePage(),
        'conta' => const AccountPage(),
        _ => const HomePage(),
      },
    );
  }
}
