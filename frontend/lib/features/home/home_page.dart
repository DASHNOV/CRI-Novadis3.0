import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/core/config/app_router.dart';
import 'package:novadis_cri/core/storage/storage_service.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'package:novadis_cri/features/auth/presentation/providers/user_name_provider.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';

/// Page d'accueil principale après authentification
/// Dirige l'utilisateur vers les fonctionnalités principales
class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeAnimationProvider);
    final userName = ref.watch(userNameProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Novadis CRI', style: TextStyle(color: AppTheme.textPrimary)),
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: AppTheme.textPrimary),
            onPressed: () => context.go(AppRouter.login),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête de bienvenue
              _buildWelcomeHeader(context, userName ?? ''),

              const SizedBox(height: 32),

              // Action principale : Nouveau CRI
              _buildPrimaryAction(context),

              const SizedBox(height: 24),

              // Actions secondaires
              _buildSecondaryActions(context),

              const SizedBox(height: 32),

              // Statistiques rapides (optionnel)
              _buildQuickStats(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, String userName) {
    return Column(
      children: [
        const Icon(
          Icons.engineering,
          size: 64,
          color: AppTheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          userName.isNotEmpty ? 'Bonjour $userName' : 'Bienvenue',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Gérez vos comptes rendus d\'intervention',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPrimaryAction(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.shadowMd,
      ),
      child: InkWell(
        onTap: () => context.push(AppRouter.criForm),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                AppTheme.primary,
                AppTheme.accent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_circle_outline,
                  size: 48,
                  color: AppTheme.textOnPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Nouveau Compte Rendu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textOnPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Créer un nouveau CRI Projet ou Service',
                style: TextStyle(fontSize: 14, color: AppTheme.textOnPrimary.withValues(alpha: 0.7)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Autres actions',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.dashboard_outlined,
                label: 'Tableau de Bord',
                color: AppTheme.primary,
                onTap: () => context.push(AppRouter.dashboard),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.history,
                label: 'Historique',
                color: AppTheme.warning,
                onTap: () => context.push(AppRouter.history),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.folder_outlined,
                label: 'Documents',
                color: AppTheme.success,
                onTap: () => context.push(AppRouter.documents),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.admin_panel_settings,
                label: 'Administration',
                color: AppTheme.success,
                onTap: () => context.push(AppRouter.admin),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Accès rapide',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _QuickStatRow(
              icon: Icons.description_outlined,
              label: 'Créer un CRI Projet',
              onTap: () => context.push(AppRouter.criNewProjet),
            ),
            const Divider(height: 24),
            _QuickStatRow(
              icon: Icons.build_outlined,
              label: 'Créer un CRI Service',
              onTap: () => context.push(AppRouter.criNewService),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickStatRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}

