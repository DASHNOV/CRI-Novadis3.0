import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/app_database.dart';
import '../../export/providers/export_providers.dart';
import '../../export/models/exported_document_model.dart';
import '../widgets/document_list_item.dart';
import '../widgets/export_options_sheet.dart';
import '../widgets/document_search_bar.dart';
import '../widgets/document_filter_chips.dart';
import '../widgets/empty_documents_state.dart';
import 'package:novadis_cri/core/widgets/content_container.dart';

/// Page principale de gestion des documents exportés
class DocumentsPage extends ConsumerStatefulWidget {
  const DocumentsPage({super.key});

  @override
  ConsumerState<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends ConsumerState<DocumentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDocs = ref.watch(selectedDocumentsProvider);
    final hasSelection = selectedDocs.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? DocumentSearchBar(
                onChanged: (query) {
                  ref.read(searchQueryProvider.notifier).state = query;
                },
                onClose: () {
                  setState(() => _isSearching = false);
                  // Réinitialiser la recherche
                  ref.read(searchQueryProvider.notifier).state = '';
                  final currentFilter = ref.read(documentFilterProvider);
                  ref.read(documentFilterProvider.notifier).state =
                      currentFilter.clearSearch();
                },
              )
            : const Text('Mes Documents'),
        actions: [
          if (!_isSearching && !hasSelection) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = true),
              tooltip: 'Rechercher',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              tooltip: 'Trier',
              onSelected: (value) {
                final sortOption = DocumentSortOption.values.firstWhere(
                  (e) => e.name == value,
                );
                ref.read(documentSortProvider.notifier).state = sortOption;
              },
              itemBuilder: (context) => DocumentSortOption.values
                  .map(
                    (option) => PopupMenuItem(
                      value: option.name,
                      child: Text(option.label),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (hasSelection) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareSelected(),
              tooltip: 'Partager',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteSelected(),
              tooltip: 'Supprimer',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                ref.read(selectedDocumentsProvider.notifier).state = {};
              },
              tooltip: 'Annuler',
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.picture_as_pdf), text: 'CRI (PDF)'),
            Tab(icon: Icon(Icons.table_chart), text: 'Exports (CSV)'),
          ],
        ),
      ),
      body: ContentContainer(
        maxWidth: 1400,
        child: Column(
          children: [
            // Filtres
            const DocumentFilterChips(),

            // Liste des documents
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDocumentList(DocumentFileType.pdf),
                  _buildDocumentList(DocumentFileType.csv),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExportOptions(),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
    );
  }

  Widget _buildDocumentList(DocumentFileType fileType) {
    final baseFilter = ref.watch(documentFilterProvider);
    final sortOption = ref.watch(documentSortProvider);

    // Créer un filtre spécifique pour cet onglet sans modifier le provider global
    final filter = DocumentFilter(
      fileType: fileType,
      exportType: baseFilter.exportType,
      startDate: baseFilter.startDate,
      endDate: baseFilter.endDate,
      searchQuery: baseFilter.searchQuery,
    );

    final documentsAsync = ref.watch(filteredDocumentsProvider(filter));

    return documentsAsync.when(
      data: (documents) {
        if (documents.isEmpty) {
          // Vérifier si c'est à cause d'une recherche active
          final hasSearchQuery =
              baseFilter.searchQuery != null &&
              baseFilter.searchQuery!.isNotEmpty;

          if (hasSearchQuery) {
            // Afficher l'état de recherche vide
            return const EmptySearchState();
          } else {
            // Afficher l'état de documents vides
            return EmptyDocumentsState(
              fileType: fileType,
              onCreatePressed: _showExportOptions,
            );
          }
        }

        // Trier les documents
        final sortedDocs = _sortDocuments(documents, sortOption);

        Widget buildDocItem(ExportedDocument doc) {
              final model = ExportedDocumentModel(
                id: doc.id,
                criId: doc.criId,
                filename: doc.filename,
                filePath: doc.filePath,
                fileType: DocumentFileType.fromString(doc.fileType),
                fileSize: doc.fileSize,
                exportType: ExportType.fromString(doc.exportType),
                metadata: doc.metadata != null ? {'raw': doc.metadata} : null,
                createdAt: doc.createdAt,
                sharedAt: doc.sharedAt,
              );

              return DocumentListItem(
                document: model,
                onTap: () => _openDocument(model),
                onLongPress: () => _toggleSelection(model.id!),
                isSelected: ref
                    .watch(selectedDocumentsProvider)
                    .contains(model.id),
                onShare: () => _shareDocument(model),
                onRename: () => _renameDocument(model),
                onDelete: () => _deleteDocument(model),
              );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(exportedDocumentsProvider);
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 1000) {
                // Desktop: 2-column grid
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 4.0,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: sortedDocs.length,
                  itemBuilder: (context, index) => buildDocItem(sortedDocs[index]),
                );
              }
              // Mobile: simple list
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: sortedDocs.length,
                itemBuilder: (context, index) => buildDocItem(sortedDocs[index]),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(exportedDocumentsProvider),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  List<ExportedDocument> _sortDocuments(
    List<ExportedDocument> documents,
    DocumentSortOption sortOption,
  ) {
    final sorted = List<ExportedDocument>.from(documents);

    switch (sortOption) {
      case DocumentSortOption.newestFirst:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case DocumentSortOption.oldestFirst:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case DocumentSortOption.nameAZ:
        sorted.sort((a, b) => a.filename.compareTo(b.filename));
        break;
      case DocumentSortOption.nameZA:
        sorted.sort((a, b) => b.filename.compareTo(a.filename));
        break;
      case DocumentSortOption.sizeAsc:
        sorted.sort((a, b) => a.fileSize.compareTo(b.fileSize));
        break;
      case DocumentSortOption.sizeDesc:
        sorted.sort((a, b) => b.fileSize.compareTo(a.fileSize));
        break;
    }

    return sorted;
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => const ExportOptionsSheet(),
    );
  }

  Future<void> _openDocument(ExportedDocumentModel document) async {
    final fileService = ref.read(fileManagementServiceProvider);

    try {
      await fileService.openFile(document.filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ouverture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareDocument(ExportedDocumentModel document) async {
    final fileService = ref.read(fileManagementServiceProvider);

    try {
      await fileService.shareFile(
        document.filePath,
        subject: 'Document ${document.filename}',
        text: 'Voici le document demandé',
      );

      // Marquer comme partagé
      if (document.id != null) {
        await fileService.markAsShared(document.id!);
        // Rafraîchir la liste
        ref.invalidate(exportedDocumentsProvider);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Document partagé')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _renameDocument(ExportedDocumentModel document) async {
    if (document.id == null) return;

    final controller = TextEditingController(
      text: document.filename.replaceAll(RegExp(r'\.[^.]+$'), ''),
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renommer le document'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nouveau nom',
            hintText: 'Entrez le nouveau nom',
          ),
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Renommer'),
          ),
        ],
      ),
    );

    if (newName == null || newName.trim().isEmpty) return;

    final fileService = ref.read(fileManagementServiceProvider);

    try {
      await fileService.renameFile(document.id!, newName.trim());

      // Rafraîchir la liste
      ref.invalidate(exportedDocumentsProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Document renommé')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du renommage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _deleteDocument(ExportedDocumentModel document) async {
    if (document.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer "${document.filename}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final fileService = ref.read(fileManagementServiceProvider);

    try {
      await fileService.deleteFile(document.id!);

      // Rafraîchir la liste
      ref.invalidate(exportedDocumentsProvider);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Document supprimé')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleSelection(int documentId) {
    final selected = ref.read(selectedDocumentsProvider);
    final newSelection = Set<int>.from(selected);

    if (newSelection.contains(documentId)) {
      newSelection.remove(documentId);
    } else {
      newSelection.add(documentId);
    }

    ref.read(selectedDocumentsProvider.notifier).state = newSelection;
  }

  Future<void> _shareSelected() async {
    final selected = ref.read(selectedDocumentsProvider);
    final fileService = ref.read(fileManagementServiceProvider);
    final database = ref.read(databaseProvider);

    try {
      final filePaths = <String>[];
      for (final id in selected) {
        final doc = await database.getExportedDocumentById(id);
        if (doc != null) {
          filePaths.add(doc.filePath);
        }
      }

      await fileService.shareMultipleFiles(filePaths);

      // Marquer comme partagés
      for (final id in selected) {
        await fileService.markAsShared(id);
      }

      // Réinitialiser la sélection
      ref.read(selectedDocumentsProvider.notifier).state = {};

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Documents partagés')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteSelected() async {
    final selected = ref.read(selectedDocumentsProvider);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Voulez-vous vraiment supprimer ${selected.length} document(s) ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final fileService = ref.read(fileManagementServiceProvider);

    try {
      final deletedCount = await fileService.deleteMultipleFiles(
        selected.toList(),
      );

      // Réinitialiser la sélection
      ref.read(selectedDocumentsProvider.notifier).state = {};

      // Rafraîchir la liste
      ref.invalidate(exportedDocumentsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$deletedCount document(s) supprimé(s)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
