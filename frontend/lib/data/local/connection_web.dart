import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'cri_novadis_db', // Nom explicite
      sqlite3Uri: Uri.parse('https://unpkg.com/@sql.js/sql.js@1.10.3/dist/sql-wasm.wasm'),
      driftWorkerUri: Uri.parse('https://unpkg.com/drift@2.20.0/dist/drift_worker.js'),
    );
    return result.resolvedExecutor;
  });
}
