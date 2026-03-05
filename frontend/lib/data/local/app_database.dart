import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import conditionnel
import 'connection_stub.dart'
    if (dart.library.html) 'connection_web.dart'
    if (dart.library.io) 'connection_native.dart';

import 'tables/cri_service_table.dart';
import 'tables/cri_projet_table.dart';
import 'tables/exported_document_table.dart';

part 'app_database.g.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

@DriftDatabase(tables: [CriServiceTable, CriProjetTable, ExportedDocumentTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(criServiceTable, criServiceTable.cybersecurityRecommendations);
        }
      },
    );
  }

  // CRI Service Methods
  Future<List<CriService>> getAllCriService() => select(criServiceTable).get();
  Stream<List<CriService>> watchAllCriService() => select(criServiceTable).watch();
  Future<CriService?> getCriServiceById(String id) => (select(criServiceTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<int> insertCriService(CriServiceTableCompanion cri) => into(criServiceTable).insert(cri);
  Future<bool> updateCriService(CriServiceTableCompanion cri) async {
    await into(criServiceTable).insertOnConflictUpdate(cri);
    return true;
  }

  // CRI Projet Methods
  Future<List<CriProjet>> getAllCriProjet() => select(criProjetTable).get();
  Stream<List<CriProjet>> watchAllCriProjet() => select(criProjetTable).watch();
  Future<CriProjet?> getCriProjetById(String id) => (select(criProjetTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<int> insertCriProjet(CriProjetTableCompanion cri) => into(criProjetTable).insert(cri);
  Future<bool> updateCriProjet(CriProjetTableCompanion cri) async {
    await into(criProjetTable).insertOnConflictUpdate(cri);
    return true;
  }
  Future<int> deleteCriProjet(String id) => (delete(criProjetTable)..where((t) => t.id.equals(id))).go();
  Future<int> deleteCriService(String id) => (delete(criServiceTable)..where((t) => t.id.equals(id))).go();

  // Exported Document Methods
  Future<List<ExportedDocument>> getAllExportedDocuments() => select(exportedDocumentTable).get();
  Future<List<ExportedDocument>> getExportedDocumentsByType(String type) => (select(exportedDocumentTable)..where((t) => t.fileType.equals(type))).get();
  Future<List<ExportedDocument>> getExportedDocumentsByCriId(String id) => (select(exportedDocumentTable)..where((t) => t.criId.equals(id))).get();
  Future<ExportedDocument?> getExportedDocumentById(int id) => (select(exportedDocumentTable)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<int> insertExportedDocument(ExportedDocumentTableCompanion doc) => into(exportedDocumentTable).insert(doc);
  Future<bool> updateExportedDocument(ExportedDocumentTableCompanion doc) => update(exportedDocumentTable).replace(doc);
  Future<int> deleteExportedDocument(int id) => (delete(exportedDocumentTable)..where((t) => t.id.equals(id))).go();
  Future<int> updateSharedAt(int id, DateTime date) => (update(exportedDocumentTable)..where((t) => t.id.equals(id))).write(
      ExportedDocumentTableCompanion(sharedAt: Value(date)),
    );
}

extension CriProjetUtils on CriProjet {
  int get interventionDurationMinutes => endTime.difference(startTime).inMinutes;
}
