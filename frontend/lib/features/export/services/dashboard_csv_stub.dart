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

BaseDashboardCsvService createDashboardCsvService(AppDatabase database) => throw UnimplementedError();
