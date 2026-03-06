import '../../../data/local/app_database.dart';
import '../models/exported_document_model.dart';
import 'base_service_interfaces.dart';

class FileManagementService implements BaseFileManagementService {
  final AppDatabase _database;
  FileManagementService(this._database);

  @override
  Future<bool> openFile(String filePath) async => throw UnimplementedError();

  @override
  Future<bool> shareFile(String filePath, {String? subject, String? text}) async => throw UnimplementedError();

  @override
  Future<bool> shareMultipleFiles(List<String> filePaths, {String? subject, String? text}) async => throw UnimplementedError();

  @override
  Future<bool> deleteFile(int documentId) async => throw UnimplementedError();

  @override
  Future<int> deleteMultipleFiles(List<int> documentIds) async => throw UnimplementedError();

  @override
  Future<bool> renameFile(int documentId, String newFilename) async => throw UnimplementedError();

  @override
  Future<void> markAsShared(int documentId) async => throw UnimplementedError();

  @override
  Future<int> registerExportedDocument({
    required dynamic file,
    required DocumentFileType fileType,
    required ExportType exportType,
    String? criId,
    Map<String, dynamic>? metadata,
  }) async => throw UnimplementedError();
}

