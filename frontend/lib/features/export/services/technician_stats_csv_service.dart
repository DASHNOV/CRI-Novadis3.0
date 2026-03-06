// Import conditionnel des implémentations
import 'technician_stats_csv_native.dart' if (dart.library.html) 'technician_stats_csv_web.dart' as impl;

import '../../../data/local/app_database.dart';
import 'base_service_interfaces.dart';

export 'base_service_interfaces.dart';

BaseTechnicianStatsCsvService createTechnicianStatsCsvService(AppDatabase database) {
  return impl.TechnicianStatsCsvService(database);
}
