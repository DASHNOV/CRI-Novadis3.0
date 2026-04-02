import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../data/local/app_database.dart';
import '../../../data/local/tables/cri_service_table.dart' show ServiceRequestType, ResolutionStatus;
import '../../../data/models/cri_projet_model.dart';
import '../../../data/models/cri_service_model.dart';
import 'base_service_interfaces.dart';

/// Service de génération de PDF pour les CRI (Version Native)
/// Reproduit le format officiel Novadis avec mise en page professionnelle
class PdfGeneratorService implements BasePdfGeneratorService {
  final AppDatabase _database;

  PdfGeneratorService(this._database);

  // ─── Couleurs Novadis ───
  static const _blue = PdfColor.fromInt(0xFF0066CC);
  static const _black = PdfColor.fromInt(0xFF000000);
  static const _gray = PdfColor.fromInt(0xFF666666);
  static const _lightGray = PdfColor.fromInt(0xFFE0E0E0);

  // ─── Styles ───
  static final _headerStyle = pw.TextStyle(
    fontSize: 13,
    fontWeight: pw.FontWeight.bold,
    color: _blue,
  );
  static final _labelStyle = pw.TextStyle(
    fontSize: 8,
    fontWeight: pw.FontWeight.bold,
    color: _black,
  );
  static const _valueStyle = pw.TextStyle(fontSize: 9, color: _black);
  static const _smallStyle = pw.TextStyle(fontSize: 7, color: _gray);
  static final _footerLinkStyle = pw.TextStyle(
    fontSize: 7,
    color: _blue,
    fontWeight: pw.FontWeight.bold,
  );

  pw.ImageProvider? _logo;

