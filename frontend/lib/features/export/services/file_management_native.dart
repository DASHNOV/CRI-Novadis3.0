import 'dart:io';
import 'package:drift/drift.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../data/local/app_database.dart';
import '../models/exported_document_model.dart';
import 'base_service_interfaces.dart';

/// Service de gestion des fichiers exportés (Version Native)
class FileManagementService implements BaseFileManagementService {
  final AppDatabase _database;

  FileManagementService(this._database);

  @override
  Future<bool> openFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Le fichier n\'existe pas: $filePath');
      }

      final result = await OpenFile.open(filePath);

      if (result.type == ResultType.done) {
        return true;
      } else {
        if (Platform.isWindows) {
          try {
            final processResult = await Process.run('explorer', [filePath]);
            if (processResult.exitCode <= 1) return true;
          } catch (_) {}
          try {
            await Process.run('cmd', ['/c', 'start', '""', filePath]);
            return true;
          } catch (_) {}
        }
        throw Exception(result.message);
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<bool> shareFile(String filePath, {String? subject, String? text}) async {
    final file = File(filePath);
    if (!await file.exists()) throw Exception('Fichier non trouvé');
    await Share.shareXFiles([XFile(filePath)], subject: subject, text: text);
    return true;
  }

  @override
  Future<bool> shareMultipleFiles(List<String> filePaths, {String? subject, String? text}) async {
    final xFiles = <XFile>[];
    for (final path in filePaths) {
      if (await File(path).exists()) xFiles.add(XFile(path));
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
    
    final file = File(document.filePath);
    final extension = p.extension(document.filename);
    var finalName = newFilename.endsWith(extension) ? newFilename : '$newFilename$extension';
    
    final newPath = p.join(p.dirname(document.filePath), finalName);
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
    if (file is! File) throw Exception('File must be a dart:io File on native');
    final fileSize = await file.length();
    final filename = p.basename(file.path);

    return await _database.insertExportedDocument(
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
  }
}


