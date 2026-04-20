// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

const _xlsxMime = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

Future<dynamic> deliverXlsx(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes], _xlsxMime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
  return filename;
}
