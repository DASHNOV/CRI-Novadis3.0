import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'file_utils_stub.dart';

class FileUtilsWeb implements FileUtils {
  @override
  Future<void> saveBytesToFile(Uint8List bytes, String path) async {
    // Ne fait rien sur le Web (ou pourrait utiliser localStorage / indexedDB)
  }

  @override
  Future<String> saveSignature(Uint8List bytes, String fileName) async {
    final base64Str = base64Encode(bytes);
    return 'data:image/png;base64,$base64Str';
  }

  @override
  bool fileExists(String path) {
    return path.startsWith('data:');
  }

  @override
  Widget getFileWidget(String path) {
    if (path.startsWith('data:')) {
      final base64Str = path.split(',').last;
      final bytes = base64Decode(base64Str);
      return Image.memory(bytes, fit: BoxFit.contain);
    }
    return Image.network(
      path,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
    );
  }
}

FileUtils createFileUtils() => FileUtilsWeb();
