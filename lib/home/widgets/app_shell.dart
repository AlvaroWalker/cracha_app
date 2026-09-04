import 'package:flutter/material.dart';

/// Shell simples da aplicação — navegação real, sem enfeite.
///
/// - Desktop (>=1024px): [NavigationRail] lateral + conteúdo.
/// - Mobile (<1024px): [NavigationBar] inferior + conteúdo.
///
/// Contrato (compatível com o uso em `main.dart`):
/// ```dart
/// AppShell(currentRoute: 'emissor', onNavigate: (r) => ..., child: ...)
/// ```
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    this.currentRoute = 'emissor',
    this.search,
    this.actions,
    this.userAvatar,
    this.onNavigate,
  });

  final Widget child;
  final String currentRoute;
  final Widget? search;
  final List<Widget>? actions;
  final Widget? userAvatar;
  final void Function(String route)? onNavigate;

  static const List<_NavItem> _navItems = [
    _NavItem(route: 'emissor', label: 'Emissor', icon: Icons.badge_outlined, activeIcon: Icons.badge_rounded),
    _NavItem(route: 'crachas', label: 'Crachás', icon: Icons.style_outlined, activeIcon: Icons.style_rounded),
    _NavItem(route: 'tutorial', label: 'Tutorial', icon: Icons.help_outline_rounded, activeIcon: Icons.help_rounded),
    _NavItem(route: 'tema', label: 'Tema', icon: Icons.brightness_6_outlined, activeIcon: Icons.brightness_6_rounded),
    _NavItem(route: 'conta', label: 'Conta', icon: Icons.account_circle_outlined, activeIcon: Icons.account_circle_rounded),
  ];

  static int indexFor(String route) {
    final lower = route.toLowerCase();
    for (var i = 0; i < _navItems.length; i++) {
      if (_navItems[i].route == lower) return i;
    }
    return 0;
  }

  void _go(BuildContext context, int index) {
    FocusScope.of(context).unfocus();
    onNavigate?.call(_navItems[index].route);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    if (isDesktop) return _buildDesktop(context);
    return _buildMobile(context);
  }

  Widget _buildDesktop(BuildContext context) {
    final index = indexFor(currentRoute);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (i) => _go(context, i),
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final item in _navItems)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.activeIcon),
                  label: Text(item.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  title: _navItems[index].label,
                  search: search,
                  actions: actions,
                  userAvatar: userAvatar,
                ),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    final index = indexFor(currentRoute);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_navItems[index].label),
        actions: [
          if (actions != null) ...actions!,
          if (userAvatar != null) ...[
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(child: userAvatar!),
            ),
          ],
        ],
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => _go(context, i),
        destinations: [
          for (final item in _navItems)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.activeIcon),
              label: item.label,
            ),
        ],
      ),
    );
  }
}

/// Barra superior simples do desktop: título + busca + ações + avatar.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, this.search, this.actions, this.userAvatar});

  final String title;
  final Widget? search;
  final List<Widget>? actions;
  final Widget? userAvatar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (search != null) ...[
            const SizedBox(width: 16),
            Expanded(child: search!),
          ] else
            const Spacer(),
          if (actions != null) ...actions!,
          if (userAvatar != null) ...[
            const SizedBox(width: 12),
            userAvatar!,
          ],
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.route, required this.label, required this.icon, required this.activeIcon});
  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}
