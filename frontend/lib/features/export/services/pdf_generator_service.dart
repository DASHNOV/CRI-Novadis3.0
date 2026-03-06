// Import conditionnel des implémentations
import 'pdf_generator_native.dart' if (dart.library.html) 'pdf_generator_web.dart' as impl;

import '../../../data/local/app_database.dart';
import 'base_service_interfaces.dart';

export 'base_service_interfaces.dart';

BasePdfGeneratorService createPdfService(AppDatabase database) {
  return impl.PdfGeneratorService(database);
}
