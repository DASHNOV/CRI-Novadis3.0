import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/data/local/local_storage_service.dart';
import 'package:novadis_cri/core/storage/storage_service.dart';
import 'package:novadis_cri/core/config/app_router.dart';
import 'package:novadis_cri/core/widgets/content_container.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';

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
    ref.watch(themeAnimationProvider);
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
      backgroundColor: AppTheme.background,
      body: FutureBuilder<Map<String, dynamic>>(
        key: ValueKey(refreshKey.value),
        future: statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.space20),
                    decoration: BoxDecoration(
                      color: AppTheme.errorLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      size: 40,
                      color: AppTheme.error,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space8),
                  Text(
                    'Impossible de charger les statistiques',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textTertiary,
                    ),
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

          return ContentContainer(
            maxWidth: 1200,
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.space20),
              children: [
                // ─── Inline header ───
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.space24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Administration',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: AppTheme.space4),
                              Text(
                                'Statistiques et gestion',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _HeaderActionButton(
                          icon: Icons.refresh_rounded,
                          tooltip: 'Actualiser',
                          onPressed: handleRefresh,
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Stat cards ───
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.description_outlined,
                        label: 'CRI',
                        value: totalCri.toString(),
                        color: AppTheme.primary,
                        bgColor: AppTheme.infoLight,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people_outline_rounded,
                        label: 'Clients',
                        value: totalClients.toString(),
                        color: AppTheme.success,
                        bgColor: AppTheme.successLight,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.location_on_outlined,
                        label: 'Sites',
                        value: totalSites.toString(),
                        color: AppTheme.warning,
                        bgColor: AppTheme.warningLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space24),

                // ─── Type distribution card ───
                if (typeCount.isNotEmpty) ...[
                  Text(
                    'Répartition par type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(
                        color: AppTheme.border.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < typeCount.entries.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              indent: AppTheme.space16,
                              endIndent: AppTheme.space16,
                              color: AppTheme.border.withValues(alpha: 0.5),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space16,
                              vertical: AppTheme.space12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(i),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.space12),
                                Expanded(
                                  child: Text(
                                    typeCount.entries.elementAt(i).key,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.space12,
                                    vertical: AppTheme.space4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusFull,
                                    ),
                                  ),
                                  child: Text(
                                    typeCount.entries
                                        .elementAt(i)
                                        .value
                                        .toString(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space24),
                ],

                // ─── Actions section ───
                Text(
                  'Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.space12),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(
                      color: AppTheme.border.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      _ActionListTile(
                        icon: Icons.info_outline_rounded,
                        iconColor: AppTheme.primary,
                        title: 'À propos',
                        subtitle: 'Informations sur l\'application',
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
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.space24),

                // ─── Logout button ───
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: handleLogout,
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: AppTheme.error,
                    ),
                    label: const Text('Se déconnecter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.space16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusLg,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space32),
              ],
            ),
          );
        },
      ),
    );
  }

  static Color _getTypeColor(int index) {
    final colors = [
      AppTheme.primary,
      AppTheme.success,
      AppTheme.warning,
      AppTheme.accent,
      AppTheme.error,
      AppTheme.primaryLight,
    ];
    return colors[index % colors.length];
  }
}

// ─── Header action button ───
class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: AppTheme.textSecondary,
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          side: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
        ),
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
  final Color bgColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action list tile ───
class _ActionListTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionListTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space16,
          vertical: AppTheme.space12,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.space8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
