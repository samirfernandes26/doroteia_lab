import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

Future<void> exportBudgetImage(Uint8List pngBytes, String fileName) async {
  await SharePlus.instance.share(
    ShareParams(
      title: 'Orçamento Doroteia Lab',
      files: [XFile.fromData(pngBytes, mimeType: 'image/png')],
      fileNameOverrides: [fileName],
    ),
  );
}
