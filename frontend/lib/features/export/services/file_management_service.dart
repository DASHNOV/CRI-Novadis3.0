import '../../../data/local/app_database.dart';
import 'base_service_interfaces.dart';

// Import conditionnel des implémentations pour le type concret
import 'file_management_web.dart' 
    if (dart.library.js_interop) 'file_management_web.dart'
    if (dart.library.io) 'file_management_native.dart' as impl;

export 'base_service_interfaces.dart';

BaseFileManagementService createFileService(AppDatabase db) {
  return impl.FileManagementService(db);
}
