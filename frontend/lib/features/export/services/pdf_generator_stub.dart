import '../../../data/local/app_database.dart';

abstract class BasePdfGeneratorService {
  Future<dynamic> generateCriServicePDF(String criId);
  Future<dynamic> generateCriProjetPDF(String criId);
}

BasePdfGeneratorService createPdfService(AppDatabase database) => throw UnimplementedError();
