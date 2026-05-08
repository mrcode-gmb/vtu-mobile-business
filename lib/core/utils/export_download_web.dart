// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

Future<bool> downloadExportFile({
  required List<int> bytes,
  required String fileName,
  required String mimeType,
}) async {
  final html.Blob blob = html.Blob(<Object>[bytes], mimeType);
  final String url = html.Url.createObjectUrlFromBlob(blob);
  final html.AnchorElement anchor =
      html.AnchorElement(href: url)
        ..download = fileName
        ..style.display = 'none';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);

  return true;
}
