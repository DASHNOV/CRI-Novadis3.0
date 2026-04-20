import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<dynamic> deliverXlsx(Uint8List bytes, String filename) async {
  final dir = await _resolveExportDirectory();
  final file = File(p.join(dir.path, filename));
  await file.writeAsBytes(bytes, flush: true);
  return file;
}

Future<Directory> _resolveExportDirectory() async {
  final base = await getApplicationDocumentsDirectory();
  final target = Directory(p.join(base.path, 'Novadis', 'Exports'));
  if (!await target.exists()) {
    await target.create(recursive: true);
  }
  return target;
}
