import '../../../data/local/app_database.dart';
import 'file_management_stub.dart';

// Import conditionnel des implémentations
import 'file_management_native.dart' if (dart.library.html) 'file_management_web.dart' as impl;

export 'file_management_stub.dart';

BaseFileManagementService createFileService(AppDatabase db) {
  return impl.FileManagementService(db);
}
