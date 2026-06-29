import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:novadis_cri/data/models/cri_model.dart';
import 'package:novadis_cri/data/models/cri_service_model.dart';
import 'package:novadis_cri/data/models/cri_projet_model.dart';
import 'package:novadis_cri/data/local/app_database.dart';
import 'package:novadis_cri/data/repositories/cri_remote_repository.dart';
import 'package:novadis_cri/features/history/widgets/cri_details_dialog.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';

/// Écran d'historique des CRI
/// Affiche la liste de tous les comptes rendus d'intervention
// Providers pour les flux de données réactifs
final criServicesStreamProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(appDatabaseProvider).watchAllCriService();
});

final criProjectsStreamProvider = StreamProvider.autoDispose((ref) {
  return ref.watch(appDatabaseProvider).watchAllCriProjet();
});

final historyListProvider = Provider.autoDispose<List<CriModel>>((ref) {
  final services = ref.watch(criServicesStreamProvider).valueOrNull ?? [];
  final projects = ref.watch(criProjectsStreamProvider).valueOrNull ?? [];

  final all = <CriModel>[];

  // Mapping des services
  for (var s in services) {
    all.add(
      CriModel(
        id: s.id,
        client: s.clientName,
        site: s.site,
        typeIntervention: s.requestType,
        description: s.requestDescription,
        date: s.interventionDate,
        createdAt: s.createdAt,
      ),
    );
  }

  // Mapping des projets
  for (var p in projects) {
    all.add(
      CriModel(
        id: p.id,
        client: p.clientName,
        site: p.site,
        typeIntervention: 'Projet: ${p.interventionType}',
        description: p.workDescription,
        date: p.interventionDate,
        createdAt: p.createdAt,
      ),
    );
  }

  // Tri par date de création décroissante
  all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return all;
});

class HistoryScreen extends HookConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeAnimationProvider);
    final db = ref.watch(appDatabaseProvider);
    final criList = ref.watch(historyListProvider);
    final remoteRepo = ref.watch(criRemoteRepositoryProvider);
    final servicesAsync = ref.watch(criServicesStreamProvider);
    final projectsAsync = ref.watch(criProjectsStreamProvider);
    final isLoading =
        servicesAsync.isLoading && projectsAsync.isLoading;
    final hasData = servicesAsync.hasValue || projectsAsync.hasValue;

    // Auto-sync depuis l'API au premier chargement si la BDD locale est vide
    useEffect(() {
      if (hasData && criList.isEmpty) {
        Future.microtask(() async {
          try {
            final remoteCris = await remoteRepo.getAllCris();
            for (var cri in remoteCris) {
              if (cri is CriServiceModel) {
                await db.updateCriService(cri.toDb());
              } else if (cri is CriProjetModel) {
                await db.updateCriProjet(cri.toDb());
              }
            }
          } catch (_) {}
        });
      }
      return null;
    }, [hasData]);

    Future<void> handleRefresh() async {
      try {
        final remoteCris = await remoteRepo.getAllCris();
        for (var cri in remoteCris) {
          if (cri is CriServiceModel) {
            await db.updateCriService(cri.toDb());
          } else if (cri is CriProjetModel) {
            await db.updateCriProjet(cri.toDb());
          }
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Synchro réussie : ${remoteCris.length} éléments')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de synchronisation : $e'), backgroundColor: AppTheme.error),
          );
        }
      }
    }

    Future<void> handleDelete(String id) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Voulez-vous vraiment supprimer ce CRI ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        // Suppression serveur (ignorée si le CRI est un brouillon local uniquement)
        try {
          await remoteRepo.deleteCri(id);
        } catch (_) {}

        int deleted = await db.deleteCriService(id);
        if (deleted == 0) {
          deleted = await db.deleteCriProjet(id);
        }

        if (context.mounted) {
          if (deleted > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('CRI supprimé'),
                backgroundColor: AppTheme.success,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Erreur lors de la suppression ou CRI introuvable',
                ),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        }
      }
    }

    void showCriDetails(CriModel cri) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ouverture de ${cri.client}...'), duration: const Duration(milliseconds: 500)),
      );

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => CriDetailsDialog(
          cri: cri,
          canDelete: true,
          onDeleted: () async {
            int deleted = await db.deleteCriService(cri.id);
            if (deleted == 0) await db.deleteCriProjet(cri.id);
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Historique', style: TextStyle(color: AppTheme.textPrimary)),
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: handleRefresh,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (isLoading && criList.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (criList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textTertiary),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun CRI enregistré',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Créez votre premier compte rendu d\'intervention',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.textTertiary),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: handleRefresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: criList.length,
              itemBuilder: (context, index) {
                final cri = criList[index];
                return _CriCard(
                  cri: cri,
                  onTap: () => showCriDetails(cri),
                  onDelete: () => handleDelete(cri.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Widget de carte pour afficher un CRI dans la liste
class _CriCard extends StatelessWidget {
  final CriModel cri;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CriCard({
    required this.cri,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cri.client,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cri.site,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                    onPressed: onDelete,
                    tooltip: 'Supprimer',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.build_outlined, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cri.typeIntervention,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd/MM/yyyy').format(cri.date),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
