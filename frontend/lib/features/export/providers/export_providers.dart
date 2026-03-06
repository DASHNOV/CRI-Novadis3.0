import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../data/local/app_database.dart';
import '../models/exported_document_model.dart';
import '../services/base_service_interfaces.dart';
import '../services/service_factory.dart' as serviceFactory;

// ============================================================
// Providers de services
// ============================================

/// Provider pour la base de données
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Provider pour le service PDF
final pdfGeneratorServiceProvider = Provider<BasePdfGeneratorService>((ref) {
  final database = ref.watch(databaseProvider);
  return serviceFactory.getPdfService(database);
});

/// Provider pour le service CSV Dashboard
final dashboardCsvServiceProvider = Provider<BaseDashboardCsvService>((ref) {
  final database = ref.watch(databaseProvider);
  return serviceFactory.getDashboardCsvService(database);
});

/// Provider pour le service CSV Technicien
final technicianStatsCsvServiceProvider = Provider<BaseTechnicianStatsCsvService>((
  ref,
) {
  final database = ref.watch(databaseProvider);
  return serviceFactory.getTechnicianStatsService(database);
});

/// Provider pour le service de gestion de fichiers
final fileManagementServiceProvider = Provider<BaseFileManagementService>((ref) {
  final database = ref.watch(databaseProvider);
  return serviceFactory.getFileService(database);
});

// ============================================================
// Providers de données
// ============================================================

/// Provider pour tous les documents exportés
final exportedDocumentsProvider = FutureProvider<List<ExportedDocument>>((
  ref,
) async {
  if (kIsWeb) return []; // Pas de documents locaux sur le web
  final database = ref.watch(databaseProvider);
  return await database.getAllExportedDocuments();
});

/// Provider pour les documents filtrés
final filteredDocumentsProvider =
    FutureProvider.family<List<ExportedDocument>, DocumentFilter>((
      ref,
      filter,
    ) async {
      if (kIsWeb) return [];
      // Utiliser le provider principal comme source de vérité pour que l'invalidation fonctionne
      final documentsSource = await ref.watch(exportedDocumentsProvider.future);
      // Créer une nouvelle liste pour éviter de modifier la source
      var documents = List<ExportedDocument>.from(documentsSource);

      // Appliquer les filtres
      if (filter.fileType != null) {
        documents = documents
            .where((doc) => doc.fileType == filter.fileType!.name)
            .toList();
      }

      if (filter.exportType != null) {
        documents = documents
            .where((doc) => doc.exportType == filter.exportType!.name)
            .toList();
      }

      if (filter.startDate != null && filter.endDate != null) {
        documents = documents.where((doc) {
          return doc.createdAt.isAfter(filter.startDate!) &&
              doc.createdAt.isBefore(
                filter.endDate!.add(const Duration(days: 1)),
              );
        }).toList();
      }

      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase();
        documents = documents.where((doc) {
          return doc.filename.toLowerCase().contains(query) ||
              (doc.metadata?.toLowerCase().contains(query) ?? false);
        }).toList();
      }

      return documents;
    });

/// Provider pour les documents PDF uniquement
final pdfDocumentsProvider = FutureProvider<List<ExportedDocument>>((
  ref,
) async {
  if (kIsWeb) return [];
  final database = ref.watch(databaseProvider);
  return await database.getExportedDocumentsByType('pdf');
});

/// Provider pour les documents CSV uniquement
final csvDocumentsProvider = FutureProvider<List<ExportedDocument>>((
  ref,
) async {
  if (kIsWeb) return [];
  final database = ref.watch(databaseProvider);
  return await database.getExportedDocumentsByType('csv');
});

/// Provider pour les documents d'un CRI spécifique
final criDocumentsProvider =
    FutureProvider.family<List<ExportedDocument>, String>((ref, criId) async {
      if (kIsWeb) return [];
      final database = ref.watch(databaseProvider);
      return await database.getExportedDocumentsByCriId(criId);
    });

