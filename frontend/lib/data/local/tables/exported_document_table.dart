import 'package:drift/drift.dart';

@DataClassName('ExportedDocument')
class ExportedDocumentTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get criId => text().nullable()();
  TextColumn get filename => text()();
  TextColumn get filePath => text()();
  TextColumn get fileType => text()(); // PDF, CSV
  IntColumn get fileSize => integer()();
  TextColumn get exportType => text()(); // CRI, Dashboard, Technician
  TextColumn get metadata => text().nullable()(); // JSON string
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get sharedAt => dateTime().nullable()();
}
