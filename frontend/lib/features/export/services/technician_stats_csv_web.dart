import '../../../data/local/app_database.dart';
import 'base_service_interfaces.dart';

class TechnicianStatsCsvService implements BaseTechnicianStatsCsvService {
  // ignore: unused_field
  final AppDatabase _database;
  TechnicianStatsCsvService(this._database);

  @override
  Future<dynamic> exportTechnicianStats({
    required String technicianName,
    required DateTime startDate,
    required DateTime endDate,
  }) async => throw UnimplementedError();
}

