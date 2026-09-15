import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/badge_manager.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_tokens.dart';

/// Shell da aplicação no padrão Modern SaaS (Linear / Vercel):
/// - Desktop (>=1024px): Sidebar lateral customizada de 240px com header
///   institucional, itens de navegação em pílula, status da nuvem e perfil.
/// - Mobile (<1024px): Dock inferior elegante com borda hairline e navegação limpa.
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
    _NavItem(
      route: 'emissor',
      label: 'Emissor',
      icon: Icons.badge_outlined,
      activeIcon: Icons.badge_rounded,
      shortcut: '⌘1',
    ),
    _NavItem(
      route: 'crachas',
      label: 'Crachás Salvos',
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      shortcut: '⌘2',
    ),
    _NavItem(
      route: 'tutorial',
      label: 'Tutorial',
      icon: Icons.help_outline_rounded,
      activeIcon: Icons.help_rounded,
      shortcut: '⌘3',
    ),
    _NavItem(
      route: 'tema',
      label: 'Aparência',
      icon: Icons.palette_outlined,
      activeIcon: Icons.palette_rounded,
      shortcut: '⌘4',
    ),
    _NavItem(
      route: 'conta',
      label: 'Conta & Sessão',
      icon: Icons.account_circle_outlined,
      activeIcon: Icons.account_circle_rounded,
      shortcut: '⌘5',
    ),
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
    final isDesktop = MediaQuery.sizeOf(context).width >= AppBreakpoint.desktop;
    if (isDesktop) return _buildDesktop(context);
    return _buildMobile(context);
  }

  Widget _buildDesktop(BuildContext context) {
    final index = indexFor(currentRoute);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          // ── Sidebar Linear / Vercel (240px) ─────────────────────────
          _DesktopSidebar(
            currentIndex: index,
            navItems: _navItems,
            onSelect: (i) => _go(context, i),
          ),

          // ── Separador Vertical Hairline ─────────────────────────────
          Container(
            width: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          // ── Conteúdo Principal + TopBar ─────────────────────────────
          Expanded(
            child: Column(
              children: [
                _TopBar(
                  routeLabel: _navItems[index].label,
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
    final isDark = theme.brightness == Brightness.dark;
    final brand = isDark ? AppColors.brandDark : AppColors.brandLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Image.asset(
              'assets/brasao.png',
              height: 24,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.account_balance_rounded, size: 22, color: brand),
            ),
            const SizedBox(width: 10),
            Text(
              _navItems[index].label,
              style: TextStyle(
                fontFamily: 'Rawline',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textDark : AppColors.textLight,
              ),
            ),
          ],
        ),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                for (var i = 0; i < _navItems.length; i++) ...[
                  Expanded(
                    child: _MobileNavItem(
                      item: _navItems[i],
                      isSelected: i == index,
                      onTap: () => _go(context, i),
                      brandColor: brand,
                      mutedColor: muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Sidebar Desktop (Linear-like 240px)
// ============================================================================

class _DesktopSidebar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> navItems;
  final ValueChanged<int> onSelect;

  const _DesktopSidebar({
    required this.currentIndex,
    required this.navItems,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bm = context.watch<BadgeManager>();
    final count = bm.badges.length;
    final cloudOnline = bm.cloudAvailable;

    final email =
        AuthService.client.auth.currentSession?.user.email ?? 'admin@campoverde.gov.br';

    return Container(
      width: 240,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header Institucional ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF161C22) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  child: Image.asset(
                    'assets/brasao.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.account_balance_rounded,
                      size: 20,
                      color: isDark ? AppColors.brandDark : AppColors.brandLight,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'CAMPO VERDE',
                              style: TextStyle(
                                fontFamily: 'Rawline',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: isDark ? AppColors.textDark : AppColors.textLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: const Text(
                              'OFICIAL',
                              style: TextStyle(
                                fontFamily: 'Rawline',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Emissor de Crachás',
                        style: TextStyle(
                          fontFamily: 'Rawline',
                          fontSize: 11,
                          color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Divisor sutil ──────────────────────────────────────────
          Container(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),

          // ── Label de Seção ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'NAVEGAÇÃO',
              style: TextStyle(
                fontFamily: 'Rawline',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: isDark ? AppColors.mutedDark.withValues(alpha: 0.7) : AppColors.mutedLight,
              ),
            ),
          ),

          // ── Lista de Itens de Navegação ────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: navItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (context, i) {
                final item = navItems[i];
                final isSelected = i == currentIndex;
                int? badgeCount;
                if (item.route == 'crachas' && count > 0) {
                  badgeCount = count;
                }

                return _SidebarItem(
                  item: item,
                  isSelected: isSelected,
                  badgeCount: badgeCount,
                  onTap: () => onSelect(i),
                );
              },
            ),
          ),

          // ── Footer: Status da Nuvem & Perfil ────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chip de status de sincronização
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF14191E) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cloudOnline ? AppColors.success : AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cloudOnline ? 'Nuvem Conectada' : 'Modo Offline',
                          style: TextStyle(
                            fontFamily: 'Rawline',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                          ),
                        ),
                      ),
                      Icon(
                        cloudOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                        size: 14,
                        color: cloudOnline ? AppColors.success : AppColors.warning,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Card do usuário autenticado
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF14191E) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: (isDark ? AppColors.brandDark : AppColors.brandLight)
                            .withValues(alpha: 0.16),
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: 15,
                          color: isDark ? AppColors.brandDark : AppColors.brandLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              email.split('@').first,
                              style: TextStyle(
                                fontFamily: 'Rawline',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textDark : AppColors.textLight,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Servidor RH',
                              style: TextStyle(
                                fontFamily: 'Rawline',
                                fontSize: 10,
                                color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => AuthService.signOut(),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.logout_rounded,
                            size: 15,
                            color: isDark ? AppColors.mutedDark : AppColors.mutedLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botão de Item da Sidebar ────────────────────────────────────────────────

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final int? badgeCount;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isSelected,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final brand = isDark ? AppColors.brandDark : AppColors.brandLight;
    final text = isDark ? AppColors.textDark : AppColors.textLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    final bg = isSelected
        ? brand.withValues(alpha: isDark ? 0.14 : 0.10)
        : Colors.transparent;

    final fgColor = isSelected ? brand : (isDark ? text : const Color(0xFF334155));

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        hoverColor: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Icon(
                isSelected ? item.activeIcon : item.icon,
                size: 18,
                color: fgColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: fgColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeCount != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? brand.withValues(alpha: 0.2)
                        : (isDark ? const Color(0xFF1E2630) : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: TextStyle(
                      fontFamily: 'Rawline',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? brand : muted,
                    ),
                  ),
                ),
              ] else if (item.shortcut != null && !isSelected) ...[
                Text(
                  item.shortcut!,
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 10.5,
                    color: isDark ? const Color(0xFF4A5568) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Item de Navegação Mobile ────────────────────────────────────────────────

class _MobileNavItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Color brandColor;
  final Color mutedColor;

  const _MobileNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.brandColor,
    required this.mutedColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? brandColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 20,
              color: isSelected ? brandColor : mutedColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.label,
            style: TextStyle(
              fontFamily: 'Rawline',
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? brandColor : mutedColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Barra Superior Desktop (Clean Header 52px)
// ============================================================================

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.routeLabel,
    this.search,
    this.actions,
    this.userAvatar,
  });

  final String routeLabel;
  final Widget? search;
  final List<Widget>? actions;
  final Widget? userAvatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Breadcrumb
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Prefeitura de Campo Verde',
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 12.5,
                  color: muted,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '/',
                  style: TextStyle(
                    fontFamily: 'Rawline',
                    fontSize: 12,
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              Text(
                routeLabel,
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
            ],
          ),

          if (search != null) ...[
            const SizedBox(width: 20),
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
  const _NavItem({
    required this.route,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.shortcut,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String? shortcut;
}
