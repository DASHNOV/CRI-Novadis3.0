import 'dart:typed_data';

/// Ouvre (prévisualise) un document selon la plateforme.
/// Web : nouvel onglet navigateur (preview PDF native).
/// Natif : fichier temporaire + viewer du système.
Future<void> openDocumentBytes(
  Uint8List bytes,
  String filename,
  String fileType,
) {
  throw UnsupportedError("Ouverture non supportée sur cette plateforme");
}
