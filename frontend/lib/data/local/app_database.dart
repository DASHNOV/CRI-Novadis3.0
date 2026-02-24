import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  AppDatabase() : super(_openConnection());

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
          // Ajouter la colonne cybersecurity_recommendations si elle manque
          await m.addColumn(criServiceTable, criServiceTable.cybersecurityRecommendations);
        }
      },
    );
  }

  // CRI Service Methods
  Future<List<CriService>> getAllCriService() => select(criServiceTable).get();
  Stream<List<CriService>> watchAllCriService() =>
      select(criServiceTable).watch();

  Future<CriService?> getCriServiceById(String id) {
    return (select(
      criServiceTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertCriService(CriServiceTableCompanion cri) {
    return into(criServiceTable).insert(cri);
  }

  Future<bool> updateCriService(CriServiceTableCompanion cri) async {
    await into(criServiceTable).insertOnConflictUpdate(cri);
    return true;
  }

  // CRI Projet Methods
  Future<List<CriProjet>> getAllCriProjet() => select(criProjetTable).get();
  Stream<List<CriProjet>> watchAllCriProjet() => select(criProjetTable).watch();

  Future<CriProjet?> getCriProjetById(String id) {
    return (select(
      criProjetTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertCriProjet(CriProjetTableCompanion cri) {
    return into(criProjetTable).insert(cri);
  }

  Future<bool> updateCriProjet(CriProjetTableCompanion cri) async {
    await into(criProjetTable).insertOnConflictUpdate(cri);
    return true;
  }

  Future<int> deleteCriProjet(String id) {
    return (delete(criProjetTable)..where((t) => t.id.equals(id))).go();
  }

  // CRI Service Delete Method
  Future<int> deleteCriService(String id) {
    return (delete(criServiceTable)..where((t) => t.id.equals(id))).go();
  }

  // Exported Document Methods
  Future<List<ExportedDocument>> getAllExportedDocuments() =>
      select(exportedDocumentTable).get();

  Future<List<ExportedDocument>> getExportedDocumentsByType(String type) {
    return (select(
      exportedDocumentTable,
    )..where((t) => t.fileType.equals(type))).get();
  }

  Future<List<ExportedDocument>> getExportedDocumentsByCriId(String id) {
    return (select(
      exportedDocumentTable,
    )..where((t) => t.criId.equals(id))).get();
  }

  Future<ExportedDocument?> getExportedDocumentById(int id) {
    return (select(
      exportedDocumentTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertExportedDocument(ExportedDocumentTableCompanion doc) {
    return into(exportedDocumentTable).insert(doc);
  }

  Future<bool> updateExportedDocument(ExportedDocumentTableCompanion doc) {
    return update(exportedDocumentTable).replace(doc);
  }

  Future<int> deleteExportedDocument(int id) {
    return (delete(exportedDocumentTable)..where((t) => t.id.equals(id))).go();
  }

  Future<int> updateSharedAt(int id, DateTime date) {
    return (update(exportedDocumentTable)..where((t) => t.id.equals(id))).write(
      ExportedDocumentTableCompanion(sharedAt: Value(date)),
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

extension CriProjetUtils on CriProjet {
  int get interventionDurationMinutes =>
      endTime.difference(startTime).inMinutes;
}