// ============================================================
// Providers d'état
// ============================================================

/// État du filtre actuel
final documentFilterProvider = StateProvider<DocumentFilter>(
  (ref) => const DocumentFilter(),
);

/// Option de tri actuelle
final documentSortProvider = StateProvider<DocumentSortOption>(
  (ref) => DocumentSortOption.newestFirst,
);

/// Documents sélectionnés (pour actions multiples)
final selectedDocumentsProvider = StateProvider<Set<int>>((ref) => {});

/// État de l'export en cours
final exportProgressProvider = StateProvider<ExportProgress?>((ref) => null);

/// Recherche active - Synchronisé avec le filtre
final searchQueryProvider = StateProvider<String>((ref) {
  // Écouter les changements et mettre à jour le filtre
  ref.listenSelf((previous, next) {
    if (previous != next) {
      final currentFilter = ref.read(documentFilterProvider);
      ref.read(documentFilterProvider.notifier).state = currentFilter.copyWith(
        searchQuery: next,
      );
    }
  });
  return '';
});

// ============================================================
// Providers d'actions
// ============================================================

/// Provider pour générer un PDF CRI
final generateCriPdfProvider = FutureProvider.family<dynamic, String>((
  ref,
  criId,
) async {
  if (kIsWeb) {
    throw Exception('La génération PDF n\'est pas disponible sur le Web');
  }
  
  final service = ref.watch(pdfGeneratorServiceProvider);
  final database = ref.watch(databaseProvider);

  // Mettre à jour le progrès
  Future.microtask(() {
    ref.read(exportProgressProvider.notifier).state = ExportProgress(
      type: 'PDF',
      status: 'Recherche du rapport...',
      progress: 0.1,
    );
  });

  try {
    dynamic file;

    // 1. Chercher dans CRI Service
    final serviceCri = await database.getCriServiceById(criId);
    if (serviceCri != null) {
      Future.microtask(() {
        ref.read(exportProgressProvider.notifier).state = ExportProgress(
          type: 'PDF',
          status: 'Génération CRI Service...',
          progress: 0.5,
        );
      });
      file = await service.generateCriServicePDF(criId);
    }

    // 2. Si non trouvé, chercher dans CRI Projet
    if (file == null) {
      final projetCri = await database.getCriProjetById(criId);
      if (projetCri != null) {
        Future.microtask(() {
          ref.read(exportProgressProvider.notifier).state = ExportProgress(
            type: 'PDF',
            status: 'Génération CRI Projet...',
            progress: 0.5,
          );
        });
        file = await service.generateCriProjetPDF(criId);
      }
    }

    if (file == null) {
      throw Exception('Rapport non trouvé (ID: $criId)');
    }

    // Enregistrer dans la base de données
    final fileService = ref.watch(fileManagementServiceProvider);
    await fileService.registerExportedDocument(
      file: file,
      fileType: DocumentFileType.pdf,
      exportType: ExportType.cri,
      criId: criId,
    );

    // Réinitialiser le progrès
    ref.read(exportProgressProvider.notifier).state = ExportProgress(
      type: 'PDF',
      status: 'Terminé',
      progress: 1.0,
    );

    // Rafraîchir la liste des documents
    ref.invalidate(exportedDocumentsProvider);

    return file;
  } catch (e) {
    ref.read(exportProgressProvider.notifier).state = ExportProgress(
      type: 'PDF',
      status: 'Erreur: $e',
      progress: 0.0,
      hasError: true,
    );
    rethrow;
  }
});

