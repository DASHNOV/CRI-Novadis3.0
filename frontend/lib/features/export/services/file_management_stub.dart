import '../../../data/local/app_database.dart';
import '../models/exported_document_model.dart';

abstract class BaseFileManagementService {
  Future<bool> openFile(String filePath);
  Future<bool> shareFile(String filePath, {String? subject, String? text});
  Future<bool> shareMultipleFiles(List<String> filePaths, {String? subject, String? text});
  Future<bool> deleteFile(int documentId);
  Future<int> deleteMultipleFiles(List<int> documentIds);
  Future<bool> renameFile(int documentId, String newFilename);
  Future<void> markAsShared(int documentId);
  Future<int> registerExportedDocument({
    required dynamic file,
    required DocumentFileType fileType,
    required ExportType exportType,
    String? criId,
    Map<String, dynamic>? metadata,
  });
}

BaseFileManagementService createFileService(AppDatabase db) => throw UnimplementedError();
