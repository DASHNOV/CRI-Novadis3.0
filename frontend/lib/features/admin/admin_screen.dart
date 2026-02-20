import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/data/local/local_storage_service.dart';
import 'package:novadis_cri/core/storage/storage_service.dart';
import 'package:novadis_cri/core/config/app_router.dart';

/// Écran d'administration
/// Affiche des statistiques et options de gestion
class AdminScreen extends HookConsumerWidget {
  const AdminScreen({super.key});

  /// Charge les statistiques des CRI
  static Future<Map<String, dynamic>> _loadStats(
    LocalStorageService service,
  ) async {
    final criList = await service.getAllCri();

    // Calcul des statistiques
    final totalCri = criList.length;
    final clientsSet = criList.map((cri) => cri.client).toSet();
    final sitesSet = criList.map((cri) => cri.site).toSet();

    // Comptage par type d'intervention
    final typeCount = <String, int>{};
    for (var cri in criList) {
      typeCount[cri.typeIntervention] =
          (typeCount[cri.typeIntervention] ?? 0) + 1;
    }

    return {
      'totalCri': totalCri,
      'totalClients': clientsSet.length,
      'totalSites': sitesSet.length,
      'typeCount': typeCount,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageService = useMemoized(() => LocalStorageService());
    final statsFuture = useMemoized(() => _loadStats(storageService));
    final refreshKey = useState(0);

    Future<void> handleRefresh() async {
      refreshKey.value++;
    }

    Future<void> handleLogout() async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Déconnexion'),
          content: const Text('Voulez-vous vraiment vous déconnecter ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Se déconnecter'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await ref.read(storageServiceProvider).clearTokens();
        if (context.mounted) {
          context.go(AppRouter.login);
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: handleRefresh,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: handleLogout,
            tooltip: 'Se déconnecter',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        key: ValueKey(refreshKey.value),
        future: statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          final stats = snapshot.data!;
          final totalCri = stats['totalCri'] as int;
          final totalClients = stats['totalClients'] as int;
          final totalSites = stats['totalSites'] as int;
          final typeCount = stats['typeCount'] as Map<String, int>;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // En-tête
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Panneau d\'administration',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Statistiques générales
              Text(
                'Statistiques',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.description,
                      label: 'CRI',
                      value: totalCri.toString(),
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.people,
                      label: 'Clients',
                      value: totalClients.toString(),
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.location_on,
                      label: 'Sites',
                      value: totalSites.toString(),
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Répartition par type
              if (typeCount.isNotEmpty) ...[
                Text(
                  'Répartition par type',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: typeCount.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  entry.value.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Actions administratives
              Text(
                'Actions',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                      ),
                      title: const Text('À propos'),
                      subtitle: const Text('Informations sur l\'application'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('À propos'),
                            content: const Text(
                              'Novadis CRI v1.0.0\n\n'
                              'Application de gestion des comptes rendus d\'intervention.\n\n'
                              'Architecture: Clean Architecture\n'
                              'Navigation: GoRouter\n'
                              'State Management: Flutter Hooks\n\n'
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
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Se déconnecter'),
                      subtitle: const Text('Fermer la session'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: handleLogout,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Widget de carte pour afficher une statistique
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
