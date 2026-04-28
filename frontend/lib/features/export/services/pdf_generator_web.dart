// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;

import '../../../data/local/app_database.dart';
import '../../../data/models/cri_projet_model.dart';
import '../../../data/models/cri_service_model.dart';
import 'base_service_interfaces.dart' show BasePdfGeneratorService, PdfWebResult;
import 'pdf_builder_common.dart';

/// Service de génération de PDF pour les CRI (Version Web)
/// Génère le PDF en mémoire et déclenche un téléchargement navigateur
class PdfGeneratorService
    with PdfBuilderCommon
    implements BasePdfGeneratorService {
  final AppDatabase _database;

  PdfGeneratorService(this._database);

  @override
  Future<dynamic> generateCriServicePDF(String criId) async {
    final criData = await _database.getCriServiceById(criId);
    if (criData == null) throw Exception('CRI Service non trouvé: $criId');
    final cri = CriServiceModel.fromDb(criData);

    final pdf = await buildCriServiceDocument(cri);
    final bytes = await pdf.save();
    final filename =
        'CRI_Service_${cri.ticketNumber}_${formatDateForFilename(DateTime.now())}.pdf';

    _triggerBrowserDownload(bytes, filename);
    debugPrint('[PDF Web] Téléchargement déclenché: $filename (${bytes.length} bytes)');
    return PdfWebResult(bytes: bytes, filename: filename);
  }

  @override
  Future<dynamic> generateCriProjetPDF(String criId) async {
    final criData = await _database.getCriProjetById(criId);
    if (criData == null) throw Exception('CRI Projet non trouvé: $criId');
    final cri = CriProjetModel.fromDb(criData);

    final pdf = await buildCriProjetDocument(cri);
    final bytes = await pdf.save();
    final filename =
        'CRI_Projet_${cri.projectNumber}_${formatDateForFilename(DateTime.now())}.pdf';

    _triggerBrowserDownload(bytes, filename);
    debugPrint('[PDF Web] Téléchargement déclenché: $filename (${bytes.length} bytes)');
    return PdfWebResult(bytes: bytes, filename: filename);
  }

  void _triggerBrowserDownload(Uint8List bytes, String filename) {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    // Nettoyage
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
}
