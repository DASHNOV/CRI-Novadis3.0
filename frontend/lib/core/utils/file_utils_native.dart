import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'file_utils_stub.dart';

class FileUtilsNative implements FileUtils {
  @override
  Future<void> saveBytesToFile(Uint8List bytes, String path) async {
    final file = File(path);
    final directory = Directory(file.parent.path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    await file.writeAsBytes(bytes);
  }

  @override
  Future<String> saveSignature(Uint8List bytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final signatureDir = Directory('${directory.path}/signatures');
    if (!await signatureDir.exists()) {
      await signatureDir.create(recursive: true);
    }
    final filePath = '${signatureDir.path}/$fileName';
    await saveBytesToFile(bytes, filePath);
    return filePath;
  }

  @override
  bool fileExists(String path) {
    return File(path).existsSync();
  }

  @override
  Widget getFileWidget(String path) {
    return Image.file(
      File(path),
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
    );
  }
}

FileUtils createFileUtils() => FileUtilsNative();
