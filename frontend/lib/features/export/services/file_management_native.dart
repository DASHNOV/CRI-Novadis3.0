import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../data/local/app_database.dart';
import '../models/exported_document_model.dart';
import 'base_service_interfaces.dart';

/// Service de gestion des fichiers exportés (Version Native)
class FileManagementService implements BaseFileManagementService {
  final AppDatabase _database;

  FileManagementService(this._database);

  /// Résout le chemin réel d'un fichier.
  /// Si le chemin stocké ne fonctionne pas, cherche par nom de fichier
  /// dans les dossiers d'export connus.
  Future<String> _resolveFilePath(String storedPath) async {
    // 1. Essayer le chemin tel quel
    if (await File(storedPath).exists()) return storedPath;

    // 2. Essayer de résoudre les symlinks du dossier parent
    final filename = p.basename(storedPath);
    final output = await getApplicationDocumentsDirectory();

    // 3. Chercher dans les dossiers d'export connus
    final searchDirs = [
      p.join(output.path, 'Novadis', 'CRI'),
      p.join(output.path, 'Novadis', 'Exports', 'Dashboard'),
      p.join(output.path, 'Novadis', 'Exports', 'Techniciens'),
    ];

    for (final dirPath in searchDirs) {
      final dir = Directory(dirPath);
      if (!await dir.exists()) continue;

      // Cherche exact match par nom
      final candidate = File(p.join(dirPath, filename));
      if (await candidate.exists()) {
        debugPrint('[FileManagement] Fichier trouvé via fallback: ${candidate.path}');
        return candidate.path;
      }

      // Cherche par listing du répertoire (cas de noms légèrement différents)
      try {
        await for (final entity in dir.list()) {
          if (entity is File && p.basename(entity.path) == filename) {
            debugPrint('[FileManagement] Fichier trouvé via listing: ${entity.path}');
            return entity.path;
          }
        }
      } catch (e) {
        debugPrint('[FileManagement] Erreur listing $dirPath: $e');
      }
    }

    // 4. Diagnostic: lister ce qui existe réellement
    final diagLines = <String>[];
    diagLines.add('Chemin stocké: $storedPath');
    diagLines.add('Documents dir: ${output.path}');
    for (final dirPath in searchDirs) {
      final dir = Directory(dirPath);
      if (await dir.exists()) {
        try {
          final files = await dir.list().toList();
          diagLines.add('$dirPath (${files.length} fichiers):');
          for (final f in files.take(10)) {
            diagLines.add('  - ${p.basename(f.path)}');
          }
        } catch (e) {
          diagLines.add('$dirPath: erreur listing: $e');
        }
      } else {
        diagLines.add('$dirPath: N\'EXISTE PAS');
      }
    }

    final diagnostic = diagLines.join('\n');
    debugPrint('[FileManagement] DIAGNOSTIC FICHIER NON TROUVÉ:\n$diagnostic');

    throw Exception('Fichier introuvable: $filename\n\nDiagnostic:\n$diagnostic');
  }

  @override
  Future<bool> openFile(String filePath) async {
    try {
      final resolvedPath = await _resolveFilePath(filePath);

      final result = await OpenFilex.open(resolvedPath);

      if (result.type == ResultType.done) {
        return true;
      } else {
        if (Platform.isWindows) {
          try {
            final processResult = await Process.run('explorer', [resolvedPath]);
            if (processResult.exitCode <= 1) return true;
          } catch (_) {}
          try {
            await Process.run('cmd', ['/c', 'start', '""', resolvedPath]);
            return true;
          } catch (_) {}
        }
        throw Exception('Impossible d\'ouvrir le fichier: ${result.message}');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<bool> shareFile(String filePath, {String? subject, String? text}) async {
    final resolvedPath = await _resolveFilePath(filePath);
    await Share.shareXFiles([XFile(resolvedPath)], subject: subject, text: text);
    return true;
  }

  @override
  Future<bool> shareMultipleFiles(List<String> filePaths, {String? subject, String? text}) async {
    final xFiles = <XFile>[];
    for (final path in filePaths) {
      try {
        final resolved = await _resolveFilePath(path);
        xFiles.add(XFile(resolved));
      } catch (_) {}
    }
    if (xFiles.isEmpty) throw Exception('Aucun fichier à partager');
    await Share.shareXFiles(xFiles, subject: subject, text: text);
    return true;
  }

  @override
  Future<bool> deleteFile(int documentId) async {
    final document = await _database.getExportedDocumentById(documentId);
    if (document == null) return false;
    final file = File(document.filePath);
    if (await file.exists()) await file.delete();
    await _database.deleteExportedDocument(documentId);
    return true;
  }

  @override
  Future<int> deleteMultipleFiles(List<int> documentIds) async {
    int count = 0;
    for (final id in documentIds) {
      if (await deleteFile(id)) count++;
    }
    return count;
  }

  @override
  Future<bool> renameFile(int documentId, String newFilename) async {
    final document = await _database.getExportedDocumentById(documentId);
    if (document == null) return false;

    final actualPath = await _resolveFilePath(document.filePath);

    final file = File(actualPath);
    final extension = p.extension(document.filename);
    var finalName = newFilename.endsWith(extension) ? newFilename : '$newFilename$extension';

    final newPath = p.join(p.dirname(actualPath), finalName);
    final renamedFile = await file.rename(newPath);

    await _database.updateExportedDocument(
      ExportedDocumentTableCompanion(
        id: Value(document.id),
        filename: Value(finalName),
        filePath: Value(renamedFile.path),
      ),
    );
    return true;
  }

  @override
  Future<void> markAsShared(int documentId) async {
    await _database.updateSharedAt(documentId, DateTime.now());
  }

  @override
  Future<int> registerExportedDocument({
    required dynamic file,
    required DocumentFileType fileType,
    required ExportType exportType,
    String? criId,
    Map<String, dynamic>? metadata,
  }) async {
    final File typedFile = file as File;
    final fileSize = await typedFile.length();
    final filename = p.basename(typedFile.path);
    final storedPath = typedFile.path;

    debugPrint('[FileManagement] registerExportedDocument:');
    debugPrint('  path: $storedPath');
    debugPrint('  filename: $filename');
    debugPrint('  size: $fileSize bytes');
    debugPrint('  exists: ${await typedFile.exists()}');

    return await _database.insertExportedDocument(
      ExportedDocumentTableCompanion.insert(
        criId: Value(criId),
        filename: filename,
        filePath: storedPath,
        fileType: fileType.name,
        fileSize: fileSize,
        exportType: exportType.name,
        metadata: Value(metadata?.toString()),
        createdAt: DateTime.now(),
      ),
    );
  }
}
