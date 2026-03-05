import '../../../data/local/app_database.dart';
import 'dashboard_csv_stub.dart';

// Import conditionnel des implémentations
import 'dashboard_csv_native.dart' if (dart.library.html) 'dashboard_csv_web.dart' as impl;

export 'dashboard_csv_stub.dart';

BaseDashboardCsvService createDashboardCsvService(AppDatabase database) {
  return impl.DashboardCsvService(database);
}
