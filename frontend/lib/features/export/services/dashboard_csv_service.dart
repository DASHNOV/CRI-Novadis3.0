import '../../../data/local/app_database.dart';
import 'base_service_interfaces.dart';

// Import conditionnel des implémentations pour le type concret
import 'dashboard_csv_web.dart' 
    if (dart.library.js_interop) 'dashboard_csv_web.dart'
    if (dart.library.io) 'dashboard_csv_native.dart' as impl;

export 'base_service_interfaces.dart';

BaseDashboardCsvService createDashboardCsvService(AppDatabase database) {
  return impl.DashboardCsvService(database);
}
