import 'dart:typed_data';

abstract class FileUtils {
  Future<void> saveBytesToFile(Uint8List bytes, String path);
  Future<String> saveSignature(Uint8List bytes, String fileName);
  bool fileExists(String path);
  dynamic getFileWidget(String path);
}

FileUtils createFileUtils() => throw UnimplementedError();
