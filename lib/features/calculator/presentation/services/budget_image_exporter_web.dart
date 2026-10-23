import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> exportBudgetImage(Uint8List pngBytes, String fileName) async {
  final parts = <JSAny>[pngBytes.toJS].toJS;
  final blob = web.Blob(parts, web.BlobPropertyBag(type: 'image/png'));
  final objectUrl = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = objectUrl
    ..download = fileName
    ..style.display = 'none';

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(objectUrl);
}
