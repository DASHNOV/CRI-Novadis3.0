import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:novadis_cri/core/config/app_router.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/documents/pages/cri_selection_page.dart';
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  color: AppTheme.primaryContent,
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

          _ExportOption(
            icon: Icons.picture_as_pdf,
            iconColor: AppTheme.error,
            title: 'Exporter CRI en PDF',
            subtitle: kIsWeb
                ? 'Générer et télécharger un rapport PDF'
                : 'Générer un rapport PDF pour un CRI',
            onTap: () {
              Navigator.pop(context);
              context.push(AppRouter.criSelection, extra: CriExportFormat.pdf);
            },
          ),
          const SizedBox(height: 12),

          _ExportOption(
            icon: Icons.table_chart,
            iconColor: AppTheme.success,
            title: 'Exporter CRI (Excel)',
            subtitle: kIsWeb
                ? 'Télécharger un classeur Excel d\'un CRI'
                : 'Générer un classeur Excel pour un CRI',
            onTap: () {
              Navigator.pop(context);
              context.push(AppRouter.criSelection,
                  extra: CriExportFormat.xlsx);
            },
          ),
          const SizedBox(height: 12),

          _ExportOption(
            icon: Icons.calendar_month,
            iconColor: AppTheme.primaryContent,
            title: 'Exporter période (Excel)',
            subtitle: 'Synthèse jour / semaine / mois / année',
            onTap: () {
              Navigator.pop(context);
              _showPeriodXlsxDialog(context);
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showPeriodXlsxDialog(BuildContext context) {
    XlsxExportPeriod selectedPeriod = XlsxExportPeriod.month;
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, child) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text(
              'Export Excel — période',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Période à synthétiser',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: XlsxExportPeriod.values.map((p) {
                    final selected = p == selectedPeriod;
                    return ChoiceChip(
                      label: Text(p.label),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => selectedPeriod = p),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Date de référence',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    '${selectedDate.day.toString().padLeft(2, '0')}/'
                    '${selectedDate.month.toString().padLeft(2, '0')}/'
                    '${selectedDate.year}',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Exporter'),
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  if (!context.mounted) return;
                  await _runPeriodXlsxExport(
                    context,
                    ref,
                    period: selectedPeriod,
                    referenceDate: selectedDate,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runPeriodXlsxExport(
    BuildContext context,
    WidgetRef ref, {
    required XlsxExportPeriod period,
    required DateTime referenceDate,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text('Génération (${period.label}) en cours...'),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final params = (period: period, referenceDate: referenceDate);
      ref.invalidate(exportPeriodXlsxProvider(params));
      final result = await ref.read(exportPeriodXlsxProvider(params).future);

      // Rafraîchir l'inventaire serveur
      ref.invalidate(serverDocumentsProvider);

      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            kIsWeb
                ? 'Excel téléchargé: ${result.filename}'
                : 'Excel généré: ${result.filename}',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'export: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
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
