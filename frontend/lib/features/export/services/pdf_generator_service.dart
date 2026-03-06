// Import conditionnel des implémentations
import 'pdf_generator_native.dart' if (dart.library.html) 'pdf_generator_web.dart' as impl;

import '../../../data/local/app_database.dart';

abstract class BasePdfGeneratorService {
  Future<dynamic> generateCriServicePDF(String criId);
  Future<dynamic> generateCriProjetPDF(String criId);
}

BasePdfGeneratorService createPdfService(AppDatabase database) {
  return impl.PdfGeneratorService(database);
}
