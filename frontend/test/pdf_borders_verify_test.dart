/// Test de vérification des bordures PDF après fix.
/// Génère un PDF et le sauvegarde dans frontend/test/pdf_borders_output.pdf
/// Exécuter avec: dart test test/pdf_borders_verify_test.dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Génère un PDF avec bordures noires (après fix)', () async {
    const black = PdfColor.fromInt(0xFF000000);
    const lightGray = PdfColor.fromInt(0xFFE0E0E0);
    const blue = PdfColor.fromInt(0xFF0066CC);

    final labelStyle = pw.TextStyle(
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: black,
    );
    const valueStyle = pw.TextStyle(fontSize: 9, color: black);

    // Bordure externe d'un bloc (inchangée — était déjà noire)
    pw.Widget buildSection(List<pw.Widget> children) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: black, width: 0.5),
          ),
          child: pw.Column(children: children),
        );

    // Séparateur horizontal AVANT fix (gris)
    pw.Widget rowBefore(List<pw.Widget> cells) => pw.Container(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: lightGray, width: 0.3),
            ),
          ),
          child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start, children: cells),
        );

    // Séparateur horizontal APRÈS fix (noir)
    pw.Widget rowAfter(List<pw.Widget> cells) => pw.Container(
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: black, width: 0.5),
            ),
          ),
          child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start, children: cells),
        );

    pw.Widget cell(String label, String value, {required bool grayBorder}) =>
        pw.Expanded(
          child: pw.Container(
            padding:
                const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                right: pw.BorderSide(
                  color: grayBorder ? lightGray : black,
                  width: grayBorder ? 0.3 : 0.5,
                ),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(label, style: labelStyle),
                pw.SizedBox(height: 1),
                pw.Text(value, style: valueStyle),
              ],
            ),
          ),
        );

    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text('VÉRIFICATION BORDURES CRI — Avant / Après fix',
              style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: blue)),
          pw.SizedBox(height: 16),

          // ─── AVANT ───
          pw.Text('AVANT fix  (_lightGray 0xFFE0E0E0, width 0.3)',
              style: pw.TextStyle(
                  fontSize: 9,
                  color: const PdfColor.fromInt(0xFFCC0000),
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          buildSection([
            rowBefore([
              cell('Client :', 'Société TEST', grayBorder: true),
            ]),
            rowBefore([
              cell('Projet / Site :', 'Site Levallois', grayBorder: true),
              cell('Date :', '24/06/2026', grayBorder: true),
            ]),
            rowBefore([
              cell('Ville :', 'Levallois', grayBorder: true),
              cell('Dpt :', '92', grayBorder: true),
              cell('Début :', '09:00', grayBorder: true),
            ]),
          ]),

          pw.SizedBox(height: 20),

          // ─── APRÈS ───
          pw.Text('APRÈS fix  (_black 0xFF000000, width 0.5)',
              style: pw.TextStyle(
                  fontSize: 9,
                  color: const PdfColor.fromInt(0xFF006600),
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          buildSection([
            rowAfter([
              cell('Client :', 'Société TEST', grayBorder: false),
            ]),
            rowAfter([
              cell('Projet / Site :', 'Site Levallois', grayBorder: false),
              cell('Date :', '24/06/2026', grayBorder: false),
            ]),
            rowAfter([
              cell('Ville :', 'Levallois', grayBorder: false),
              cell('Dpt :', '92', grayBorder: false),
              cell('Début :', '09:00', grayBorder: false),
            ]),
          ]),
        ],
      ),
    ));

    final bytes = await pdf.save();
    final out = File('test/pdf_borders_output.pdf');
    await out.writeAsBytes(bytes);
    expect(out.existsSync(), isTrue);
    print('\nPDF généré : ${out.absolute.path}');
  });
}
