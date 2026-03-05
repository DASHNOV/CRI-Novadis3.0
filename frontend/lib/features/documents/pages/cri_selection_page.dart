import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/documents_providers.dart';
import '../../export/providers/export_providers.dart';

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
    final reportsAsync = ref.watch(availableReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner un CRI'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Rechercher un client, site ou numéro...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_late_outlined,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'Aucun rapport terminé trouvé'
                        : 'Aucun résultat pour "$_searchQuery"',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  if (_searchQuery.isEmpty) ...[
                    const SizedBox(height: 8),
                    const Text('Assurez-vous d\'avoir validé vos rapports.'),
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(availableReportsProvider);
              return ref.read(availableReportsProvider.future);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredReports.length,
              itemBuilder: (context, index) {
                final report = filteredReports[index];
                return _CriReportCard(report: report);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text('Erreur lors de la récupération des rapports'),
              TextButton(
                onPressed: () => ref.refresh(availableReportsProvider),
                child: const Text('Réessayer'),
              ),
            ],
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        onTap: () => _showExportConfirm(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: report.isProjet
                          ? Colors.purple.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      report.isProjet ? 'Projet' : 'Service',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: report.isProjet ? Colors.purple : Colors.blue,
                      ),
                    ),
                  ),
                  Text(
                    report.nIntervention,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                report.clientName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.siteName,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(report.date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () => _showExportConfirm(context, ref),
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('Exporter'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ],
              ),
            ],
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
      title: const Text('Génération du PDF'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            progress?.status ?? 'Préparation du document...',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Veuillez patienter',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

