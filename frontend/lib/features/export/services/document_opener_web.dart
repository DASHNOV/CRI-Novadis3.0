// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

const _mimes = <String, String>{
  'pdf': 'application/pdf',
  'xlsx':
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
};

/// Ouvre le document dans un nouvel onglet.
/// Le navigateur prévisualise nativement les PDF (pas de téléchargement).
/// Les xlsx ne sont pas prévisualisables : fallback en téléchargement.
Future<void> openDocumentBytes(
  Uint8List bytes,
  String filename,
  String fileType,
) async {
  final ft = fileType.toLowerCase();
  final mime = _mimes[ft] ?? 'application/octet-stream';
  final blob = html.Blob(<dynamic>[bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);

  // xlsx : non prévisualisable dans le navigateur -> téléchargement direct.
  if (ft != 'pdf') {
    _clickAnchor(url, download: filename);
    _revokeLater(url);
    return;
  }

  // PDF : ouverture dans un nouvel onglet (preview native du navigateur).
  // Un anchor target=_blank déclenché par un clic utilisateur n'est pas
  // bloqué par les popup-blockers (contrairement à window.open).
  _clickAnchor(url, target: '_blank');
  _revokeLater(url);
}

void _clickAnchor(String url, {String? download, String? target}) {
  final anchor = html.AnchorElement(href: url)..style.display = 'none';
  if (download != null) anchor.setAttribute('download', download);
  if (target != null) anchor.setAttribute('target', target);
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
}

// Laisse le temps à l'onglet/téléchargement de consommer l'URL avant révocation.
void _revokeLater(String url) {
  Future<void>.delayed(
    const Duration(minutes: 1),
    () => html.Url.revokeObjectUrl(url),
  );
}
