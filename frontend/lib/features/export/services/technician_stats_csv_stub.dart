import '../../../data/local/app_database.dart';

abstract class BaseTechnicianStatsCsvService {
  Future<dynamic> exportTechnicianStats({
    required String technicianName,
    required DateTime startDate,
    required DateTime endDate,
  });
}

BaseTechnicianStatsCsvService createTechnicianStatsCsvService(AppDatabase database) => throw UnimplementedError();
