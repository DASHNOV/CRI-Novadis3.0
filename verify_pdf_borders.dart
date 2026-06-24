/// Script standalone pour vérifier le rendu des bordures du PDF.
/// Génère un PDF avec les mêmes styles que pdf_builder_common.dart
/// et le sauvegarde dans le répertoire courant.
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async {
  const black = PdfColor.fromInt(0xFF000000);
  const lightGray = PdfColor.fromInt(0xFFE0E0E0);

  final labelStyle = pw.TextStyle(
    fontSize: 8,
    fontWeight: pw.FontWeight.bold,
    color: black,
  );
  const valueStyle = pw.TextStyle(fontSize: 9, color: black);

  pw.Widget buildTableSection(List<pw.Widget> children) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: black, width: 0.5),
      ),
      child: pw.Column(children: children),
    );
  }

  // Version AVANT fix (gris)
  pw.Widget buildRowBefore(List<pw.Widget> cells) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: lightGray, width: 0.3),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: cells,
      ),
    );
  }

  // Version APRÈS fix (noir)
  pw.Widget buildRowAfter(List<pw.Widget> cells) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: black, width: 0.5),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: cells,
      ),
    );
  }

  pw.Widget cell(String label, String value, {bool grayBorder = false}) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
  }

  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text('TEST BORDURES PDF — Avant vs Après fix',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),

            pw.Text('AVANT (bordures grises _lightGray 0.3)',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.red)),
            pw.SizedBox(height: 4),
            buildTableSection([
              buildRowBefore([
                cell('Client :', 'Société TEST', grayBorder: true),
              ]),
              buildRowBefore([
                cell('Projet / Site :', 'Site Levallois', grayBorder: true),
                cell('Date :', '24/06/2026', grayBorder: true),
              ]),
              buildRowBefore([
                cell('Ville :', 'Levallois', grayBorder: true),
                cell('Dpt :', '92', grayBorder: true),
                cell('Début :', '09:00', grayBorder: true),
              ]),
            ]),

            pw.SizedBox(height: 20),

            pw.Text('APRÈS fix (bordures noires _black 0.5)',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.green)),
            pw.SizedBox(height: 4),
            buildTableSection([
              buildRowAfter([
                cell('Client :', 'Société TEST', grayBorder: false),
              ]),
              buildRowAfter([
                cell('Projet / Site :', 'Site Levallois', grayBorder: false),
                cell('Date :', '24/06/2026', grayBorder: false),
              ]),
              buildRowAfter([
                cell('Ville :', 'Levallois', grayBorder: false),
                cell('Dpt :', '92', grayBorder: false),
                cell('Début :', '09:00', grayBorder: false),
              ]),
            ]),
          ],
        );
      },
    ),
  );

  final bytes = await pdf.save();
  final file = File('verify_borders_output.pdf');
  await file.writeAsBytes(bytes);
  print('PDF généré : ${file.absolute.path}');
}
