import '../../../data/local/app_database.dart';
import '../models/exported_document_model.dart';
import 'file_management_stub.dart';

class FileManagementService implements BaseFileManagementService {
  final AppDatabase _database;
  FileManagementService(this._database);

  @override
  Future<bool> openFile(String filePath) async => throw UnimplementedError();

  @override
  Future<bool> shareFile(String filePath, {String? subject, String? text}) async => throw UnimplementedError();

  @override
  Future<bool> deleteFile(int documentId) async => throw UnimplementedError();

  @override
  Future<int> registerExportedDocument({
    required dynamic file,
    required DocumentFileType fileType,
    required ExportType exportType,
    String? criId,
    Map<String, dynamic>? metadata,
  }) async => throw UnimplementedError();
}

BaseFileManagementService createFileService(AppDatabase db) => FileManagementService(db);
