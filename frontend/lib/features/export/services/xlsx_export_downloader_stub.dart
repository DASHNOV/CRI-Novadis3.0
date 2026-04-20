import 'dart:typed_data';

/// Implémentation plateforme-spécifique pour délivrer le XLSX téléchargé.
/// Retourne soit un `File` (natif) soit un `String` (nom de fichier sur web).
Future<dynamic> deliverXlsx(Uint8List bytes, String filename) {
  throw UnsupportedError('Pas d\'implémentation pour cette plateforme');
}
