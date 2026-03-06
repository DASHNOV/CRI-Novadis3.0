import '../../../data/local/app_database.dart';
import 'base_service_interfaces.dart';

// Import conditionnel des implémentations pour le type concret
import 'file_management_native.dart' if (dart.library.html) 'file_management_web.dart' as impl;

export 'base_service_interfaces.dart';

BaseFileManagementService createFileService(AppDatabase db) {
  return impl.FileManagementService(db);
}
