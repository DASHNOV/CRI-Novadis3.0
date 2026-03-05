import '../../../data/local/app_database.dart';

class TechnicianStatsCsvService {
  final AppDatabase _database;
  TechnicianStatsCsvService(this._database);

  Future<dynamic> exportTechnicianStats({
    required String technicianName,
    required DateTime startDate,
    required DateTime endDate,
  }) async => throw UnimplementedError();
}
