import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/app_database.dart';
import '../../../data/local/local_storage_service.dart';
import '../../../data/models/cri_service_model.dart';
import '../../../data/models/cri_projet_model.dart';
import '../../../data/repositories/cri_remote_repository.dart';
import '../../export/providers/export_providers.dart';
import '../../export/models/exported_document_model.dart';

/// Modèle unifié pour les rapports d'intervention (CRI)
class CriReportModel {
  final String id;
  final String clientName;
  final String siteName;
  final String nIntervention;
  final DateTime date;
  final bool isProjet;

  CriReportModel({
    required this.id,
    required this.clientName,
    required this.siteName,
    required this.nIntervention,
    required this.date,
    required this.isProjet,
  });
}

/// Provider pour récupérer tous les rapports d'intervention disponibles (Service, Projet et Mock)
/// Charge d'abord depuis le serveur (source de vérité), puis complète avec la DB locale.
final availableReportsProvider = FutureProvider<List<CriReportModel>>((
  ref,
) async {
  final database = ref.watch(databaseProvider);
  final localStorage = LocalStorageService();
  final remoteRepo = ref.watch(criRemoteRepositoryProvider);

  // CRI récupérés directement depuis le serveur (fallback si DB locale indisponible)
  final List<CriReportModel> serverReports = [];

  // 1. Synchroniser depuis le serveur (non-bloquant si erreur)
  try {
    final serverCris = await remoteRepo.getAllCris();
    for (final cri in serverCris) {
      // Collecter directement pour le fallback
      try {
        if (cri is CriServiceModel && !cri.isDraft) {
          serverReports.add(CriReportModel(
            id: cri.id,
            clientName: cri.clientName,
            siteName: cri.site,
            nIntervention: cri.ticketNumber,
            date: cri.interventionDate,
            isProjet: false,
          ));
        } else if (cri is CriProjetModel && !cri.isDraft) {
          serverReports.add(CriReportModel(
            id: cri.id,
            clientName: cri.clientName,
            siteName: cri.site,
            nIntervention: cri.projectNumber,
            date: cri.interventionDate,
            isProjet: true,
          ));
        }
      } catch (_) {}

      // Persister en DB locale
      try {
        if (cri is CriServiceModel) {
          await database.updateCriService(cri.toDb());
        } else if (cri is CriProjetModel) {
          await database.updateCriProjet(cri.toDb());
        }
      } catch (e) {
        debugPrint('[Sync] Erreur upsert CRI ${(cri as dynamic).id}: $e');
      }
    }
  } catch (e) {
    debugPrint('[Sync] Impossible de charger les CRI depuis le serveur: $e');
  }

  // 2. Lire depuis la DB locale (maintenant à jour avec les données serveur)
  // Si la DB WASM échoue en production, on utilise les données serveur directement.
  List<CriService> serviceReports = [];
  List<CriProjet> projetReports = [];
  try {
    serviceReports = await (database.select(
      database.criServiceTable,
    )..where((tbl) => tbl.isDraft.equals(false))).get();
    projetReports = await (database.select(
      database.criProjetTable,
    )..where((tbl) => tbl.isDraft.equals(false))).get();
  } catch (e) {
    debugPrint('[DB] Erreur lecture DB locale, utilisation des données serveur: $e');
    // Fallback : utiliser directement les données serveur
    final allReports = List<CriReportModel>.from(serverReports);
    allReports.sort((a, b) => b.date.compareTo(a.date));
    return allReports;
  }
  final legacyReports = await localStorage.getAllCri();

  final List<CriReportModel> allReports = [];
  final Set<String> seenIds = {};

  for (final report in serviceReports) {
    if (seenIds.add(report.id)) {
      allReports.add(
        CriReportModel(
          id: report.id,
          clientName: report.clientName,
          siteName: report.site,
          nIntervention: report.ticketNumber ?? '',
          date: report.interventionDate,
          isProjet: false,
        ),
      );
    }
  }

  for (final report in projetReports) {
    if (seenIds.add(report.id)) {
      allReports.add(
        CriReportModel(
          id: report.id,
          clientName: report.clientName,
          siteName: report.site,
          nIntervention: report.projectNumber,
          date: report.interventionDate,
          isProjet: true,
        ),
      );
    }
  }

  for (final report in legacyReports) {
    if (seenIds.add(report.id)) {
      allReports.add(
        CriReportModel(
          id: report.id,
          clientName: report.client,
          siteName: report.site,
          nIntervention: 'CRI-${report.id}',
          date: report.date,
          isProjet: false,
        ),
      );
    }
  }

  allReports.sort((a, b) => b.date.compareTo(a.date));
  return allReports;
});

/// Provider pour les documents groupés par date
final documentsGroupedByDateProvider =
    FutureProvider<Map<String, List<ExportedDocumentModel>>>((ref) async {
      final documentsAsync = await ref.watch(exportedDocumentsProvider.future);

      final Map<String, List<ExportedDocumentModel>> grouped = {
        'Aujourd\'hui': [],
        'Hier': [],
        'Cette semaine': [],
        'Ce mois': [],
        'Plus ancien': [],
      };

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final weekAgo = today.subtract(const Duration(days: 7));
      final monthAgo = DateTime(now.year, now.month - 1, now.day);

      for (final doc in documentsAsync) {
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

        final docDate = DateTime(
          doc.createdAt.year,
          doc.createdAt.month,
          doc.createdAt.day,
        );

        if (docDate == today) {
          grouped['Aujourd\'hui']!.add(model);
        } else if (docDate == yesterday) {
          grouped['Hier']!.add(model);
        } else if (docDate.isAfter(weekAgo)) {
          grouped['Cette semaine']!.add(model);
        } else if (docDate.isAfter(monthAgo)) {
          grouped['Ce mois']!.add(model);
        } else {
          grouped['Plus ancien']!.add(model);
        }
      }

      // Supprimer les groupes vides
      grouped.removeWhere((key, value) => value.isEmpty);

      return grouped;
    });

/// Provider pour les statistiques des documents
final documentStatsProvider = FutureProvider<DocumentStats>((ref) async {
  final documents = await ref.watch(exportedDocumentsProvider.future);

  var totalSize = 0;
  var pdfCount = 0;
  var csvCount = 0;
  var sharedCount = 0;

  for (final doc in documents) {
    totalSize += doc.fileSize;
    if (doc.fileType.toLowerCase() == 'pdf') {
      pdfCount++;
    } else if (doc.fileType.toLowerCase() == 'csv') {
      csvCount++;
    }
    if (doc.sharedAt != null) {
      sharedCount++;
    }
  }

  return DocumentStats(
    totalDocuments: documents.length,
    totalSize: totalSize,
    pdfCount: pdfCount,
    csvCount: csvCount,
    sharedCount: sharedCount,
  );
});

/// Statistiques des documents
class DocumentStats {
  final int totalDocuments;
  final int totalSize;
  final int pdfCount;
  final int csvCount;
  final int sharedCount;

  DocumentStats({
    required this.totalDocuments,
    required this.totalSize,
    required this.pdfCount,
    required this.csvCount,
    required this.sharedCount,
  });

  String get formattedTotalSize {
    if (totalSize < 1024) {
      return '$totalSize B';
    } else if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
