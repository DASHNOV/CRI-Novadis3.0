import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:novadis_cri/core/config/app_router.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  color: AppTheme.primaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: const Icon(
                  Icons.add_circle_outline,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Nouveau document',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (kIsWeb)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'L\'export de documents n\'est pas disponible sur le Web.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textTertiary,
                  ),
                ),
              ),
            )
          else ...[
            // Options d'export
            _ExportOption(
              icon: Icons.picture_as_pdf,
              iconColor: AppTheme.error,
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
              iconColor: AppTheme.primary,
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
              iconColor: AppTheme.success,
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
            backgroundColor: AppTheme.surface,
            title: Text(
              'Export Dashboard',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choisissez le type d\'export :',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.list, color: AppTheme.primary),
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
                  leading: const Icon(Icons.analytics, color: AppTheme.primary),
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
                  leading: const Icon(Icons.leaderboard, color: AppTheme.primary),
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
                  leading: const Icon(Icons.all_inclusive, color: AppTheme.primary),
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
                  backgroundColor: AppTheme.surface,
                  title: Text(
                    'Export Stats Technicien',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                  content: Text(
                    'Aucun technicien trouvé.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
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
                    backgroundColor: AppTheme.surface,
                    title: Text(
                      'Export Stats Technicien',
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sélectionnez le technicien :',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
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
              backgroundColor: AppTheme.surface,
              title: Text(
                'Erreur',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              content: Text(
                'Erreur lors du chargement: $error',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
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
            ).colorScheme.copyWith(primary: AppTheme.primary),
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
            backgroundColor: AppTheme.success,
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
            backgroundColor: AppTheme.error,
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
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
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
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
