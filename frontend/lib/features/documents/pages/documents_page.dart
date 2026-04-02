import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:novadis_cri/core/theme/app_theme.dart';
import '../../../data/local/app_database.dart';
import '../../export/providers/export_providers.dart';
import '../../export/models/exported_document_model.dart';
import '../widgets/document_list_item.dart';
import '../widgets/export_options_sheet.dart';
import '../widgets/document_search_bar.dart';
import '../widgets/document_filter_chips.dart';
import '../widgets/empty_documents_state.dart';
import 'package:novadis_cri/core/widgets/content_container.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';

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
    ref.watch(themeAnimationProvider);
    final selectedDocs = ref.watch(selectedDocumentsProvider);
    final hasSelection = selectedDocs.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          // ─── Modern toolbar ───
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              border: Border(
                bottom: BorderSide(color: AppTheme.border.withValues(alpha: 0.5)),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Title row + actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.space20,
                      AppTheme.space12,
                      AppTheme.space12,
                      0,
                    ),
                    child: Row(
                      children: [
                        if (_isSearching)
                          Expanded(
                            child: DocumentSearchBar(
                              onChanged: (query) {
                                ref.read(searchQueryProvider.notifier).state =
                                    query;
                              },
                              onClose: () {
                                setState(() => _isSearching = false);
                                ref.read(searchQueryProvider.notifier).state =
                                    '';
                                final currentFilter =
                                    ref.read(documentFilterProvider);
                                ref
                                    .read(documentFilterProvider.notifier)
                                    .state = currentFilter.clearSearch();
                              },
                            ),
                          )
                        else ...[
                          Expanded(
                            child: Text(
                              'Mes Documents',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                        if (!_isSearching && !hasSelection) ...[
                          _ToolbarIconButton(
                            icon: Icons.search_rounded,
                            tooltip: 'Rechercher',
                            onPressed: () =>
                                setState(() => _isSearching = true),
                          ),
                          const SizedBox(width: AppTheme.space4),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.swap_vert_rounded,
                              color: AppTheme.textSecondary,
                              size: 20,
                            ),
                            tooltip: 'Trier',
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMd,
                              ),
                            ),
                            onSelected: (value) {
                              final sortOption =
                                  DocumentSortOption.values.firstWhere(
                                (e) => e.name == value,
                              );
                              ref.read(documentSortProvider.notifier).state =
                                  sortOption;
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.space12,
                              vertical: AppTheme.space4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusFull,
                              ),
                            ),
                            child: Text(
                              '${selectedDocs.length}',
                              style: TextStyle(
                                color: AppTheme.primaryContent,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppTheme.space8),
                          _ToolbarIconButton(
                            icon: Icons.share_outlined,
                            tooltip: 'Partager',
                            onPressed: () => _shareSelected(),
                          ),
                          _ToolbarIconButton(
                            icon: Icons.delete_outline_rounded,
                            tooltip: 'Supprimer',
                            color: AppTheme.error,
                            onPressed: () => _deleteSelected(),
                          ),
                          _ToolbarIconButton(
                            icon: Icons.close_rounded,
                            tooltip: 'Annuler',
                            onPressed: () {
                              ref
                                  .read(selectedDocumentsProvider.notifier)
                                  .state = {};
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ─── Modern TabBar ───
                  Container(
                    margin: const EdgeInsets.only(top: AppTheme.space8),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primaryContent,
                      unselectedLabelColor: AppTheme.textTertiary,
                      indicatorColor: AppTheme.primaryContent,
                      indicatorWeight: 2.5,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.picture_as_pdf_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('CRI (PDF)'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.table_chart_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Exports (CSV)'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Filtres ───
          const DocumentFilterChips(),

          // ─── Liste des documents ───
          Expanded(
            child: ContentContainer(
              maxWidth: 1400,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDocumentList(DocumentFileType.pdf),
                  _buildDocumentList(DocumentFileType.csv),
                ],
              ),
            ),
          ),
        ],
      ),

      // ─── Modern FAB ───
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showExportOptions(),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Nouveau',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
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
      // ─── Shimmer loading placeholder ───
      loading: () => Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: Column(
          children: List.generate(
            5,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space12),
              child: _ShimmerPlaceholder(delay: index * 100),
            ),
          ),
        ),
      ),
      error: (error, stack) => Center(
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
                  size: 32,
                  color: AppTheme.error,
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              Text(
                'Erreur de chargement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              Text(
                '$error',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space20),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(exportedDocumentsProvider),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Réessayer'),
              ),
            ],
          ),
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

// ─── Toolbar icon button ───
class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      color: color ?? AppTheme.textSecondary,
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
      ),
    );
  }
}

// ─── Shimmer loading placeholder ───
class _ShimmerPlaceholder extends StatefulWidget {
  final int delay;
  const _ShimmerPlaceholder({this.delay = 0});

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    // Stagger animation
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerAnimatedContainer(
      animation: _animation,
    );
  }
}

class _ShimmerAnimatedContainer extends AnimatedWidget {
  const _ShimmerAnimatedContainer({
    required Animation<double> animation,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final double value = (listenable as Animation<double>).value;
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant.withValues(alpha: value),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppTheme.space16),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.border.withValues(alpha: value),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 180,
                  decoration: BoxDecoration(
                    color: AppTheme.border.withValues(alpha: value),
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusSm,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.border.withValues(alpha: value * 0.6),
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusSm,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
