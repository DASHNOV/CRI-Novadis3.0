import '../../../data/local/app_database.dart';
import 'pdf_generator_stub.dart';

// Import conditionnel des implémentations
import 'pdf_generator_native.dart' if (dart.library.html) 'pdf_generator_web.dart' as impl;

export 'pdf_generator_stub.dart';

BasePdfGeneratorService createPdfService(AppDatabase database) {
  return impl.PdfGeneratorService(database);
}
