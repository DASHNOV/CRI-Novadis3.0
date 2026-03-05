import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
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
