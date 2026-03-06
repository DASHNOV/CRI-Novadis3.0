// Import conditionnel des implémentations
import 'technician_stats_csv_native.dart' if (dart.library.html) 'technician_stats_csv_web.dart' as impl;

import '../../../data/local/app_database.dart';

abstract class BaseTechnicianStatsCsvService {
  Future<dynamic> exportTechnicianStats({
    required String technicianName,
    required DateTime startDate,
    required DateTime endDate,
  });
}

BaseTechnicianStatsCsvService createTechnicianStatsCsvService(AppDatabase database) {
  return impl.TechnicianStatsCsvService(database);
}
