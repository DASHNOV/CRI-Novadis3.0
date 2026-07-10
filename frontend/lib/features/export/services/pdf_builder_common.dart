import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

import '../../../data/local/tables/cri_service_table.dart';
import '../../../data/local/tables/cri_projet_table.dart';
import '../../../data/models/cri_projet_model.dart';
import '../../../data/models/cri_service_model.dart';

/// Mixin contenant toute la logique de construction PDF partagée entre natif et web.
/// Ne dépend PAS de dart:io.
mixin PdfBuilderCommon {
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

  Future<void> loadLogo() async {
    if (_logo != null) return;
    try {
      final logoData = await rootBundle.load('assets/logos/novadis_logo_blanc.jpg');
      _logo = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      debugPrint('[PDF] Logo non trouvé: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════
  // SIGNATURES — résolution chemin fichier ou base64
  // ════════════════════════════════════════════════════════════════

  /// Résout une donnée de signature (chemin fichier PNG ou base64) en bytes.
  /// Délègue à [resolveFilePhoto] pour les chemins fichiers.
  Future<Uint8List?> _resolveSignatureBytes(String? signatureData) async {
    if (signatureData == null || signatureData.isEmpty) return null;
    try {
      // Cas 1 : data URI base64 (ex: data:image/png;base64,...)
      if (signatureData.startsWith('data:')) {
        final cleanBase64 = signatureData.split(',').last;
        return Uint8List.fromList(base64Decode(cleanBase64));
      }
      // Cas 2 : base64 brut (très long, pas un chemin)
      if (signatureData.length > 500) {
        return Uint8List.fromList(base64Decode(signatureData));
      }
      // Cas 3 : chemin de fichier — déléguer à la plateforme
      final image = await resolveFilePhoto(signatureData);
      if (image != null) return image.bytes;
    } catch (e) {
      debugPrint('[PDF] Erreur résolution signature: $e');
    }
    return null;
  }

  // ════════════════════════════════════════════════════════════════
  // Construction du document CRI Service
  // ════════════════════════════════════════════════════════════════

  Future<pw.Document> buildCriServiceDocument(CriServiceModel cri) async {
    await loadLogo();

    // Pré-charger toutes les signatures techniciens + client
    final techSigBytesList = await Future.wait(
      cri.technicianSignatures.map((s) => _resolveSignatureBytes(s)),
    );
    final clientSigBytes = await _resolveSignatureBytes(cri.clientSignature);

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
              _buildHeader('COMPTE RENDU D\'INTERVENTION SERVICES'),
              pw.SizedBox(height: 12),
              _buildTableSection([
                _buildRow([_buildCell('Client :', cri.clientName, bold: true)]),
              ]),
              pw.SizedBox(height: 6),
              _buildTableSection([
                _buildRow([
                  _buildCell('Projet / Site :', cri.site, flex: 3),
                  _buildCell(
                    'Date :',
                    cri.endDate != null
                        ? '${dateFormat.format(cri.interventionDate)}  - ${dateFormat.format(cri.endDate!)}'
                        : dateFormat.format(cri.interventionDate),
                    flex: 2,
                  ),
                ]),
              ]),
              pw.SizedBox(height: 6),
              _buildTableSection([
                _buildRow([
                  _buildCell('Ville :', cri.ville ?? '', flex: 3),
                  _buildCell('Dpt :', cri.departement, flex: 1),
                  _buildCell(
                    'Début d\'intervention :',
                    timeFormat.format(cri.startTime),
                    flex: 2,
                  ),
                ]),
              ]),
              pw.SizedBox(height: 6),
              _buildTableSection([
                _buildRow([
                  _buildCheckboxGroup([
                    _checkbox(
                      'Maintenance préventive',
                      cri.requestType ==
                          ServiceRequestType.maintenancePreventive,
                    ),
                    _checkbox(
                      'Maintenance curative',
                      cri.requestType ==
                          ServiceRequestType.maintenanceCorrective,
                    ),
                    _checkbox(
                      'Dépannage',
                      cri.requestType == ServiceRequestType.depannage,
                    ),
                    _checkbox(
                      'Support technique',
                      cri.requestType == ServiceRequestType.supportTechnique,
                    ),
                  ], flex: 2),
                  _buildCheckboxGroup([
                    _checkbox(
                      'Sous contrat',
                      cri.contratType == ServiceContratType.sousContrat,
                    ),
                    _checkbox(
                      'Hors contrat',
                      cri.contratType == ServiceContratType.horsContrat,
                    ),
                  ], flex: 2),
                  _buildCheckboxGroup([
                    _checkbox(
                      'Vidéo',
                      cri.systemTypes.contains(ServiceSystemType.video),
                    ),
                    _checkbox(
                      'Contrôle d\'accès',
                      cri.systemTypes.contains(
                        ServiceSystemType.controleAcces,
                      ),
                    ),
                    _checkbox(
                      'Intrusion',
                      cri.systemTypes.contains(ServiceSystemType.intrusion),
                    ),
                    _checkbox(
                      'Hypervision',
                      cri.systemTypes.contains(ServiceSystemType.hypervision),
                    ),
                  ], flex: 2),
                ]),
              ]),
              pw.SizedBox(height: 6),
              _buildTableSection([
                _buildLabelValueBlock(
                  'Motif Intervention :',
                  cri.requestDescription,
                ),
              ]),
              pw.SizedBox(height: 6),
              _buildTableSection([
                _buildLinedTextBlock(
                  'Travail Effectué :',
                  cri.actionsPerformed,
                  lineCount: 10,
                ),
                if (cri.diagnosticPerformed != null &&
                    cri.diagnosticPerformed!.isNotEmpty)
                  _buildLabelValueBlock(
                    'Diagnostic :',
                    cri.diagnosticPerformed!,
                  ),
              ]),
              pw.SizedBox(height: 6),
              _buildTableSection([
                _buildRow([
                  _buildCheckboxGroup(
                    [
                      _checkbox(
                        'Terminée',
                        cri.resolutionStatus == ResolutionStatus.resolu ||
                            (!cri.additionalInterventionRequired &&
                                !cri.devisARealiser &&
                                !cri.facturable),
                      ),
                      _checkbox('A Suivre', cri.additionalInterventionRequired),
                      _checkbox('Devis à réaliser', cri.devisARealiser),
                      _checkbox('Facturable', cri.facturable),
                    ],
                    flex: 4,
                    horizontal: true,
                  ),
                  _buildCell(
                    'Fin d\'intervention :',
                    cri.endDate != null
                        ? '${dateFormat.format(cri.endDate!)} ${timeFormat.format(cri.endTime)} H'
                        : '${timeFormat.format(cri.endTime)} H',
                    flex: 2,
                  ),
                ]),
              ]),
              pw.SizedBox(height: 6),
              _buildTableSection([
                _buildLabelValueBlock(
                  'Remarques Client :',
                  cri.recommendations ?? '',
                ),
              ]),
              pw.SizedBox(height: 6),
              _buildSignatureBlock(
                techNames: cri.technicianNames.isNotEmpty ? cri.technicianNames : [cri.technicianName],
                techEmail: 'sav@novadis.eu',
                clientName: cri.clientName,
                clientEmail: cri.email,
                techSignatureBytesList: techSigBytesList,
                clientSignatureBytes: clientSigBytes,
              ),
              pw.SizedBox(height: 12),
              _buildFooter(),
            ],
          );
        },
      ),
    );

    if (cri.photos.isNotEmpty) {
      await _addPhotosPages(pdf, cri.photos);
    }

    return pdf;
  }

  // ════════════════════════════════════════════════════════════════
  // Construction du document CRI Projet
  // (Conforme au modèle officiel Novadis)
  // ════════════════════════════════════════════════════════════════

  Future<pw.Document> buildCriProjetDocument(CriProjetModel cri) async {
    await loadLogo();

    // Pré-charger toutes les signatures techniciens + client
    final techSigBytesList = await Future.wait(
      cri.technicianSignatures.map((s) => _resolveSignatureBytes(s)),
    );
    final clientSigBytes = await _resolveSignatureBytes(cri.clientSignature);

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

              // ─── Projet / Site + Date ───
              _buildTableSection([
                _buildRow([
                  _buildCell('Projet / Site :', cri.site, flex: 3),
                  _buildCell(
                    'Date :',
                    cri.endDate != null
                        ? '${dateFormat.format(cri.interventionDate)}  - ${dateFormat.format(cri.endDate!)}'
                        : dateFormat.format(cri.interventionDate),
                    flex: 2,
                  ),
                ]),
              ]),
              pw.SizedBox(height: 6),

              // ─── Ville / Dpt / Début d'intervention ───
              _buildTableSection([
                _buildRow([
                  _buildCell('Ville :', cri.ville ?? '', flex: 3),
                  _buildCell('Dpt :', cri.departement, flex: 1),
                  _buildCell(
                    'Début d\'intervention :',
                    timeFormat.format(cri.startTime),
                    flex: 2,
                  ),
                ]),
              ]),
              pw.SizedBox(height: 6),

              // ─── Commande + Logiciel ───
              _buildTableSection([
                _buildRow([
                  _buildCell(
                    'Commande n°',
                    cri.projectNumber.startsWith('CC') ? cri.projectNumber : '',
                    flex: 2,
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: _buildSoftwaresCell(cri.softwares),
                    ),
                  ),
                ]),
              ]),
              pw.SizedBox(height: 6),

              // ─── Travail Effectué (grande section avec lignes) ───
              _buildTableSection([
                _buildLinedTextBlock(
                  'Travail Effectué :',
                  cri.workDescription,
                  lineCount: 15,
                ),
              ]),

              pw.Spacer(),

              // ─── Checkboxes bas + Fin d'intervention ───
              _buildTableSection([
                _buildRow([
                  pw.Expanded(
                    flex: 4,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Row(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(right: 12),
                                child: _checkbox(
                                  'Mise en service',
                                  cri.interventionType == ProjetInterventionType.installationMateriel,
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(right: 12),
                                child: _checkbox(
                                  'Formation',
                                  cri.interventionType == ProjetInterventionType.formation,
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(right: 12),
                                child: _checkbox(
                                  'Visite de site',
                                  cri.interventionType == ProjetInterventionType.visiteeDeSite,
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(right: 12),
                                child: _checkbox(
                                  'Audit',
                                  cri.interventionType == ProjetInterventionType.audit,
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(right: 12),
                                child: _checkbox(
                                  'Mise à jour',
                                  cri.interventionType == ProjetInterventionType.miseAJour,
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(right: 12),
                                child: _checkbox(
                                  'Autre',
                                  cri.interventionType == ProjetInterventionType.autre,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildCell(
                    'Fin d\'intervention :',
                    cri.endDate != null
                        ? '${dateFormat.format(cri.endDate!)} ${timeFormat.format(cri.endTime)} H'
                        : '${timeFormat.format(cri.endTime)} H',
                    flex: 2,
                  ),
                ]),
              ]),
              pw.SizedBox(height: 6),

              // ─── Remarques Client ───
              _buildTableSection([
                _buildLabelValueBlock(
                  'Remarques Client :',
                  cri.clientComments ?? '',
                ),
              ]),
              pw.SizedBox(height: 6),

              // ─── Signatures ───
              _buildSignatureBlock(
                techNames: cri.technicianNames.isNotEmpty ? cri.technicianNames : [cri.technicianName],
                techEmail: 'tech@novadis.eu',
                clientName: cri.clientName,
                clientEmail: cri.email,
                techSignatureBytesList: techSigBytesList,
                clientSignatureBytes: clientSigBytes,
              ),
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

    return pdf;
  }

  // ════════════════════════════════════════════════════════════════
  // COMPOSANTS PDF RÉUTILISABLES
  // ════════════════════════════════════════════════════════════════

  pw.Widget _buildHeader(String title) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (_logo != null)
          pw.Image(_logo!, width: 90)
        else
          pw.Text(
            'novadis',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: _black,
            ),
          ),
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

  pw.Widget _buildTableSection(List<pw.Widget> children) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _black, width: 0.5),
      ),
      child: pw.Column(children: children),
    );
  }

  pw.Widget _buildRow(List<pw.Widget> cells) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _black, width: 0.5),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: cells,
      ),
    );
  }

  pw.Widget _buildCell(
    String label,
    String value, {
    int flex = 1,
    bool bold = false,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            right: pw.BorderSide(color: _black, width: 0.5),
          ),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(label, style: _labelStyle),
            pw.SizedBox(height: 1),
            // Valeur toujours présente (espace insécable si vide) pour que
            // toutes les cellules d'une ligne aient la même hauteur et que les
            // séparateurs verticaux descendent jusqu'au bas de la ligne.
            pw.Text(
              value.isEmpty ? ' ' : value,
              style: bold
                  ? pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _black,
                    )
                  : _valueStyle,
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildLabelValueBlock(String label, String value) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _black, width: 0.5),
        ),
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

  /// Bloc avec label + texte + lignes horizontales (style formulaire papier).
  /// La hauteur est fixe (lineCount × 18 px) — le texte est superposé sur les
  /// lignes et tronqué s'il dépasse l'espace disponible.
  pw.Widget _buildLinedTextBlock(
    String label,
    String value, {
    int lineCount = 15,
  }) {
    const lineHeight = 18.0;
    final totalHeight = lineCount * lineHeight;

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: _labelStyle),
          pw.SizedBox(height: 4),
          pw.SizedBox(
            height: totalHeight,
            width: double.infinity,
            child: value.isNotEmpty
                ? pw.Text(
                    value,
                    style: _valueStyle,
                    maxLines: lineCount,
                    overflow: pw.TextOverflow.clip,
                  )
                : pw.SizedBox(),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCheckboxGroup(
    List<pw.Widget> checkboxes, {
    int flex = 1,
    bool horizontal = false,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: horizontal
            ? pw.Row(
                children: checkboxes
                    .map(
                      (c) => pw.Padding(
                        padding: const pw.EdgeInsets.only(right: 12),
                        child: c,
                      ),
                    )
                    .toList(),
              )
            : pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisSize: pw.MainAxisSize.min,
                children: checkboxes,
              ),
      ),
    );
  }

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
                ? pw.Center(
                    child: pw.Text(
                      'X',
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  )
                : pw.SizedBox(),
          ),
          pw.SizedBox(width: 4),
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  /// Bloc signatures — prend les bytes pré-chargés (pas de base64/chemin).
  /// Supporte plusieurs techniciens (liste de noms + signatures).
  pw.Widget _buildSignatureBlock({
    required List<String> techNames,
    required String techEmail,
    required String clientName,
    String? clientEmail,
    required List<Uint8List?> techSignatureBytesList,
    Uint8List? clientSignatureBytes,
  }) {
    final effectiveNames = techNames.isEmpty ? [''] : techNames;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _black, width: 0.5),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Techniciens (empilés verticalement si plusieurs)
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(6),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  right: pw.BorderSide(color: _black, width: 0.5),
                ),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    effectiveNames.length > 1
                        ? 'Intervenants Novadis :'
                        : 'Intervenant Novadis :',
                    style: _labelStyle,
                  ),
                  pw.SizedBox(height: 2),
                  ...effectiveNames.asMap().entries.map((entry) {
                    final i = entry.key;
                    final name = entry.value;
                    final sigBytes = i < techSignatureBytesList.length
                        ? techSignatureBytesList[i]
                        : null;
                    return pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (i > 0)
                          pw.Divider(color: _lightGray, thickness: 0.5),
                        pw.Text(
                          name,
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (i == 0)
                          pw.Text(
                            'Mail : $techEmail',
                            style: _smallStyle,
                          ),
                        pw.SizedBox(height: 2),
                        pw.Text('Signature :', style: _labelStyle),
                        _buildSignatureFromBytes(sigBytes),
                      ],
                    );
                  }),
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
                  pw.Text(
                    clientName,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (clientEmail != null && clientEmail.isNotEmpty)
                    pw.Text(
                      'Mail de contact :\n$clientEmail',
                      style: _smallStyle,
                    ),
                  pw.SizedBox(height: 4),
                  pw.Text('Signature :', style: _labelStyle),
                  _buildSignatureFromBytes(clientSignatureBytes),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche une signature depuis ses bytes pré-chargés
  pw.Widget _buildSignatureFromBytes(Uint8List? bytes) {
    if (bytes != null && bytes.isNotEmpty) {
      try {
        return pw.Container(
          height: 50,
          alignment: pw.Alignment.centerLeft,
          child: pw.Image(
            pw.MemoryImage(bytes),
            height: 46,
          ),
        );
      } catch (e) {
        debugPrint('[PDF] Erreur rendu signature: $e');
      }
    }
    return pw.Container(height: 50);
  }

  /// Construit la cellule "Logiciel / Version" pour le CRI Projet.
  /// Affiche la liste des logiciels sélectionnés avec leur version
  /// (ou "-" si aucune version saisie). Si la liste est vide, reste
  /// sur l'affichage placeholder pour compatibilité.
  pw.Widget _buildSoftwaresCell(List<SoftwareEntry> softwares) {
    if (softwares.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('Logiciel :', style: _labelStyle),
          pw.SizedBox(height: 1),
          pw.Text('Version :', style: _labelStyle),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('Logiciel(s) :', style: _labelStyle),
        pw.SizedBox(height: 2),
        ...softwares.map((s) {
          final version = (s.version == null || s.version!.trim().isEmpty)
              ? '-'
              : s.version!.trim();
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 1),
            child: pw.Text(
              '${s.software.label} (v. $version)',
              style: _valueStyle,
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: _blue, thickness: 1),
        pw.SizedBox(height: 4),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (_logo != null)
              pw.Image(_logo!, width: 60)
            else
              pw.Text(
                'novadis',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            pw.SizedBox(width: 16),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('14, rue Clément Bayard', style: _smallStyle),
                pw.Text('92300 Levallois Perret', style: _smallStyle),
              ],
            ),
            pw.SizedBox(width: 16),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('T +33 (0)1 41 34 09 90', style: _smallStyle),
                pw.Text('F +33 (0)1 41 34 09 91', style: _smallStyle),
              ],
            ),
            pw.Spacer(),
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
  // PHOTOS
  // ════════════════════════════════════════════════════════════════

  Future<List<pw.MemoryImage>> resolvePhotos(List<String> photos) async {
    final validPhotos = <pw.MemoryImage>[];

    for (final photoPath in photos) {
      try {
        if (photoPath.startsWith('data:') ||
            photoPath.startsWith('/9j/') ||
            photoPath.length > 500) {
          final cleanBase64 = photoPath.contains(',')
              ? photoPath.split(',').last
              : photoPath;
          final bytes = base64Decode(cleanBase64);
          validPhotos.add(pw.MemoryImage(Uint8List.fromList(bytes)));
        } else {
          final image = await resolveFilePhoto(photoPath);
          if (image != null) validPhotos.add(image);
        }
      } catch (e) {
        debugPrint('[PDF] Erreur chargement photo: $e');
      }
    }

    return validPhotos;
  }

  /// Point d'extension pour charger un fichier depuis un chemin.
  /// Retourne null par défaut (pas de support fichier sur web).
  Future<pw.MemoryImage?> resolveFilePhoto(String filePath) async => null;

  Future<void> _addPhotosPages(
    pw.Document pdf,
    List<String> photos,
  ) async {
    final validPhotos = await resolvePhotos(photos);
    if (validPhotos.isEmpty) return;

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
                      child: pw.Image(
                        validPhotos[i + 1],
                        fit: pw.BoxFit.contain,
                      ),
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

  String formatDateForFilename(DateTime date) =>
      DateFormat('yyyyMMdd_HHmmss').format(date);
}
