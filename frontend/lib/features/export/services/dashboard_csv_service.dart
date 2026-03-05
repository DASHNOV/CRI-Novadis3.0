import '../../../data/local/app_database.dart';

// Import conditionnel des implémentations
import 'dashboard_csv_native.dart' if (dart.library.html) 'dashboard_csv_web.dart' as impl;

class DashboardCsvService extends impl.DashboardCsvService {
  DashboardCsvService(super.database);
}
