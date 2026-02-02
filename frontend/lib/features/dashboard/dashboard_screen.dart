import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/core/config/app_router.dart';

/// Écran principal du dashboard
/// Affiche les actions principales de l'application
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.dashboard,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Bienvenue sur Novadis CRI',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gérez vos comptes rendus d\'intervention',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
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
                      color: Colors.green,
                      onTap: () => context.push(AppRouter.criForm),
                    ),
                    _DashboardCard(
                      icon: Icons.history,
                      title: 'Historique',
                      color: Colors.blue,
                      onTap: () => context.push(AppRouter.history),
                    ),
                    _DashboardCard(
                      icon: Icons.admin_panel_settings,
                      title: 'Admin',
                      color: Colors.orange,
                      onTap: () => context.push(AppRouter.admin),
                    ),
                    _DashboardCard(
                      icon: Icons.info_outline,
                      title: 'À propos',
                      color: Colors.purple,
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
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
