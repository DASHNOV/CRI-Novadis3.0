// Import conditionnel des implémentations
import 'dashboard_csv_native.dart' if (dart.library.html) 'dashboard_csv_web.dart' as impl;

import '../../../data/local/app_database.dart';

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

BaseDashboardCsvService createDashboardCsvService(AppDatabase database) {
  return impl.DashboardCsvService(database);
}
