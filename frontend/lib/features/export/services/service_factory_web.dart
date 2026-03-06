import '../../../data/local/app_database.dart';
import '../models/exported_document_model.dart';
import 'base_service_interfaces.dart';

// Isolation totale : pas d'imports des fichiers _web.dart qui pourraient référencer indirectement du code natif
// On définit des implémentations "no-op" directement ici pour le Web.

class WebPdfGeneratorService implements BasePdfGeneratorService {
  WebPdfGeneratorService(AppDatabase db);
  @override
  Future<dynamic> generateCriServicePDF(String criId) async => throw UnimplementedError();
  @override
  Future<dynamic> generateCriProjetPDF(String criId) async => throw UnimplementedError();
}

class WebDashboardCsvService implements BaseDashboardCsvService {
  WebDashboardCsvService(AppDatabase db);
  @override
  Future<dynamic> exportInterventions({required DateTime startDate, required DateTime endDate, String? interventionType, String? status}) async => throw UnimplementedError();
  @override
  Future<dynamic> exportKPISynthesis({required DateTime startDate, required DateTime endDate}) async => throw UnimplementedError();
  @override
  Future<dynamic> exportTopSites({required DateTime startDate, required DateTime endDate, int limit = 10}) async => throw UnimplementedError();
  @override
  Future<List<dynamic>> exportAll({required DateTime startDate, required DateTime endDate}) async => throw UnimplementedError();
}

class WebTechnicianStatsCsvService implements BaseTechnicianStatsCsvService {
  WebTechnicianStatsCsvService(AppDatabase db);
  @override
  Future<dynamic> exportTechnicianStats({required String technicianName, required DateTime startDate, required DateTime endDate}) async => throw UnimplementedError();
}

class WebFileManagementService implements BaseFileManagementService {
  WebFileManagementService(AppDatabase db);
  @override
  Future<bool> openFile(String filePath) async => false;
  @override
  Future<bool> shareFile(String filePath, {String? subject, String? text}) async => false;
  @override
  Future<bool> shareMultipleFiles(List<String> filePaths, {String? subject, String? text}) async => false;
  @override
  Future<bool> deleteFile(int documentId) async => false;
  @override
  Future<int> deleteMultipleFiles(List<int> documentIds) async => 0;
  @override
  Future<bool> renameFile(int documentId, String newFilename) async => false;
  @override
  Future<void> markAsShared(int documentId) async {}
  @override
  Future<int> registerExportedDocument({required dynamic file, required DocumentFileType fileType, required ExportType exportType, String? criId, Map<String, dynamic>? metadata}) async => 0;
}

BasePdfGeneratorService createPdfService(AppDatabase db) => WebPdfGeneratorService(db);
BaseDashboardCsvService createDashboardCsvService(AppDatabase db) => WebDashboardCsvService(db);
BaseTechnicianStatsCsvService createTechnicianStatsCsvService(AppDatabase db) => WebTechnicianStatsCsvService(db);
BaseFileManagementService createFileManagementService(AppDatabase db) => WebFileManagementService(db);
