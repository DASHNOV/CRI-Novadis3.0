import '../../../data/local/app_database.dart';
import 'pdf_generator_service.dart';

class PdfGeneratorService implements BasePdfGeneratorService {
  final AppDatabase _database;
  PdfGeneratorService(this._database);

  @override
  Future<dynamic> generateCriServicePDF(String criId) async {
    throw UnimplementedError('PDF generation not supported on web');
  }

  @override
  Future<dynamic> generateCriProjetPDF(String criId) async {
    throw UnimplementedError('PDF generation not supported on web');
  }
}