  Future<void> _loadLogo() async {
    if (_logo != null) return;
    try {
      final logoData = await rootBundle.load('assets/novadis_logo.png');
      _logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      debugPrint('[PDF] Logo non trouvé: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════
  // CRI SERVICE
  // ════════════════════════════════════════════════════════════════

  @override
  Future<dynamic> generateCriServicePDF(String criId) async {
    final criData = await _database.getCriServiceById(criId);
    if (criData == null) throw Exception('CRI Service non trouvé: $criId');
    final cri = CriServiceModel.fromDb(criData);

    await _loadLogo();
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ─── En-tête avec logo + titre ───
              _buildHeader('COMPTE RENDU D\'INTERVENTION SERVICES'),
              pw.SizedBox(height: 12),

              // ─── Client ───
              _buildTableSection([
                _buildRow([_buildCell('Client :', cri.clientName, bold: true)]),
              ]),
              pw.SizedBox(height: 6),

              // ─── Site / Date ───
              _buildTableSection([
                _buildRow([
                  _buildCell('Projet / Site :', cri.site, flex: 3),
                  _buildCell('Date :', dateFormat.format(cri.interventionDate), flex: 2),
                ]),
              ]),
              pw.SizedBox(height: 6),

              // ─── Ville / Dpt / Heure début ───
              _buildTableSection([
                _buildRow([
                  _buildCell('Ville :', cri.ville ?? '', flex: 3),
                  _buildCell('Dpt :', cri.departement, flex: 1),
                  _buildCell('Début d\'intervention :', timeFormat.format(cri.startTime), flex: 2),
                ]),
              ]),
              pw.SizedBox(height: 6),

              // ─── Type d'intervention (checkboxes) ───
              _buildTableSection([
                _buildRow([
                  _buildCheckboxGroup([
                    _checkbox('Maintenance préventive', cri.requestType == ServiceRequestType.maintenancePreventive),
                    _checkbox('Maintenance curative', cri.requestType == ServiceRequestType.maintenanceCorrective),
                  ], flex: 2),
                  _buildCheckboxGroup([
                    _checkbox('Sous contrat', cri.contratType == 'Sous contrat'),
                    _checkbox('Hors contrat', cri.contratType == 'Hors contrat'),
                  ], flex: 2),
                  _buildCheckboxGroup([
                    _checkbox('Vidéo', true),
                    _checkbox('Contrôle d\'accès', false),
                    _checkbox('Intrusion', false),
                  ], flex: 2),
                ]),
              ]),
              pw.SizedBox(height: 6),

              // ─── Motif intervention ───
              _buildTableSection([
                _buildLabelValueBlock('Motif Intervention :', cri.requestDescription),
              ]),
              pw.SizedBox(height: 6),

              // ─── Travail effectué ───
              _buildTableSection([
                _buildLabelValueBlock('Travail Effectué :', cri.actionsPerformed),
                if (cri.diagnosticPerformed != null && cri.diagnosticPerformed!.isNotEmpty)
                  _buildLabelValueBlock('Diagnostic :', cri.diagnosticPerformed!),
              ]),

              pw.Spacer(),

              // ─── Statut + Fin d'intervention ───
              _buildTableSection([
                _buildRow([
                  _buildCheckboxGroup([
                    _checkbox('Terminée', cri.resolutionStatus == ResolutionStatus.resolu),
                    _checkbox('A Suivre', cri.additionalInterventionRequired),
                    _checkbox('Devis à réaliser', false),
                    _checkbox('Facturable', false),
                  ], flex: 4, horizontal: true),
                  _buildCell('Fin d\'intervention :', '${timeFormat.format(cri.endTime)} H', flex: 2),
                ]),
              ]),
              pw.SizedBox(height: 6),

              // ─── Remarques client ───
              _buildTableSection([
                _buildLabelValueBlock('Remarques Client :', cri.recommendations ?? ''),
              ]),
              pw.SizedBox(height: 6),

              // ─── Signatures ───
              _buildSignatureBlock(cri.technicianName, 'sav@novadis.eu', cri.clientName, cri.email, cri.technicianSignature, cri.clientSignature),
              pw.SizedBox(height: 12),

              // ─── Pied de page Novadis ───
              _buildFooter(),
            ],
          );
        },
      ),
    );

    // Page photos si disponible
    if (cri.photos.isNotEmpty) {
      await _addPhotosPages(pdf, cri.photos);
    }

    return await _savePDF(pdf, 'CRI_Service_${cri.ticketNumber}_${_formatDateForFilename(DateTime.now())}');
  }

  // ════════════════════════════════════════════════════════════════
  // CRI PROJET
  // ════════════════════════════════════════════════════════════════

  @override
  Future<dynamic> generateCriProjetPDF(String criId) async {
    final criData = await _database.getCriProjetById(criId);
    if (criData == null) throw Exception('CRI Projet non trouvé: $criId');
    final cri = CriProjetModel.fromDb(criData);

    await _loadLogo();
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ─── En-tête ───
              _buildHeader('COMPTE RENDU D\'INTERVENTION PROJET'),
              pw.SizedBox(height: 12),

              // ─── Client ───
              _buildTableSection([
                _buildRow([_buildCell('Client :', cri.clientName, bold: true)]),
              ]),
              pw.SizedBox(height: 6),

              // ─── Projet / Site / Date ───
              _buildTableSection([
                _buildRow([
                  _buildCell('Projet :', cri.projectName, flex: 2),
                  _buildCell('N° Projet :', cri.projectNumber, flex: 2),
                ]),
                _buildRow([
                  _buildCell('Site :', cri.site, flex: 2),
                  _buildCell('Date :', dateFormat.format(cri.interventionDate), flex: 2),
                ]),
              ]),
              pw.SizedBox(height: 6),

              // ─── Ville / Horaires ───
              _buildTableSection([
                _buildRow([
                  _buildCell('Ville :', cri.ville ?? '', flex: 2),
                  _buildCell('Début :', timeFormat.format(cri.startTime), flex: 1),
                  _buildCell('Fin :', timeFormat.format(cri.endTime), flex: 1),
                  _buildCell('Durée :', cri.formattedDuration, flex: 1),
                ]),
              ]),
              pw.SizedBox(height: 6),

              // ─── Phase / Type intervention ───
              _buildTableSection([
                _buildRow([
                  _buildCell('Phase projet :', cri.projectPhase.label, flex: 2),
                  _buildCell('Type d\'intervention :', cri.interventionType.label, flex: 2),
                ]),
              ]),
              pw.SizedBox(height: 6),

              // ─── Travaux réalisés ───
              _buildTableSection([
                _buildLabelValueBlock('Travaux réalisés :', cri.workDescription),
              ]),
              pw.SizedBox(height: 6),

              // ─── Matériel utilisé ───
              if (cri.materialsUsed != null && cri.materialsUsed!.isNotEmpty) ...[
                _buildTableSection([
                  _buildLabelValueBlock('Matériel utilisé :', cri.materialsUsed!),
                ]),
                pw.SizedBox(height: 6),
              ],

              // ─── Problèmes / Solutions ───
              if (cri.problemsEncountered != null && cri.problemsEncountered!.isNotEmpty) ...[
                _buildTableSection([
                  _buildLabelValueBlock('Problèmes rencontrés :', cri.problemsEncountered!),
                  if (cri.solutionsProvided != null && cri.solutionsProvided!.isNotEmpty)
                    _buildLabelValueBlock('Solutions apportées :', cri.solutionsProvided!),
                ]),
                pw.SizedBox(height: 6),
              ],

              // ─── Statut / Suivi ───
              _buildTableSection([
                _buildRow([
                  _buildCell('Statut projet :', cri.projectStatus.label, flex: 2),
                  _buildCell('Prochaine intervention :', cri.nextInterventionDate != null ? dateFormat.format(cri.nextInterventionDate!) : 'Non planifiée', flex: 2),
                ]),
                if (cri.actionsToDo != null && cri.actionsToDo!.isNotEmpty)
                  _buildLabelValueBlock('Actions à prévoir :', cri.actionsToDo!),
              ]),

              pw.Spacer(),

              // ─── Remarques client ───
              _buildTableSection([
                _buildLabelValueBlock('Remarques Client :', cri.clientComments ?? ''),
              ]),
              pw.SizedBox(height: 6),

              // ─── Signatures ───
              _buildSignatureBlock(cri.technicianName, 'sav@novadis.eu', cri.clientName, cri.email, cri.technicianSignature, cri.clientSignature),
              pw.SizedBox(height: 12),

              // ─── Pied de page ───
              _buildFooter(),
            ],
          );
        },
      ),
    );

    if (cri.photos.isNotEmpty) {
      await _addPhotosPages(pdf, cri.photos);
    }

    return await _savePDF(pdf, 'CRI_Projet_${cri.projectNumber}_${_formatDateForFilename(DateTime.now())}');
  }

  // ════════════════════════════════════════════════════════════════
  // COMPOSANTS PDF RÉUTILISABLES
  // ════════════════════════════════════════════════════════════════

  /// En-tête: logo novadis + titre bleu
  pw.Widget _buildHeader(String title) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // Logo ou texte "novadis"
        if (_logo != null)
          pw.Image(_logo!, width: 90)
        else
          pw.Text('novadis', style: pw.TextStyle(
            fontSize: 22,
            fontWeight: pw.FontWeight.bold,
            color: _black,
          )),
        pw.SizedBox(width: 20),
        pw.Expanded(
          child: pw.Text(
            title,
            style: _headerStyle,
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// Section avec bordure complète
  pw.Widget _buildTableSection(List<pw.Widget> children) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _black, width: 0.5),
      ),
      child: pw.Column(children: children),
    );
  }

  /// Ligne avec cellules
  pw.Widget _buildRow(List<pw.Widget> cells) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _lightGray, width: 0.3)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: cells,
      ),
    );
  }

  /// Cellule label: valeur
  pw.Widget _buildCell(String label, String value, {int flex = 1, bool bold = false}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: const pw.BoxDecoration(
          border: pw.Border(right: pw.BorderSide(color: _lightGray, width: 0.3)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(label, style: _labelStyle),
            pw.SizedBox(height: 1),
            pw.Text(value, style: bold
                ? pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _black)
                : _valueStyle),
          ],
        ),
      ),
    );
  }

  /// Bloc label + texte libre sur toute la largeur
  pw.Widget _buildLabelValueBlock(String label, String value) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _lightGray, width: 0.3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: _labelStyle),
          pw.SizedBox(height: 2),
          pw.Text(value.isEmpty ? ' ' : value, style: _valueStyle),
          pw.SizedBox(height: 4),
        ],
      ),
    );
  }

  /// Groupe de checkboxes
  pw.Widget _buildCheckboxGroup(List<pw.Widget> checkboxes, {int flex = 1, bool horizontal = false}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: horizontal
            ? pw.Row(
                children: checkboxes.map((c) => pw.Padding(
                  padding: const pw.EdgeInsets.only(right: 12),
                  child: c,
                )).toList(),
              )
            : pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisSize: pw.MainAxisSize.min,
                children: checkboxes,
              ),
      ),
    );
  }

  /// Checkbox individuelle
  pw.Widget _checkbox(String label, bool checked) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            width: 10,
            height: 10,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _black, width: 0.5),
            ),
            child: checked
                ? pw.Center(child: pw.Text('X', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)))
                : pw.SizedBox(),
          ),
          pw.SizedBox(width: 4),
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  /// Bloc signatures technicien + client
  pw.Widget _buildSignatureBlock(
    String techName, String techEmail,
    String clientName, String? clientEmail,
    String? techSignatureBase64, String? clientSignatureBase64,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: _black, width: 0.5)),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Technicien
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: const pw.BoxDecoration(
                border: pw.Border(right: pw.BorderSide(color: _black, width: 0.5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Intervenant Novadis :', style: _labelStyle),
                  pw.Text(techName, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Mail de contact : $techEmail', style: _smallStyle),
                  pw.SizedBox(height: 4),
                  pw.Text('Signature :', style: _labelStyle),
                  _buildSignatureImage(techSignatureBase64),
                ],
              ),
            ),
          ),
          // Client
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Client :', style: _labelStyle),
                  pw.Text('Société :', style: _smallStyle),
                  pw.Text(clientName, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  if (clientEmail != null && clientEmail.isNotEmpty)
                    pw.Text('Mail de contact :\n$clientEmail', style: _smallStyle),
                  pw.SizedBox(height: 4),
                  pw.Text('Signature :', style: _labelStyle),
                  _buildSignatureImage(clientSignatureBase64),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche une signature base64 ou un espace vide
  pw.Widget _buildSignatureImage(String? base64Data) {
    if (base64Data != null && base64Data.isNotEmpty) {
      try {
        final cleanBase64 = base64Data.contains(',') ? base64Data.split(',').last : base64Data;
        final bytes = base64Decode(cleanBase64);
        return pw.Container(
          height: 40,
          alignment: pw.Alignment.centerLeft,
          child: pw.Image(pw.MemoryImage(Uint8List.fromList(bytes)), height: 36),
        );
      } catch (e) {
        debugPrint('[PDF] Erreur décodage signature: $e');
      }
    }
    return pw.Container(height: 40); // Espace vide pour signature manuscrite
  }

  /// Pied de page Novadis
  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: _blue, thickness: 1),
        pw.SizedBox(height: 4),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo ou texte
            if (_logo != null)
              pw.Image(_logo!, width: 60)
            else
              pw.Text('novadis', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(width: 16),
            // Adresse
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('14, rue Clément Bayard', style: _smallStyle),
                pw.Text('92300 Levallois Perret', style: _smallStyle),
              ],
            ),
            pw.SizedBox(width: 16),
            // Téléphone
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('T +33 (0)1 41 34 09 90', style: _smallStyle),
                pw.Text('F +33 (0)1 41 34 09 91', style: _smallStyle),
              ],
            ),
            pw.Spacer(),
            // Site web / email
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('contact@novadis.eu', style: _footerLinkStyle),
                pw.Text('Novadis.eu', style: _footerLinkStyle),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════
  // PHOTOS & SAUVEGARDE
  // ════════════════════════════════════════════════════════════════

  Future<void> _addPhotosPages(pw.Document pdf, List<String> photos) async {
    final validPhotos = <pw.MemoryImage>[];

    for (final photoPath in photos) {
      try {
        if (photoPath.startsWith('data:') || photoPath.startsWith('/9j/') || photoPath.length > 500) {
          // Base64 encoded
          final cleanBase64 = photoPath.contains(',') ? photoPath.split(',').last : photoPath;
          final bytes = base64Decode(cleanBase64);
          validPhotos.add(pw.MemoryImage(Uint8List.fromList(bytes)));
        } else {
          // File path
          final file = File(photoPath);
          if (await file.exists()) {
            validPhotos.add(pw.MemoryImage(await file.readAsBytes()));
          }
        }
      } catch (e) {
        debugPrint('[PDF] Erreur chargement photo: $e');
      }
    }

    if (validPhotos.isEmpty) return;

    // 2 photos par page
    for (var i = 0; i < validPhotos.length; i += 2) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Text('Photos de l\'intervention', style: _headerStyle),
                pw.SizedBox(height: 12),
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Image(validPhotos[i], fit: pw.BoxFit.contain),
                  ),
                ),
                if (i + 1 < validPhotos.length) ...[
                  pw.SizedBox(height: 12),
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Image(validPhotos[i + 1], fit: pw.BoxFit.contain),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      );
    }
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

  String _formatDateForFilename(DateTime date) => DateFormat('yyyyMMdd_HHmmss').format(date);
}
