import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:novadis_cri/data/models/cri_model.dart';
import 'package:novadis_cri/data/repositories/site_summary_repository.dart';
import 'package:novadis_cri/data/models/site_summary_model.dart';
import 'package:novadis_cri/features/cri_form/widgets/site_summary_card.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';

class CriDetailsDialog extends ConsumerWidget {
  final CriModel cri;

  const CriDetailsDialog({super.key, required this.cri});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Barre de saisie
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        cri.client,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Résumé du site
                    _buildSiteSummary(ref),

                    const SizedBox(height: 24),

                    Text(
                      'DÉTAILS DE L\'INTERVENTION',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.primaryContent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildInfoTile(Icons.location_on_outlined, 'Site', cri.site),
                    _buildInfoTile(Icons.build_circle_outlined, 'Type', cri.typeIntervention),
                    _buildInfoTile(Icons.calendar_today_outlined, 'Date', DateFormat('dd/MM/yyyy').format(cri.date)),

                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Description :', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(cri.description),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSiteSummary(WidgetRef ref) {
    final siteSummaryRepo = ref.watch(siteSummaryRepositoryProvider);

    return FutureBuilder<SiteSummaryModel?>(
      future: siteSummaryRepo.getSummary(cri.site),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return SiteSummaryCard(
            summary: snapshot.data!,
            onDismiss: () {},
            onSeeHistory: () {},
          );
        }
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: const Text('Aucun historique serveur pour ce site.'),
        );
      },
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
