import '../../../data/local/app_database.dart';

class DashboardCsvService {
  final AppDatabase _database;
  DashboardCsvService(this._database);

  Future<dynamic> exportInterventions({
    required DateTime startDate,
    required DateTime endDate,
    String? interventionType,
    String? status,
  }) async => throw UnimplementedError();

  Future<dynamic> exportKPISynthesis({required DateTime startDate, required DateTime endDate}) async => throw UnimplementedError();

  Future<dynamic> exportTopSites({required DateTime startDate, required DateTime endDate, int limit = 10}) async => throw UnimplementedError();

  Future<List<dynamic>> exportAll({required DateTime startDate, required DateTime endDate}) async => throw UnimplementedError();
}
