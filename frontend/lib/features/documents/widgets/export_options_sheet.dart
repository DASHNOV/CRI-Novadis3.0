import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:novadis_cri/core/config/app_router.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';
import 'package:novadis_cri/features/export/providers/export_providers.dart';

/// Bottom sheet pour choisir le type d'export à créer
class ExportOptionsSheet extends ConsumerWidget {
  const ExportOptionsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Nouveau document',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (kIsWeb)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'L\'export de documents n\'est pas disponible sur le Web.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ),
            )
          else ...[
            // Options d'export
            _ExportOption(
              icon: Icons.picture_as_pdf,
              iconColor: Colors.red,
              title: 'Exporter CRI en PDF',
              subtitle: 'Générer un rapport PDF pour un CRI',
              onTap: () {
                Navigator.pop(context);
                context.push(AppRouter.criSelection);
              },
            ),
            const SizedBox(height: 12),

            _ExportOption(
              icon: Icons.dashboard,
              iconColor: Colors.blue,
              title: 'Exporter Dashboard (CSV)',
              subtitle: 'Exporter les statistiques du dashboard',
              onTap: () {
                Navigator.pop(context);
                _showDashboardExportDialog(context);
              },
            ),
            const SizedBox(height: 12),

            _ExportOption(
              icon: Icons.person,
              iconColor: Colors.green,
              title: 'Exporter Stats Technicien (CSV)',
              subtitle: 'Exporter les statistiques d\'un technicien',
              onTap: () {
                Navigator.pop(context);
                _showTechnicianExportDialog(context);
              },
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showDashboardExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, child) {
          return AlertDialog(
            title: const Text('Export Dashboard'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choisissez le type d\'export :'),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.list),
                  title: const Text('Interventions globales'),
                  onTap: () {
                    _pickDateAndExport(
                      dialogContext,
                      ref,
                      (start, end) => ref.refresh(
                        exportInterventionsCsvProvider((
                          startDate: start,
                          endDate: end,
                        )).future,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.analytics),
                  title: const Text('Synthèse KPI'),
                  onTap: () {
                    _pickDateAndExport(
                      dialogContext,
                      ref,
                      (start, end) => ref.refresh(
                        exportKPICsvProvider((
                          startDate: start,
                          endDate: end,
                        )).future,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.leaderboard),
                  title: const Text('Top Sites'),
                  onTap: () {
                    _pickDateAndExport(
                      dialogContext,
                      ref,
                      (start, end) => ref.refresh(
                        exportTopSitesCsvProvider((
                          startDate: start,
                          endDate: end,
                        )).future,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.all_inclusive),
                  title: const Text('Tout exporter'),
                  onTap: () {
                    _pickDateAndExport(
                      dialogContext,
                      ref,
                      (start, end) => ref.refresh(
                        exportAllDashboardCsvProvider((
                          startDate: start,
                          endDate: end,
                        )).future,
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTechnicianExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, child) {
          final techniciansAsync = ref.watch(techniciansListProvider);

          return techniciansAsync.when(
            data: (technicians) {
              if (technicians.isEmpty) {
                return AlertDialog(
                  title: const Text('Export Stats Technicien'),
                  content: const Text('Aucun technicien trouvé.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Fermer'),
                    ),
                  ],
                );
              }

              // On utilise un StatefulBuilder pour gérer l'état de la sélection
              // indépendamment de Riverpod pour ce champ local
              String selectedTech = technicians.first.name;

              return StatefulBuilder(
                builder: (context, setState) {
                  return AlertDialog(
                    title: const Text('Export Stats Technicien'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Sélectionnez le technicien :'),
                        const SizedBox(height: 12),
                        DropdownButton<String>(
                          isExpanded: true,
                          value: selectedTech,
                          items: technicians.map((t) {
                            return DropdownMenuItem(
                              value: t.name,
                              child: Text(t.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedTech = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Annuler'),
                      ),
                      FilledButton(
                        onPressed: () {
                          _pickDateAndExport(
                            dialogContext,
                            ref,
                            (start, end) => ref.refresh(
                              exportTechnicianStatsCsvProvider((
                                technicianName: selectedTech,
                                startDate: start,
                                endDate: end,
                              )).future,
                            ),
                          );
                        },
                        child: const Text('Continuer'),
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => AlertDialog(
              title: const Text('Erreur'),
              content: Text('Erreur lors du chargement: $error'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickDateAndExport(
    BuildContext dialogContext,
    WidgetRef ref,
    Future<dynamic> Function(DateTime start, DateTime end) exportAction,
  ) async {
    final now = DateTime.now();
    // Utiliser le contexte du dialogue pour afficher le DatePicker
    final dateRange = await showDateRangePicker(
      context: dialogContext,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: Theme.of(context).primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (dateRange == null) return;

    // On garde le dialogue ouvert pour avoir un contexte valide pour le ScaffoldMessenger
    if (!dialogContext.mounted) return;

    ScaffoldMessenger.of(dialogContext).showSnackBar(
      const SnackBar(
        content: Text('Génération de l\'export en cours...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final result = await exportAction(dateRange.start, dateRange.end);

      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(
            content: Text('Export réussi !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Ouvrir le fichier automatiquement
        if (!kIsWeb && result != null) {
           // On ne tente pas d'ouvrir le fichier sur le web car c'est un dynamic qui n'est pas un File
           // Logic for native opening...
        }

        // Attendre un peu que le message s'affiche
        await Future.delayed(const Duration(milliseconds: 1000));

        if (dialogContext.mounted) {
          Navigator.pop(dialogContext);
        }
      }
    } catch (e) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Widget pour une option d'export
class _ExportOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ExportOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

