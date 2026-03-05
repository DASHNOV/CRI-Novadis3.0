import '../../../data/local/app_database.dart';
import 'technician_stats_csv_stub.dart';

// Import conditionnel des implémentations
import 'technician_stats_csv_native.dart' if (dart.library.html) 'technician_stats_csv_web.dart' as impl;

export 'technician_stats_csv_stub.dart';

BaseTechnicianStatsCsvService createTechnicianStatsCsvService(AppDatabase database) {
  return impl.TechnicianStatsCsvService(database);
}
