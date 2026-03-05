import 'dart:io';
import 'package:drift/drift.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;

import '../../../data/local/app_database.dart';
import '../models/exported_document_model.dart';
import 'file_management_stub.dart';

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
  Future<bool> deleteFile(int documentId) async {
    final document = await _database.getExportedDocumentById(documentId);
    if (document == null) return false;
    final file = File(document.filePath);
    if (await file.exists()) await file.delete();
    await _database.deleteExportedDocument(documentId);
    return true;
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

BaseFileManagementService createFileService(AppDatabase db) => FileManagementService(db);
