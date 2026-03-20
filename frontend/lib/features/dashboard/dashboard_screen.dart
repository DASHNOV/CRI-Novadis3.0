import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/core/config/app_router.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';

/// Écran principal du dashboard
/// Affiche les actions principales de l'application
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeAnimationProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Dashboard', style: TextStyle(color: AppTheme.textPrimary)),
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: AppTheme.textPrimary),
            onPressed: () {
              // Retour à l'écran de connexion
              context.go(AppRouter.login);
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                  boxShadow: AppTheme.shadowSm,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.dashboard,
                        size: 48,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bienvenue sur Novadis CRI',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gérez vos comptes rendus d\'intervention',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Actions principales
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _DashboardCard(
                      icon: Icons.add_circle_outline,
                      title: 'Créer un CRI',
                      color: AppTheme.success,
                      onTap: () => context.push(AppRouter.criForm),
                    ),
                    _DashboardCard(
                      icon: Icons.history,
                      title: 'Historique',
                      color: AppTheme.primary,
                      onTap: () => context.push(AppRouter.history),
                    ),
                    _DashboardCard(
                      icon: Icons.admin_panel_settings,
                      title: 'Admin',
                      color: AppTheme.warning,
                      onTap: () => context.push(AppRouter.admin),
                    ),
                    _DashboardCard(
                      icon: Icons.info_outline,
                      title: 'À propos',
                      color: AppTheme.accent,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('À propos'),
                            content: const Text(
                              'Novadis CRI v1.0.0\n\n'
                              'Application de gestion des comptes rendus d\'intervention.\n\n'
                              'Mode démonstration - Données locales uniquement.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Fermer'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget de carte pour les actions du dashboard
class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
