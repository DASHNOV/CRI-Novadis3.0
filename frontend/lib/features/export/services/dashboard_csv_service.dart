import '../../../data/local/app_database.dart';
import 'base_service_interfaces.dart';

// Import conditionnel des implémentations pour le type concret
import 'dashboard_csv_native.dart' if (dart.library.html) 'dashboard_csv_web.dart' as impl;

export 'base_service_interfaces.dart';

BaseDashboardCsvService createDashboardCsvService(AppDatabase database) {
  return impl.DashboardCsvService(database);
}
