import 'dart:io';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../data/local/app_database.dart';
import '../../../data/local/tables/cri_service_table.dart';

import '../../../data/models/cri_projet_model.dart';
import '../../../data/models/cri_service_model.dart';

/// Service de génération de PDF pour les CRI
class PdfGeneratorService {
  final AppDatabase _database;

  PdfGeneratorService(this._database);

  /// Couleur principale Novadis
  static const novadisBlue = PdfColor.fromInt(0xFF0066CC);
  static const novadisLightBlue = PdfColor.fromInt(0xFFE3F2FD);
  static const darkGray = PdfColor.fromInt(0xFF424242);
  static const lightGray = PdfColor.fromInt(0xFFE0E0E0);

  /// Génère un PDF pour un CRI Service (Format Papier Spécifique)
  Future<File> generateCriServicePDF(String criId) async {
    final criData = await _database.getCriServiceById(criId);
    if (criData == null) {
      throw Exception('CRI Service non trouvé: $criId');
    }
    final cri = CriServiceModel.fromDb(criData);

    final pdf = pw.Document();

    // Charger le logo (si disponible)
    pw.ImageProvider? logo;
    try {
      final logoData = await rootBundle.load('assets/logos/novadis_logo.png');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // Logo non disponible, continuer sans
    }

    // Ajouter les pages
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildPaperHeader(
                logo,
                title: 'COMPTE RENDU D\'INTERVENTION SERVICES',
              ),
              pw.SizedBox(height: 15),
              pw.Expanded(child: _buildServicePaperBody(cri)),
              pw.SizedBox(height: 10),
              _buildServicePaperFooterBlock(cri),
              pw.SizedBox(height: 20),
              _buildPaperBottomAddress(),
            ],
          );
        },
      ),
    );

    // Ajouter page photos si présentes
    if (cri.photos.isNotEmpty) {
      await _addPhotosPage(pdf, jsonEncode(cri.photos));
    }

    // Sauvegarder le PDF
    return await _savePDF(
      pdf,
      'CRI_Service_${cri.ticketNumber}_${_formatDateForFilename(DateTime.now())}',
    );
  }

  /// Génère un PDF pour un CRI Projet
  Future<File> generateCriProjetPDF(String criId) async {
    final criData = await _database.getCriProjetById(criId);
    if (criData == null) {
      throw Exception('CRI Projet non trouvé: $criId');
    }
    final cri = CriProjetModel.fromDb(criData);

    final pdf = pw.Document();

    // Charger le logo (si disponible)
    pw.ImageProvider? logo;
    try {
      final logoData = await rootBundle.load('assets/logos/novadis_logo.png');
      logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // Logo non disponible
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _buildHeader(
                logo,
                'COMPTE RENDU D\'INTERVENTION PROJET',
                cri.projectNumber,
              ),
              pw.SizedBox(height: 15),
              _buildProjetGeneralInfo(
                cri.interventionDate,
                cri.startTime,
                cri.endTime,
                cri.durationMinutes,
                cri.interventionType.label,
              ),
              pw.SizedBox(height: 10),
              _buildClientInfoSection(
                cri.clientName,
                cri.site,
                cri.address,
                null,
                null,
                cri.clientContact,
                cri.phone,
                cri.email,
              ),
              pw.SizedBox(height: 10),
              _buildProjetDetailsSection(
                cri.projectName,
                cri.projectNumber,
                cri.projectPhase.label,
                null,
                null,
                null,
              ),
              pw.SizedBox(height: 10),
              _buildProjetExecutionSection(
                cri.interventionType.label,
                null,
                null,
                cri.workDescription,
                cri.materialsUsed,
                cri.problemsEncountered,
              ),
              pw.SizedBox(height: 10),
              _buildProjetResultSection(
                cri.projectStatus.label,
                cri.solutionsProvided,
                null,
              ),
              pw.SizedBox(height: 10),
              _buildValidationSection(
                cri.technicianName,
                cri.technicianSignature,
                cri.clientSignature,
                null,
                cri.isDraft,
              ),
            ],
          );
        },
      ),
    );

    // Ajouter page photos si présentes
    if (cri.photos.isNotEmpty) {
      await _addPhotosPage(pdf, jsonEncode(cri.photos));
    }

    // Sauvegarder le PDF
    return await _savePDF(
      pdf,
      'CRI_Projet_${cri.projectNumber}_${_formatDateForFilename(DateTime.now())}',
    );
  }

  pw.Widget _buildServicePaperBody(CriServiceModel cri) {
    final borderSide = pw.BorderSide(color: PdfColors.black, width: 1);
    final boxDecoration = pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.black, width: 1),
    );

    return pw.Container(
      decoration: boxDecoration,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Row 1: Client
          _buildPaperRow(
            children: [
              _buildPaperCell(
                label: 'Client',
                value: cri.clientName,
                textStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
            borderBottom: true,
          ),
          // Row 2: Projet/Site | Date
          _buildPaperRow(
            children: [
              _buildPaperCell(
                label: 'Projet / Site',
                value: cri.site,
                flex: 2,
                borderRight: true,
              ),
              _buildPaperCell(
                label: 'Date',
                value: DateFormat('dd/MM/yyyy').format(cri.interventionDate),
                flex: 1,
              ),
            ],
            borderBottom: true,
          ),
          // Row 3: Ville | Dpt | Début
          _buildPaperRow(
            children: [
              _buildPaperCell(
                label: 'Ville',
                value: cri.ville,
                flex: 2,
                borderRight: true,
              ),
              _buildPaperCell(
                label: 'Dpt',
                value: cri.departement,
                flex: 1,
                borderRight: true,
              ),
              _buildPaperCell(
                label: 'Début d\'intervention',
                value: DateFormat('HH:mm').format(cri.startTime),
                flex: 1,
              ),
            ],
            borderBottom: true,
          ),
          // Row 4: Checkboxes Maintenance | Contrat | System
          pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border(bottom: borderSide)),
            child: pw.Row(
              children: [
                pw.Expanded(
                  // Maintenance type
                  flex: 3,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(right: borderSide),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildPaperCheckbox(
                          'Maintenance préventive',
                          cri.requestType.label == 'Maintenance préventive',
                        ), // Assuming label comparison or enum
                        pw.SizedBox(height: 5),
                        _buildPaperCheckbox(
                          'Maintenance curative',
                          cri.requestType == ServiceRequestType.depannage,
                        ),
                      ],
                    ),
                  ),
                ),
                pw.Expanded(
                  // Contrat
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(right: borderSide),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildPaperCheckbox(
                          'Sous contrat',
                          cri.contratType == 'Sous contrat',
                        ),
                        pw.SizedBox(height: 5),
                        _buildPaperCheckbox(
                          'Hors contrat',
                          cri.contratType == 'Hors contrat',
                        ),
                      ],
                    ),
                  ),
                ),
                pw.Expanded(
                  // System type
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildPaperCheckbox('Vidéo', cri.systemType == 'Vidéo'),
                        pw.SizedBox(height: 5),
                        _buildPaperCheckbox(
                          'Contrôle d\'accès',
                          cri.systemType == 'Contrôle d\'accès',
                        ),
                        pw.SizedBox(height: 5),
                        _buildPaperCheckbox(
                          'Intrusion',
                          cri.systemType == 'Intrusion',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Row 5: Motif Intervention
          _buildPaperRow(
            children: [
              _buildPaperCell(
                label: 'Motif Intervention',
                value: cri.requestDescription,
              ),
            ],
            borderBottom: true,
          ),
          // Row 6: Travail Effectué
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                border: pw.Border(bottom: borderSide),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Travail Effectué :',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    cri.actionsPerformed,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  if (cri.diagnosticPerformed != null &&
                      cri.diagnosticPerformed!.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Diagnostic : ${cri.diagnosticPerformed}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                  if (cri.identifiedCause != null &&
                      cri.identifiedCause!.isNotEmpty) ...[
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Cause : ${cri.identifiedCause}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                  if (cri.recommendations != null &&
                      cri.recommendations!.isNotEmpty) ...[
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Recommandations : ${cri.recommendations}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Row 7: Status checkboxes | Fin info
          pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border(bottom: borderSide)),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 4,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(right: borderSide),
                    ),
                    child: pw.Wrap(
                      spacing: 10,
                      runSpacing: 5,
                      children: [
                        _buildPaperCheckbox(
                          'Terminée',
                          cri.interventionStatus == 'Terminée',
                        ),
                        _buildPaperCheckbox(
                          'A Suivre',
                          cri.interventionStatus == 'A Suivre',
                        ),
                        _buildPaperCheckbox(
                          'Devis à réaliser',
                          cri.interventionStatus == 'Devis à réaliser',
                        ),
                        _buildPaperCheckbox(
                          'Facturable',
                          cri.interventionStatus == 'Facturable',
                        ),
                      ],
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    child: _buildPaperLabelValue(
                      'Fin d\'intervention',
                      '${DateFormat('HH:mm').format(cri.endTime)} H',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Row 8: Remarques Client
          pw.Container(
            height: 30,
            decoration: pw.BoxDecoration(border: pw.Border(bottom: borderSide)),
            padding: const pw.EdgeInsets.all(5),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Remarques Client :',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                pw.SizedBox(width: 5),
                // No specific client remarks field in service model other than followUpComments, using empty for now or followUpComments?
                // Using generic text if not mapped
              ],
            ),
          ),

          // Row 9: Pièces détachées Table Header
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              border: pw.Border(bottom: borderSide),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 2,
                  child: _buildTableHeaderCell(
                    'Référence Pièce détachée',
                    borderRight: true,
                  ),
                ),
                pw.Expanded(
                  flex: 4,
                  child: _buildTableHeaderCell(
                    'Désignation',
                    borderRight: true,
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: _buildTableHeaderCell('Garantie', borderRight: true),
                ),
                pw.Expanded(flex: 1, child: _buildTableHeaderCell('Quantité')),
              ],
            ),
          ),

          // Row 10: Pièces détachées content (Empty rows manually or dynamic)
          // Showing 2 empty rows as per screenshot design if no data, or dynamic data
          ...List.generate(3, (index) {
            final piece = (index < cri.piecesDetachees.length)
                ? cri.piecesDetachees[index]
                : null;
            return pw.Container(
              height: 20,
              decoration: pw.BoxDecoration(
                border: pw.Border(bottom: borderSide),
              ), // dotted line logic not easy with simple borders, using solid
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: _buildTableCellContent(
                      piece != null ? (piece['ref']?.toString() ?? '') : '',
                      borderRight: true,
                    ),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: _buildTableCellContent(
                      piece != null
                          ? (piece['designation']?.toString() ?? '')
                          : '',
                      borderRight: true,
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: _buildTableCellContent(
                      piece != null
                          ? (piece['garantie']?.toString() ?? '')
                          : '',
                      borderRight: true,
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: _buildTableCellContent(
                      piece != null ? (piece['qte']?.toString() ?? '') : '',
                      centered: true,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Row 11: Frais supplémentaires
          pw.Container(
            child: pw.Row(
              children: [
                // Labels column
                pw.Container(
                  width: 120,
                  padding: const pw.EdgeInsets.all(5),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(right: borderSide),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Frais supplémentaires',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '(Hors Contrat)',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Checkboxes column
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      _buildFraisRow(
                        'Déplacement IDF',
                        cri.fraisSupplementaires.contains('IDF'),
                        borderBottom: true,
                      ),
                      _buildFraisRow(
                        'Déplacement National (Forfait sur Devis)',
                        cri.fraisSupplementaires.contains('National'),
                        borderBottom: true,
                      ),
                      _buildFraisRow(
                        'Autres : ${cri.fraisSupplementaires.where((e) => e != 'IDF' && e != 'National').join(', ')}',
                        cri.fraisSupplementaires.any(
                          (e) => e != 'IDF' && e != 'National',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFraisRow(
    String label,
    bool value, {
    bool borderBottom = false,
  }) {
    return pw.Container(
      height: 20,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5),
      decoration: borderBottom
          ? const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.black, width: 1),
              ),
            )
          : null,
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Container(
            width: 10,
            height: 10,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black),
            ),
            child: value
                ? pw.Center(
                    child: pw.Text('X', style: const pw.TextStyle(fontSize: 8)),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableHeaderCell(String text, {bool borderRight = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      decoration: borderRight
          ? const pw.BoxDecoration(
              border: pw.Border(
                right: pw.BorderSide(color: PdfColors.black, width: 1),
              ),
            )
          : null,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildTableCellContent(
    String text, {
    bool borderRight = false,
    bool centered = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      decoration: borderRight
          ? const pw.BoxDecoration(
              border: pw.Border(
                right: pw.BorderSide(color: PdfColors.black, width: 1),
              ),
            )
          : null,
      alignment: centered ? pw.Alignment.center : pw.Alignment.centerLeft,
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  pw.Widget _buildServicePaperFooterBlock(CriServiceModel cri) {
    final borderSide = pw.BorderSide(color: PdfColors.black, width: 1);
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Row(
        children: [
          // Intervenant col
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                border: pw.Border(right: borderSide),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Intervenant Novadis :',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    cri.technicianName,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Mail de contact : sav@novadis.eu', // Changed to SAV for service
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Signature :',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  if (cri.technicianSignature != null && !cri.isDraft)
                    _buildSignature(cri.technicianSignature!)
                  else
                    pw.SizedBox(height: 40),
                ],
              ),
            ),
          ),
          // Client col
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(5),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Client :', style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 2),
                  pw.Text('Société :', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    cri.clientName,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Mail de contact :',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  if (cri.email != null)
                    pw.Text(
                      cri.email!,
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Signature :',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  if (cri.clientSignature != null && !cri.isDraft)
                    _buildSignature(cri.clientSignature!)
                  else
                    pw.SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Génère un PDF pour un CRI Projet (Format Papier Spécifique)

  // ============================================================
  // Helpers Format Papier (Nouveau Design)
  // ============================================================

  pw.Widget _buildPaperHeader(
    pw.ImageProvider? logo, {
    String title = "COMPTE RENDU D'INTERVENTION PROJET",
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logo != null)
          pw.Image(logo, width: 120) // Logo un peu plus grand
        else
          pw.Text(
            'novadis',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                color: novadisBlue,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPaperBottomAddress() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'novadis',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '14, rue Clément Bayard',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              '92300 Levallois Perret',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'T +33 (0)1 41 34 09 90',
              style: const pw.TextStyle(fontSize: 8),
            ),
            pw.Text(
              'F +33 (0)1 41 34 09 91',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'contact@novadis.eu',
              style: const pw.TextStyle(fontSize: 8, color: novadisBlue),
            ),
            pw.Text(
              'Novadis.eu',
              style: const pw.TextStyle(fontSize: 8, color: novadisBlue),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPaperRow({
    required List<pw.Widget> children,
    bool borderBottom = false,
  }) {
    return pw.Container(
      decoration: borderBottom
          ? const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.black, width: 1),
              ),
            )
          : null,
      child: pw.Row(children: children),
    );
  }

  pw.Widget _buildPaperCell({
    required String label,
    String? value,
    int flex = 1,
    bool borderRight = false,
    pw.TextStyle? textStyle,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(5),
        decoration: borderRight
            ? const pw.BoxDecoration(
                border: pw.Border(
                  right: pw.BorderSide(color: PdfColors.black, width: 1),
                ),
              )
            : null,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '$label :',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value ?? '',
              style: textStyle ?? const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildPaperCheckbox(String label, bool value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 10,
          height: 10,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black),
          ),
          child: value
              ? pw.Center(
                  child: pw.Text('X', style: const pw.TextStyle(fontSize: 8)),
                )
              : null,
        ),
        pw.SizedBox(width: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  pw.Widget _buildPaperLabelValue(String label, String? value) {
    return pw.Row(
      children: [
        pw.Text(
          '$label : ',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.Expanded(
          child: pw.Text(value ?? '', style: const pw.TextStyle(fontSize: 10)),
        ),
      ],
    );
  }

  pw.Widget _buildSignature(String path) {
    if (path.isEmpty) return pw.SizedBox(height: 40);

    final file = File(path);
    if (file.existsSync()) {
      try {
        final bytes = file.readAsBytesSync();
        return pw.Container(
          height: 40,
          alignment: pw.Alignment.centerLeft,
          child: pw.Image(
            pw.MemoryImage(bytes),
            height: 40,
            fit: pw.BoxFit.contain,
          ),
        );
      } catch (e) {
        return pw.Text(
          '[Erreur]',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.red),
        );
      }
    }

    return pw.Container(
      height: 40,
      child: pw.Center(
        child: pw.Text(
          '[Signature non trouvée]',
          style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
        ),
      ),
    );
  }

  // ============================================================
  // Sections du PDF
  // ============================================================

  pw.Widget _buildHeader(pw.ImageProvider? logo, String title, String numero) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: novadisBlue,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          if (logo != null)
            pw.Image(logo, width: 80, height: 80)
          else
            pw.Container(
              width: 80,
              height: 80,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Center(
                child: pw.Text(
                  'NOVADIS',
                  style: pw.TextStyle(
                    color: novadisBlue,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  numero,
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Date de génération',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
              ),
              pw.Text(
                DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildProjetGeneralInfo(
    DateTime interventionDate,
    DateTime startTime,
    DateTime endTime,
    int durationMinutes,
    String projectType,
  ) {
    return _buildSection('Informations Générales', [
      _buildInfoRow('Type de projet', projectType),
      _buildInfoRow(
        'Date d\'intervention',
        DateFormat('dd/MM/yyyy').format(interventionDate),
      ),
      _buildInfoRow('Heure de début', DateFormat('HH:mm').format(startTime)),
      _buildInfoRow('Heure de fin', DateFormat('HH:mm').format(endTime)),
      _buildInfoRow(
        'Durée totale',
        '${(durationMinutes / 60).toStringAsFixed(1)}h ($durationMinutes min)',
      ),
    ]);
  }

  pw.Widget _buildClientInfoSection(
    String clientName,
    String site,
    String? address,
    String? ville,
    String? departement,
    String? contact,
    String? phone,
    String? email,
  ) {
    return _buildSection('Informations Client', [
      _buildInfoRow('Client', clientName),
      _buildInfoRow('Site', site),
      if (address != null) _buildInfoRow('Adresse', address),
      if (ville != null || departement != null)
        _buildInfoRow(
          'Ville / Dept',
          '${ville ?? ''} ${departement != null ? '($departement)' : ''}',
        ),
      if (contact != null) _buildInfoRow('Contact', contact),
      if (phone != null) _buildInfoRow('Téléphone', phone),
      if (email != null) _buildInfoRow('Email', email),
    ]);
  }

  pw.Widget _buildProjetDetailsSection(
    String projectName,
    String projectNumber,
    String projectPhase,
    String? commande,
    String? logiciel,
    String? version,
  ) {
    return _buildSection('Détails du Projet', [
      _buildInfoRow('Nom du projet', projectName),
      pw.Row(
        children: [
          pw.Expanded(child: _buildInfoRow('N° Projet', projectNumber)),
          pw.Expanded(child: _buildInfoRow('Phase', projectPhase)),
        ],
      ),
      if (commande != null) _buildInfoRow('N° Commande', commande),
      if (logiciel != null || version != null)
        _buildInfoRow(
          'Système',
          '${logiciel ?? ''} ${version != null ? '(v$version)' : ''}',
        ),
    ]);
  }

  pw.Widget _buildProjetExecutionSection(
    String typeIntervention,
    String? natureActe,
    String? actesRealisesJson,
    String workDescription,
    String? materials,
    String? problems,
  ) {
    List<String> actes = [];
    if (actesRealisesJson != null) {
      try {
        actes = List<String>.from(jsonDecode(actesRealisesJson));
      } catch (e) {
        // Ignorer l'erreur de parsing
      }
    }

    return _buildSection('Exécution', [
      pw.Row(
        children: [
          pw.Expanded(child: _buildInfoRow('Type', typeIntervention)),
          if (natureActe != null)
            pw.Expanded(child: _buildInfoRow('Nature', natureActe)),
        ],
      ),
      if (actes.isNotEmpty) _buildInfoRow('Actes réalisés', actes.join(', ')),
      _buildTextBlock('Description des travaux', workDescription),
      if (materials != null) _buildTextBlock('Matériels utilisés', materials),
      if (problems != null) _buildTextBlock('Problèmes rencontrés', problems),
    ]);
  }

  pw.Widget _buildProjetResultSection(
    String status,
    String? solutions,
    bool? clientAcceptance,
  ) {
    return _buildSection('Résultat', [
      _buildInfoRow('Statut du projet', status),
      if (solutions != null) _buildTextBlock('Solutions apportées', solutions),
      if (clientAcceptance != null)
        _buildInfoRow('Acceptation client', clientAcceptance ? 'Oui' : 'Non'),
    ]);
  }

  pw.Widget _buildValidationSection(
    String technicianName,
    String? technicianSignature,
    String? clientSignature,
    String? satisfaction,
    bool isDraft,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: lightGray),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Validation',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: novadisBlue,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Technicien: $technicianName',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 5),
                    if (technicianSignature != null && !isDraft)
                      pw.Container(
                        height: 60,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: lightGray),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '[Signature Technicien]',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      )
                    else
                      pw.Container(
                        height: 60,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: lightGray),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'Non signé',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Client', style: const pw.TextStyle(fontSize: 12)),
                    pw.SizedBox(height: 5),
                    if (clientSignature != null && !isDraft)
                      pw.Container(
                        height: 60,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: lightGray),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '[Signature Client]',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                      )
                    else
                      pw.Container(
                        height: 60,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: lightGray),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'Non signé',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (satisfaction != null) ...[
            pw.SizedBox(height: 10),
            _buildInfoRow('Satisfaction client', satisfaction),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // Widgets utilitaires
  // ============================================================

  pw.Widget _buildSection(String title, List<pw.Widget> children) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: lightGray),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: novadisBlue,
            ),
          ),
          pw.SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTextBlock(String label, String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '$label:',
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 3),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: novadisLightBlue,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // Gestion des photos et sauvegarde
  // ============================================================

  Future<void> _addPhotosPage(pw.Document pdf, String photosJson) async {
    // TODO: Parser le JSON et ajouter les photos
    // Pour l'instant, on ajoute juste une page placeholder
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) =>
            pw.Center(child: pw.Text('Photos de l\'intervention')),
      ),
    );
  }

  Future<File> _savePDF(pw.Document pdf, String filename) async {
    final output = await getApplicationDocumentsDirectory();
    final novadisDir = Directory(p.join(output.path, 'Novadis', 'CRI'));

    if (!await novadisDir.exists()) {
      await novadisDir.create(recursive: true);
    }

    final file = File(p.join(novadisDir.path, '$filename.pdf'));
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  String _formatDateForFilename(DateTime date) {
    return DateFormat('yyyyMMdd_HHmmss').format(date);
  }
}
