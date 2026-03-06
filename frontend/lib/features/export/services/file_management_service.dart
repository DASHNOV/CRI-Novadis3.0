// Import conditionnel des implémentations
import 'file_management_native.dart' if (dart.library.html) 'file_management_web.dart' as impl;

import '../../../data/local/app_database.dart';
import 'base_service_interfaces.dart';

export 'base_service_interfaces.dart';

BaseFileManagementService createFileService(AppDatabase db) {
  return impl.FileManagementService(db);
}
