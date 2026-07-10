import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

/// Écrit le binaire en fichier temporaire puis l'ouvre dans le viewer natif.
Future<void> openDocumentBytes(
  Uint8List bytes,
  String filename,
  String fileType,
) async {
  final dir = await getTemporaryDirectory();
  final safeName = filename.trim().isEmpty
      ? 'document.${fileType.toLowerCase()}'
      : _sanitize(filename);
  final file = File(p.join(dir.path, safeName));
  await file.writeAsBytes(bytes, flush: true);

  final result = await OpenFilex.open(file.path);
  if (result.type != ResultType.done) {
    throw Exception(result.message);
  }
}

String _sanitize(String name) =>
    name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
