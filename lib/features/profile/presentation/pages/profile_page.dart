import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

const _background = AppColors.background;
const _headerBackground = AppColors.header;
const _surface = AppColors.surface;
const _border = AppColors.border;
const _brand = AppColors.brand;
const _textPrimary = AppColors.textPrimary;
const _textSecondary = AppColors.textMuted;
const _success = AppColors.success;

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (!context.mounted) return;

    final result = ref.read(authControllerProvider);
    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível sair: ${result.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final authAction = ref.watch(authControllerProvider);
    final displayName = user?.name?.trim().isNotEmpty == true
        ? user!.name!.trim()
        : 'Laboratório Doroteia';
    final email = user?.email ?? 'Sessão local ativa';

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ProfileHeader(onBack: () => context.go('/home')),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileHero(name: displayName, email: email),
                        const SizedBox(height: 24),
                        _ProfileSettingsGrid(
                          isSigningOut: authAction.isLoading,
                          onSignOut: () => _signOut(context, ref),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _headerBackground,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final backButton = OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Voltar ao Dashboard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textPrimary,
                    side: const BorderSide(color: _border),
                  ),
                );

                if (constraints.maxWidth < 520) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _ProfileBrand(),
                      const SizedBox(height: 12),
                      backButton,
                    ],
                  );
                }

                return Row(
                  children: [const _ProfileBrand(), const Spacer(), backButton],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileBrand extends StatelessWidget {
  const _ProfileBrand();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.manage_accounts_outlined, color: _brand, size: 23),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acesso & Conta',
              style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 3),
            Text(
              'Perfil e preferências do laboratório',
              style: TextStyle(color: _textSecondary, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(20),
        gradient: RadialGradient(
          center: const Alignment(1.15, -1.0),
          radius: 1.1,
          colors: [_brand.withValues(alpha: 0.13), Colors.transparent],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(email, style: const TextStyle(color: _textSecondary)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _success.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: _success, size: 8),
                    SizedBox(width: 7),
                    Text(
                      'Sessão ativa e protegida',
                      style: TextStyle(
                        color: _success,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final avatar = CircleAvatar(
            radius: 34,
            backgroundColor: _brand.withValues(alpha: 0.14),
            child: Text(
              _initials(name),
              style: const TextStyle(
                color: _brand,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          );

          if (constraints.maxWidth < 480) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [avatar, const SizedBox(height: 18), details],
            );
          }
          return Row(
            children: [
              avatar,
              const SizedBox(width: 20),
              Expanded(child: details),
            ],
          );
        },
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return 'DL';
    return parts.map((part) => part[0].toUpperCase()).join();
  }
}

class _ProfileSettingsGrid extends StatelessWidget {
  const _ProfileSettingsGrid({
    required this.isSigningOut,
    required this.onSignOut,
  });

  final bool isSigningOut;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680 ? 2 : 1;
        const spacing = 18.0;
        final width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

        final cards = [
          _PreferenceCard(
            icon: Icons.key_outlined,
            title: 'Chaves de API',
            description:
                'Área preparada para integrar credenciais de serviços e automações do laboratório.',
            badge: 'Em breve',
          ),
          _PreferenceCard(
            icon: Icons.tune_rounded,
            title: 'Preferências do Laboratório',
            description:
                'Configure os padrões de impressão e custo quando novos parâmetros forem adicionados.',
            badge: 'Em breve',
          ),
          _PreferenceCard(
            icon: Icons.storage_outlined,
            title: 'Dados locais',
            description:
                'Seu catálogo permanece salvo neste dispositivo para manter o trabalho entre sessões.',
            badge: 'Ativo',
            accent: _success,
          ),
          _SignOutCard(isLoading: isSigningOut, onSignOut: onSignOut),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((card) => SizedBox(width: width, child: card))
              .toList(growable: false),
        );
      },
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    this.accent = _brand,
  });

  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 23),
          const SizedBox(height: 18),
          Text(
            title,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 7),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 12,
                height: 1.42,
              ),
            ),
          ),
          Text(
            badge,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignOutCard extends StatelessWidget {
  const _SignOutCard({required this.isLoading, required this.onSignOut});

  final bool isLoading;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.logout_rounded, color: _textSecondary, size: 23),
          const SizedBox(height: 18),
          const Text(
            'Encerrar sessão',
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 7),
          const Expanded(
            child: Text(
              'Saia desta conta neste dispositivo. Seus dados de catálogo locais serão preservados.',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 12,
                height: 1.42,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: isLoading ? null : onSignOut,
            style: TextButton.styleFrom(
              foregroundColor: _brand,
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: isLoading
                ? const SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _brand,
                    ),
                  )
                : const Icon(Icons.logout_rounded, size: 16),
            label: const Text('Sair da conta'),
          ),
        ],
      ),
    );
  }
}
