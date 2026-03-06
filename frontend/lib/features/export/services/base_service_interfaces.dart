import '../../../data/local/app_database.dart';
import '../models/exported_document_model.dart';

abstract class BasePdfGeneratorService {
  Future<dynamic> generateCriServicePDF(String criId);
  Future<dynamic> generateCriProjetPDF(String criId);
}

abstract class BaseDashboardCsvService {
  Future<dynamic> exportInterventions({
    required DateTime startDate,
    required DateTime endDate,
    String? interventionType,
    String? status,
  });
  Future<dynamic> exportKPISynthesis({required DateTime startDate, required DateTime endDate});
  Future<dynamic> exportTopSites({required DateTime startDate, required DateTime endDate, int limit = 10});
  Future<List<dynamic>> exportAll({required DateTime startDate, required DateTime endDate});
}

abstract class BaseTechnicianStatsCsvService {
  Future<dynamic> exportTechnicianStats({
    required String technicianName,
    required DateTime startDate,
    required DateTime endDate,
  });
}

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
