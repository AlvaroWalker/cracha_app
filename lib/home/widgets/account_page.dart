import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_tokens.dart';
import '../../views/app_button.dart';

/// Página de conta e sessão no padrão Modern SaaS (Linear / Vercel):
/// - Identificação do operador do sistema
/// - Metadados da conexão e segurança
/// - Ação de encerramento de sessão
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final brand = isDark ? AppColors.brandDark : AppColors.brandLight;
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final email = AuthService.client.auth.currentSession?.user.email ?? 'admin@campoverde.gov.br';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Conta & Sessão',
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Detalhes da credencial autenticada no emissor de crachás.',
                style: TextStyle(
                  fontFamily: 'Rawline',
                  fontSize: 13,
                  color: muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Card do Operador
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1,
                  ),
                  boxShadow: AppShadow.sm(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: brand.withValues(alpha: isDark ? 0.16 : 0.10),
                          child: Icon(
                            Icons.admin_panel_settings_rounded,
                            size: 28,
                            color: brand,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                email,
                                style: TextStyle(
                                  fontFamily: 'Rawline',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.textDark : AppColors.textLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(AppRadius.pill),
                                    ),
                                    child: const Text(
                                      'OPERADOR RH OFICIAL',
                                      style: TextStyle(
                                        fontFamily: 'Rawline',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.success,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 1,
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                    const SizedBox(height: 16),

                    // Metadados
                    _InfoRow(
                      icon: Icons.shield_outlined,
                      label: 'Autenticação',
                      value: 'Supabase Cloud Auth (Criptografado)',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.account_balance_outlined,
                      label: 'Município',
                      value: 'Prefeitura Municipal de Campo Verde — MT',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _InfoRow(
                      icon: Icons.offline_bolt_outlined,
                      label: 'Modo Offline',
                      value: 'Sincronização bidirecional ativa',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botão de Logout
              AppButton.danger(
                label: 'Encerrar Sessão neste Dispositivo',
                icon: Icons.logout_rounded,
                onPressed: () => AuthService.signOut(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.mutedDark : AppColors.mutedLight;

    return Row(
      children: [
        Icon(icon, size: 16, color: muted),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Rawline',
            fontSize: 12.5,
            color: muted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Rawline',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
        ),
      ],
    );
  }
}
