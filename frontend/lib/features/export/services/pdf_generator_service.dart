import '../../../data/local/app_database.dart';
import 'base_service_interfaces.dart';

// Import conditionnel des implémentations pour le type concret
import 'pdf_generator_native.dart' if (dart.library.html) 'pdf_generator_web.dart' as impl;

export 'base_service_interfaces.dart';

BasePdfGeneratorService createPdfService(AppDatabase database) {
  return impl.PdfGeneratorService(database);
}
