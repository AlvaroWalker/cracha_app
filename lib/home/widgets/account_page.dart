import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

/// Página simples de conta: mostra o email logado + botão sair. Sem enfeite.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final email = AuthService.client.auth.currentSession?.user.email ?? '—';
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Conta',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Sessão atual neste dispositivo.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('Email'),
            subtitle: Text(email),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => AuthService.signOut(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sair'),
        ),
      ],
    );
  }
}
