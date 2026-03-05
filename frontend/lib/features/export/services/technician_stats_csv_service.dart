import '../../../data/local/app_database.dart';

// Import conditionnel des implémentations
import 'technician_stats_csv_native.dart' if (dart.library.html) 'technician_stats_csv_web.dart' as impl;

class TechnicianStatsCsvService extends impl.TechnicianStatsCsvService {
  TechnicianStatsCsvService(super.database);
}