/// Provider pour exporter les interventions en CSV
final exportInterventionsCsvProvider =
    FutureProvider.family<dynamic, ({DateTime startDate, DateTime endDate})>((
      ref,
      params,
    ) async {
      if (kIsWeb) {
        throw Exception('L\'export CSV n\'est pas disponible sur le Web');
      }
      final service = ref.watch(dashboardCsvServiceProvider);

      Future.microtask(() {
        ref.read(exportProgressProvider.notifier).state = ExportProgress(
          type: 'CSV',
          status: 'Export des interventions...',
          progress: 0.5,
        );
      });

      try {
        final file = await service.exportInterventions(
          startDate: params.startDate,
          endDate: params.endDate,
        );

        final fileService = ref.watch(fileManagementServiceProvider);
        await fileService.registerExportedDocument(
          file: file,
          fileType: DocumentFileType.csv,
          exportType: ExportType.dashboard,
          metadata: {
            'startDate': params.startDate.toIso8601String(),
            'endDate': params.endDate.toIso8601String(),
          },
        );

        ref.read(exportProgressProvider.notifier).state = ExportProgress(
          type: 'CSV',
          status: 'Terminé',
          progress: 1.0,
        );

        ref.invalidate(exportedDocumentsProvider);

        return file;
      } catch (e) {
        ref.read(exportProgressProvider.notifier).state = ExportProgress(
          type: 'CSV',
          status: 'Erreur: $e',
          progress: 0.0,
          hasError: true,
        );
        rethrow;
      }
    });

/// Provider pour exporter la synthèse KPI en CSV
final exportKPICsvProvider =
    FutureProvider.family<dynamic, ({DateTime startDate, DateTime endDate})>((
      ref,
      params,
    ) async {
      if (kIsWeb) {
        throw Exception('L\'export CSV n\'est pas disponible sur le Web');
      }
      final service = ref.watch(dashboardCsvServiceProvider);

      Future.microtask(() {
        ref.read(exportProgressProvider.notifier).state = ExportProgress(
          type: 'CSV',
          status: 'Export synthèse KPI...',
          progress: 0.5,
        );
      });

      try {
        final file = await service.exportKPISynthesis(
          startDate: params.startDate,
          endDate: params.endDate,
        );

        final fileService = ref.watch(fileManagementServiceProvider);
        await fileService.registerExportedDocument(
          file: file,
          fileType: DocumentFileType.csv,
          exportType: ExportType.dashboard,
          metadata: {
            'type': 'KPI',
            'startDate': params.startDate.toIso8601String(),
            'endDate': params.endDate.toIso8601String(),
          },
        );

        ref.read(exportProgressProvider.notifier).state = ExportProgress(
          type: 'CSV',
          status: 'Terminé',
          progress: 1.0,
        );

        ref.invalidate(exportedDocumentsProvider);

        return file;
      } catch (e) {
        ref.read(exportProgressProvider.notifier).state = ExportProgress(
          type: 'CSV',
          status: 'Erreur: $e',
          progress: 0.0,
          hasError: true,
        );
        rethrow;
      }
    });

/// Provider pour exporter le top sites en CSV
final exportTopSitesCsvProvider =
    FutureProvider.family<dynamic, ({DateTime startDate, DateTime endDate})>((
      ref,
      params,
    ) async {
      if (kIsWeb) {
        throw Exception('L\'export CSV n\'est pas disponible sur le Web');
      }
      final service = ref.watch(dashboardCsvServiceProvider);

      Future.microtask(() {
        ref.read(exportProgressProvider.notifier).state = ExportProgress(
          type: 'CSV',
          status: 'Export top sites...',
          progress: 0.5,
        );
      });

      try {
        final file = await service.exportTopSites(
          startDate: params.startDate,
          endDate: params.endDate,
        );

        final fileService = ref.watch(fileManagementServiceProvider);
        await fileService.registerExportedDocument(
          file: file,
          fileType: DocumentFileType.csv,
          exportType: ExportType.dashboard,
          metadata: {
            'type': 'TopSites',
            'startDate': params.startDate.toIso8601String(),
            'endDate': params.endDate.toIso8601String(),
          },
        );

        ref.read(exportProgressProvider.notifier).state = ExportProgress(
          type: 'CSV',
          status: 'Terminé',
          progress: 1.0,
        );

        ref.invalidate(exportedDocumentsProvider);

        return file;
      } catch (e) {
        ref.read(exportProgressProvider.notifier).state = ExportProgress(
          type: 'CSV',
          status: 'Erreur: $e',
          progress: 0.0,
          hasError: true,
        );
        rethrow;
      }
    });

