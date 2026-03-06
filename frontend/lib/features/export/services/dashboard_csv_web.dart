import '../../../data/local/app_database.dart';
import 'dashboard_csv_service.dart';

class DashboardCsvService implements BaseDashboardCsvService {
  final AppDatabase _database;
  DashboardCsvService(this._database);

  @override
  Future<dynamic> exportInterventions({
    required DateTime startDate,
    required DateTime endDate,
    String? interventionType,
    String? status,
  }) async => throw UnimplementedError();

  @override
  Future<dynamic> exportKPISynthesis({required DateTime startDate, required DateTime endDate}) async => throw UnimplementedError();

  @override
  Future<dynamic> exportTopSites({required DateTime startDate, required DateTime endDate, int limit = 10}) async => throw UnimplementedError();

  @override
  Future<List<dynamic>> exportAll({required DateTime startDate, required DateTime endDate}) async => throw UnimplementedError();
}
