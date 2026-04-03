import '../../../data/local/app_database.dart';
import 'base_service_interfaces.dart';

import 'pdf_generator_web.dart'
    if (dart.library.io) 'pdf_generator_native.dart' as impl;

export 'base_service_interfaces.dart';

BasePdfGeneratorService createPdfService(AppDatabase database) {
  return impl.PdfGeneratorService(database);
}