/// Provider pour exporter tout le dashboard en CSV
final exportAllDashboardCsvProvider =
    FutureProvider.family<List<dynamic>, ({DateTime startDate, DateTime endDate})>(
      (ref, params) async {
        if (kIsWeb) {
          throw Exception('L\'export CSV n\'est pas disponible sur le Web');
        }
        final service = ref.watch(dashboardCsvServiceProvider);

        Future.microtask(() {
          ref.read(exportProgressProvider.notifier).state = ExportProgress(
            type: 'CSV',
            status: 'Export complet du dashboard...',
            progress: 0.3,
          );
        });

        try {
          final files = await service.exportAll(
            startDate: params.startDate,
            endDate: params.endDate,
          );

          final fileService = ref.watch(fileManagementServiceProvider);

          for (final file in files) {
            await fileService.registerExportedDocument(
              file: file,
              fileType: DocumentFileType.csv,
              exportType: ExportType.dashboard,
              metadata: {
                'type': 'All',
                'startDate': params.startDate.toIso8601String(),
                'endDate': params.endDate.toIso8601String(),
              },
            );
          }

          ref.read(exportProgressProvider.notifier).state = ExportProgress(
            type: 'CSV',
            status: 'Terminé',
            progress: 1.0,
          );

          ref.invalidate(exportedDocumentsProvider);

          return files;
        } catch (e) {
          ref.read(exportProgressProvider.notifier).state = ExportProgress(
            type: 'CSV',
            status: 'Erreur: $e',
            progress: 0.0,
            hasError: true,
          );
          rethrow;
        }
      },
    );

/// Provider pour exporter les stats technicien en CSV
final exportTechnicianStatsCsvProvider =
    FutureProvider.family<
      dynamic,
      ({String technicianName, DateTime startDate, DateTime endDate})
    >((ref, params) async {
      if (kIsWeb) {
        throw Exception('L\'export CSV n\'est pas disponible sur le Web');
      }
      final service = ref.watch(technicianStatsCsvServiceProvider);

      Future.microtask(() {
        ref.read(exportProgressProvider.notifier).state = ExportProgress(
          type: 'CSV',
          status: 'Export des statistiques...',
          progress: 0.5,
        );
      });

      try {
        final file = await service.exportTechnicianStats(
          technicianName: params.technicianName,
          startDate: params.startDate,
          endDate: params.endDate,
        );

        final fileService = ref.watch(fileManagementServiceProvider);
        await fileService.registerExportedDocument(
          file: file,
          fileType: DocumentFileType.csv,
          exportType: ExportType.technician,
          metadata: {
            'technicianName': params.technicianName,
            'startDate': params.startDate.toIso8601String(),
            'endDate': params.endDate.toIso8601String(),
          },
        );

        ref.read(exportProgressProvider.notifier).state = ExportProgress(
          type: 'CSV',
          status: 'Terminé',
          progress: 1.0,
        );

        ref.invalidate(exportedDocumentsProvider);

        return file;
      } catch (e) {
        ref.read(exportProgressProvider.notifier).state = ExportProgress(
          type: 'CSV',
          status: 'Erreur: $e',
          progress: 0.0,
          hasError: true,
        );
        rethrow;
      }
    });

// ============================================================
// Modèles
// ============================================================

/// Progrès d'un export
class ExportProgress {
  final String type;
  final String status;
  final double progress;
  final bool hasError;

  ExportProgress({
    required this.type,
    required this.status,
    required this.progress,
    this.hasError = false,
  });
}
