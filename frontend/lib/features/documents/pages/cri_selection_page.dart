import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:novadis_cri/core/theme/app_theme.dart';
import '../providers/documents_providers.dart';
import '../../export/providers/export_providers.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';

/// Format d'export disponible depuis la sélection d'un CRI.
enum CriExportFormat { pdf, xlsx }

/// Ordre de tri par date des CRI.
enum CriSortOrder {
  dateDesc, // Du plus récent au plus ancien (défaut)
  dateAsc, // Du plus ancien au plus récent
}

/// Page de sélection d'un CRI pour l'exportation (PDF ou Excel)
class CriSelectionPage extends ConsumerStatefulWidget {
  final CriExportFormat format;

  const CriSelectionPage({super.key, this.format = CriExportFormat.pdf});

  @override
  ConsumerState<CriSelectionPage> createState() => _CriSelectionPageState();
}

class _CriSelectionPageState extends ConsumerState<CriSelectionPage> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  CriSortOrder _sortOrder = CriSortOrder.dateDesc;

  @override
  void initState() {
    super.initState();
    // Rafraîchir la liste pour inclure les CRI récemment soumis
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(availableReportsProvider);
    });
  }

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
        title: Text(widget.format == CriExportFormat.xlsx
            ? 'Sélectionner un CRI (Excel)'
            : 'Sélectionner un CRI'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
            onPressed: () => ref.invalidate(availableReportsProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space16,
                  0,
                  AppTheme.space16,
                  AppTheme.space12,
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusLg),
                        border: Border.all(
                          color: AppTheme.border.withValues(alpha: 0.5),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
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
                    const SizedBox(height: AppTheme.space8),
                    Row(
                      children: [
                        Icon(
                          Icons.sort_rounded,
                          size: 16,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _SortChip(
                                  label: 'Plus récent',
                                  selected:
                                      _sortOrder == CriSortOrder.dateDesc,
                                  onSelected: () => setState(
                                    () => _sortOrder = CriSortOrder.dateDesc,
                                  ),
                                ),
                                const SizedBox(width: AppTheme.space8),
                                _SortChip(
                                  label: 'Plus ancien',
                                  selected:
                                      _sortOrder == CriSortOrder.dateAsc,
                                  onSelected: () => setState(
                                    () => _sortOrder = CriSortOrder.dateAsc,
                                  ),
                                ),
                              ],
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
        ),
      ),
      body: reportsAsync.when(
        data: (reports) {
          final filteredReports = reports.where((report) {
            final query = _searchQuery.toLowerCase();
            return report.clientName.toLowerCase().contains(query) ||
                report.siteName.toLowerCase().contains(query) ||
                report.nIntervention.toLowerCase().contains(query);
          }).toList()
            ..sort((a, b) => _sortOrder == CriSortOrder.dateDesc
                ? b.date.compareTo(a.date)
                : a.date.compareTo(b.date));

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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 1100
                    ? 3
                    : constraints.maxWidth >= 700
                        ? 2
                        : 1;

                if (crossAxisCount == 1) {
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.space16),
                    itemCount: filteredReports.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppTheme.space12),
                    itemBuilder: (context, index) {
                      final report = filteredReports[index];
                      return _CriReportCard(
                        report: report,
                        format: widget.format,
                      );
                    },
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: AppTheme.space16,
                        mainAxisSpacing: AppTheme.space16,
                        mainAxisExtent: 200,
                      ),
                      itemCount: filteredReports.length,
                      itemBuilder: (context, index) {
                        final report = filteredReports[index];
                        return _CriReportCard(
                          report: report,
                          format: widget.format,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryContent),
              const SizedBox(height: AppTheme.space16),
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

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _SortChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.primary : AppTheme.surfaceVariant,
      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space12,
            vertical: AppTheme.space8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : AppTheme.border.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CriReportCard extends ConsumerWidget {
  final CriReportModel report;
  final CriExportFormat format;

  const _CriReportCard({required this.report, required this.format});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    final bool isProjet = report.isProjet;
    final Color typeBadgeColor =
        isProjet ? AppTheme.accent : AppTheme.primaryContent;
    final Color typeBadgeBg =
        isProjet ? AppTheme.accent.withValues(alpha: 0.08) : AppTheme.infoLight;

    return Container(
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
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryContent,
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
                      icon: Icon(
                        format == CriExportFormat.xlsx
                            ? Icons.table_chart_rounded
                            : Icons.picture_as_pdf_rounded,
                        size: 16,
                      ),
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
      builder: (context) =>
          _ExportProgressDialog(report: report, format: format),
    );
  }
}

class _ExportProgressDialog extends ConsumerStatefulWidget {
  final CriReportModel report;
  final CriExportFormat format;

  const _ExportProgressDialog({required this.report, required this.format});

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
      if (widget.format == CriExportFormat.xlsx) {
        ref.invalidate(exportCriXlsxProvider(widget.report.id));
        await ref.read(exportCriXlsxProvider(widget.report.id).future);
      } else {
        // Invalider le cache pour forcer une nouvelle génération à chaque fois
        ref.invalidate(generateCriPdfProvider(widget.report.id));
        await ref.read(generateCriPdfProvider(widget.report.id).future);
      }

      if (mounted) {
        Navigator.pop(context); // Fermer le dialog de progrès
        Navigator.pop(context); // Retourner à la page Documents

        final formatLabel =
            widget.format == CriExportFormat.xlsx ? 'Excel' : 'PDF';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb
                  ? '$formatLabel téléchargé pour ${widget.report.clientName}'
                  : '$formatLabel généré avec succès pour ${widget.report.clientName}',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Rafraîchir la liste des documents (natif uniquement)
        if (!kIsWeb) {
          ref.invalidate(exportedDocumentsProvider);
        }
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
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.primaryContent,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.space20),
          Text(
            widget.format == CriExportFormat.xlsx
                ? 'Génération de l\'Excel'
                : 'Génération du PDF',
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
