import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../../data/local/app_database.dart';
import '../../../data/models/cri_projet_model.dart';
import '../../../data/models/cri_service_model.dart';
import 'base_service_interfaces.dart';
import 'pdf_builder_common.dart';

/// Service de génération de PDF pour les CRI (Version Native)
/// Reproduit le format officiel Novadis avec mise en page professionnelle
class PdfGeneratorService with PdfBuilderCommon implements BasePdfGeneratorService {
  final AppDatabase _database;

  PdfGeneratorService(this._database);

  @override
  Future<pw.MemoryImage?> resolveFilePhoto(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return pw.MemoryImage(await file.readAsBytes());
      }
    } catch (e) {
      debugPrint('[PDF] Erreur lecture fichier photo: $e');
    }
    return null;
  }

  @override
  Future<dynamic> generateCriServicePDF(String criId) async {
    final criData = await _database.getCriServiceById(criId);
    if (criData == null) throw Exception('CRI Service non trouvé: $criId');
    final cri = CriServiceModel.fromDb(criData);

    final pdf = await buildCriServiceDocument(cri);
    return await _savePDF(
      pdf,
      'CRI_Service_${cri.ticketNumber}_${formatDateForFilename(DateTime.now())}',
    );
  }

  @override
  Future<dynamic> generateCriProjetPDF(String criId) async {
    final criData = await _database.getCriProjetById(criId);
    if (criData == null) throw Exception('CRI Projet non trouvé: $criId');
    final cri = CriProjetModel.fromDb(criData);

    final pdf = await buildCriProjetDocument(cri);
    return await _savePDF(
      pdf,
      'CRI_Projet_${cri.projectNumber}_${formatDateForFilename(DateTime.now())}',
    );
  }

  Future<File> _savePDF(pw.Document pdf, String filename) async {
    final output = await getApplicationDocumentsDirectory();
    debugPrint('[PDF] Documents dir: ${output.path}');

    final novadisDir = Directory(p.join(output.path, 'Novadis', 'CRI'));
    if (!await novadisDir.exists()) {
      await novadisDir.create(recursive: true);
      debugPrint('[PDF] Créé dossier: ${novadisDir.path}');
    }

    final filePath = p.join(novadisDir.path, '$filename.pdf');
    final File file = File(filePath);
    final bytes = await pdf.save();
    debugPrint('[PDF] PDF généré: ${bytes.length} bytes');

    await file.writeAsBytes(bytes, flush: true);
    debugPrint('[PDF] Fichier écrit: $filePath');

    final exists = await file.exists();
    final size = exists ? await file.length() : 0;
    debugPrint('[PDF] Vérification: exists=$exists, size=$size');

    if (!exists) {
      throw Exception('Échec de l\'écriture du fichier PDF: $filePath');
    }

    return file;
  }
}
