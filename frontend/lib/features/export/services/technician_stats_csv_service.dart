import '../../../data/local/app_database.dart';
import 'base_service_interfaces.dart';

// Import conditionnel des implémentations pour le type concret
import 'technician_stats_csv_native.dart' if (dart.library.html) 'technician_stats_csv_web.dart' as impl;

export 'base_service_interfaces.dart';

BaseTechnicianStatsCsvService createTechnicianStatsCsvService(AppDatabase database) {
  return impl.TechnicianStatsCsvService(database);
}
