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
    // Sur le Web, on retourne juste un identifiant/chemin factice pour l'instant
    // car le stockage local de fichiers n'est pas supporté de la même manière.
    return 'web_signature_$fileName';
  }

  @override
  bool fileExists(String path) {
    return false; // Pas de système de fichiers direct sur le Web
  }

  @override
  Widget getFileWidget(String path) {
    return Image.network(
      path,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
    );
  }
}

FileUtils createFileUtils() => FileUtilsWeb();
