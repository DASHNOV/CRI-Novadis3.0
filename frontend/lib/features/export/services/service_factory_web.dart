import '../../../data/local/app_database.dart';
import 'base_service_interfaces.dart';
import 'pdf_generator_web.dart';
import 'dashboard_csv_web.dart';
import 'technician_stats_csv_web.dart';
import 'file_management_web.dart';

BasePdfGeneratorService createPdfService(AppDatabase db) => PdfGeneratorService(db);
BaseDashboardCsvService createDashboardCsvService(AppDatabase db) => DashboardCsvService(db);
BaseTechnicianStatsCsvService createTechnicianStatsCsvService(AppDatabase db) => TechnicianStatsCsvService(db);
BaseFileManagementService createFileManagementService(AppDatabase db) => FileManagementService(db);
