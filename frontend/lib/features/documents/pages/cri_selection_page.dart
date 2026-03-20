import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:novadis_cri/core/theme/app_theme.dart';
import '../providers/documents_providers.dart';
import '../../export/providers/export_providers.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';

/// Page de sélection d'un CRI pour l'exportation PDF
class CriSelectionPage extends ConsumerStatefulWidget {
  const CriSelectionPage({super.key});

  @override
  ConsumerState<CriSelectionPage> createState() => _CriSelectionPageState();
}

class _CriSelectionPageState extends ConsumerState<CriSelectionPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeAnimationProvider);
    final reportsAsync = ref.watch(availableReportsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Sélectionner un CRI'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space16,
              0,
              AppTheme.space16,
              AppTheme.space12,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Rechercher un client, site ou numéro...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textTertiary,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppTheme.textTertiary,
                    size: 20,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: AppTheme.textTertiary,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppTheme.space12,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: reportsAsync.when(
        data: (reports) {
          final filteredReports = reports.where((report) {
            final query = _searchQuery.toLowerCase();
            return report.clientName.toLowerCase().contains(query) ||
                report.siteName.toLowerCase().contains(query) ||
                report.nIntervention.toLowerCase().contains(query);
          }).toList();

          if (filteredReports.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.space32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.space20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _searchQuery.isEmpty
                            ? Icons.assignment_outlined
                            : Icons.search_off_rounded,
                        size: 40,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                    Text(
                      _searchQuery.isEmpty
                          ? 'Aucun rapport terminé trouvé'
                          : 'Aucun résultat pour "$_searchQuery"',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_searchQuery.isEmpty) ...[
                      const SizedBox(height: AppTheme.space8),
                      Text(
                        'Assurez-vous d\'avoir validé vos rapports.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(availableReportsProvider);
              return ref.read(availableReportsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(AppTheme.space16),
              itemCount: filteredReports.length,
              itemBuilder: (context, index) {
                final report = filteredReports[index];
                return _CriReportCard(report: report);
              },
            ),
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(height: AppTheme.space16),
              Text(
                'Chargement des rapports...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space16),
                  decoration: BoxDecoration(
                    color: AppTheme.errorLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: AppTheme.error,
                    size: 32,
                  ),
                ),
                const SizedBox(height: AppTheme.space16),
                Text(
                  'Erreur lors de la récupération des rapports',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.space16),
                OutlinedButton.icon(
                  onPressed: () => ref.refresh(availableReportsProvider),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CriReportCard extends ConsumerWidget {
  final CriReportModel report;

  const _CriReportCard({required this.report});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    final bool isProjet = report.isProjet;
    final Color typeBadgeColor =
        isProjet ? AppTheme.accent : AppTheme.primary;
    final Color typeBadgeBg =
        isProjet ? AppTheme.accent.withValues(alpha: 0.08) : AppTheme.infoLight;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          onTap: () => _showExportConfirm(context, ref),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: type badge + intervention number
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space8,
                        vertical: AppTheme.space4,
                      ),
                      decoration: BoxDecoration(
                        color: typeBadgeBg,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusFull,
                        ),
                      ),
                      child: Text(
                        isProjet ? 'Projet' : 'Service',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: typeBadgeColor,
                        ),
                      ),
                    ),
                    Text(
                      report.nIntervention,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space12),

                // Client name
                Text(
                  report.clientName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),

                // Location
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(width: AppTheme.space4),
                    Expanded(
                      child: Text(
                        report.siteName,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Separator
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.space12,
                  ),
                  child: Divider(
                    height: 1,
                    color: AppTheme.border.withValues(alpha: 0.5),
                  ),
                ),

                // Footer: date + export button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(width: AppTheme.space4),
                        Text(
                          dateFormat.format(report.date),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: () => _showExportConfirm(context, ref),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                      label: const Text('Exporter'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space16,
                          vertical: 0,
                        ),
                        minimumSize: const Size(0, 34),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExportConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ExportProgressDialog(report: report),
    );
  }
}

class _ExportProgressDialog extends ConsumerStatefulWidget {
  final CriReportModel report;

  const _ExportProgressDialog({required this.report});

  @override
  ConsumerState<_ExportProgressDialog> createState() =>
      _ExportProgressDialogState();
}

class _ExportProgressDialogState extends ConsumerState<_ExportProgressDialog> {
  @override
  void initState() {
    super.initState();
    // Lancer l'exportation après la première frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _startExport());
  }

  Future<void> _startExport() async {
    try {
      await ref.read(generateCriPdfProvider(widget.report.id).future);

      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de progrès
        Navigator.pop(context); // Retourner à la page Documents

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF généré avec succès pour ${widget.report.clientName}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Rafraîchir la liste des documents
        ref.invalidate(exportedDocumentsProvider);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de progrès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération : ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Écouter le progrès d'export pour valider que ça fonctionne
    final progress = ref.watch(exportProgressProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppTheme.space24,
        AppTheme.space24,
        AppTheme.space24,
        AppTheme.space24,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated progress indicator
          Container(
            padding: const EdgeInsets.all(AppTheme.space16),
            decoration: BoxDecoration(
              color: AppTheme.infoLight,
              shape: BoxShape.circle,
            ),
            child: const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space20),
          Text(
            'Génération du PDF',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            progress?.status ?? 'Préparation du document...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            'Veuillez patienter',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
