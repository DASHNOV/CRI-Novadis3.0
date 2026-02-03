import 'dart:io';
import 'package:drift/drift.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

import '../../../data/local/app_database.dart';
import '../models/exported_document_model.dart';

/// Service de gestion des fichiers exportés
class FileManagementService {
  final AppDatabase _database;

  FileManagementService(this._database);

  /// Ouvre un fichier avec l'application par défaut du système
  Future<bool> openFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Le fichier n\'existe pas: $filePath');
      }

      final result = await OpenFile.open(filePath);

      // Vérifier le résultat
      if (result.type == ResultType.done) {
        return true;
      } else {
        // Fallback pour Windows : essayer plusieurs méthodes
        if (Platform.isWindows) {
          // 1. Essayer avec explorer
          try {
            final processResult = await Process.run('explorer', [filePath]);
            if (processResult.exitCode <= 1) return true;
          } catch (_) {}

          // 2. Essayer avec cmd start
          try {
            await Process.run('cmd', ['/c', 'start', '""', filePath]);
            return true;
          } catch (_) {}

          // 3. Au pire, ouvrir le dossier contenant le fichier
          try {
            await Process.run('explorer', ['/select,', filePath]);
            return true;
          } catch (_) {}
        }

        // Traduire les erreurs courantes
        String errorMessage;
        switch (result.type) {
          case ResultType.noAppToOpen:
            errorMessage =
                "Aucune application n'est installée pour ouvrir ce type de fichier.";
            break;
          case ResultType.fileNotFound:
            errorMessage = "Le fichier est introuvable.";
            break;
          case ResultType.permissionDenied:
            errorMessage = "Permission refusée.";
            break;
          default:
            errorMessage = result.message;
        }

        throw Exception(errorMessage);
      }
    } catch (e) {
      // Nettoyer le message d'exception pour l'affichage
      final msg = e.toString().replaceAll('Exception: ', '');
      throw Exception(msg);
    }
  }

  /// Partage un fichier via le système de partage natif
  Future<bool> shareFile(
    String filePath, {
    String? subject,
    String? text,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Le fichier n\'existe pas: $filePath');
      }

      final xFile = XFile(filePath);

      await Share.shareXFiles(
        [xFile],
        subject: subject ?? 'Document Novadis',
        text: text ?? 'Voici le document demandé',
      );

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Partage plusieurs fichiers
  Future<bool> shareMultipleFiles(
    List<String> filePaths, {
    String? subject,
    String? text,
  }) async {
    try {
      final xFiles = <XFile>[];

      for (final path in filePaths) {
        final file = File(path);
        if (await file.exists()) {
          xFiles.add(XFile(path));
        }
      }

      if (xFiles.isEmpty) {
        throw Exception('Aucun fichier valide à partager');
      }

      await Share.shareXFiles(
        xFiles,
        subject: subject ?? 'Documents Novadis',
        text: text ?? 'Voici les documents demandés',
      );

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Renomme un fichier et met à jour la base de données
  Future<bool> renameFile(int documentId, String newFilename) async {
    try {
      final document = await _database.getExportedDocumentById(documentId);
      if (document == null) {
        throw Exception('Document non trouvé: $documentId');
      }

      final file = File(document.filePath);
      if (!await file.exists()) {
        throw Exception('Le fichier n\'existe pas: ${document.filePath}');
      }

      // Vérifier que le nouveau nom a la bonne extension
      final extension = p.extension(document.filename);
      var finalFilename = newFilename;
      if (!newFilename.endsWith(extension)) {
        finalFilename = '$newFilename$extension';
      }

      // Nouveau chemin
      final directory = p.dirname(document.filePath);
      final newPath = p.join(directory, finalFilename);

      // Renommer le fichier
      final renamedFile = await file.rename(newPath);

      // Mettre à jour la base de données
      await _database.updateExportedDocument(
        ExportedDocumentTableCompanion(
          id: Value(document.id),
          criId: Value(document.criId),
          filename: Value(finalFilename),
          filePath: Value(renamedFile.path),
          fileType: Value(document.fileType),
          fileSize: Value(document.fileSize),
          exportType: Value(document.exportType),
          metadata: Value(document.metadata),
          createdAt: Value(document.createdAt),
          sharedAt: Value(document.sharedAt),
        ),
      );

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Supprime un fichier et son entrée dans la base de données
  Future<bool> deleteFile(int documentId) async {
    try {
      final document = await _database.getExportedDocumentById(documentId);
      if (document == null) {
        throw Exception('Document non trouvé: $documentId');
      }

      final file = File(document.filePath);

      // Supprimer le fichier s'il existe
      if (await file.exists()) {
        await file.delete();
      }

      // Supprimer l'entrée de la base de données
      await _database.deleteExportedDocument(documentId);

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Supprime plusieurs fichiers
  Future<int> deleteMultipleFiles(List<int> documentIds) async {
    var deletedCount = 0;

    for (final id in documentIds) {
      try {
        final success = await deleteFile(id);
        if (success) deletedCount++;
      } catch (e) {
        // Continuer même si un fichier échoue
        continue;
      }
    }

    return deletedCount;
  }

  /// Vérifie si un fichier existe
  Future<bool> fileExists(String filePath) async {
    final file = File(filePath);
    return await file.exists();
  }

  /// Récupère la taille d'un fichier
  Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return 0;
    }
    return await file.length();
  }

  /// Nettoie les vieux documents (plus de X jours)
  Future<int> cleanupOldDocuments(int daysOld) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      // Récupérer les vieux documents
      final oldDocs = await _database.getAllExportedDocuments();
      final toDelete = oldDocs
          .where((doc) => doc.createdAt.isBefore(cutoffDate))
          .toList();

      var deletedCount = 0;
      for (final doc in toDelete) {
        try {
          await deleteFile(doc.id);
          deletedCount++;
        } catch (e) {
          continue;
        }
      }

      return deletedCount;
    } catch (e) {
      rethrow;
    }
  }

  /// Enregistre un document exporté dans la base de données
  Future<int> registerExportedDocument({
    required File file,
    required DocumentFileType fileType,
    required ExportType exportType,
    String? criId,
    Map<String, dynamic>? metadata,
  }) async {
    final fileSize = await file.length();
    final filename = p.basename(file.path);

    final documentId = await _database.insertExportedDocument(
      ExportedDocumentTableCompanion.insert(
        criId: Value(criId),
        filename: filename,
        filePath: file.path,
        fileType: fileType.name,
        fileSize: fileSize,
        exportType: exportType.name,
        metadata: Value(metadata?.toString()),
        createdAt: DateTime.now(),
      ),
    );

    return documentId;
  }

  /// Met à jour la date de partage d'un document
  Future<void> markAsShared(int documentId) async {
    await _database.updateSharedAt(documentId, DateTime.now());
  }

  /// Récupère les informations d'un fichier
  Future<FileInfo> getFileInfo(String filePath) async {
    final file = File(filePath);

    if (!await file.exists()) {
      throw Exception('Le fichier n\'existe pas: $filePath');
    }

    final stat = await file.stat();

    return FileInfo(
      path: filePath,
      name: p.basename(filePath),
      size: stat.size,
      modified: stat.modified,
      extension: p.extension(filePath),
    );
  }
}

/// Informations sur un fichier
class FileInfo {
  final String path;
  final String name;
  final int size;
  final DateTime modified;
  final String extension;

  FileInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.modified,
    required this.extension,
  });

  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
