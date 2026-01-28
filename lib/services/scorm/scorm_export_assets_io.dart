import 'dart:io';

import 'package:archive/archive.dart';

Future<void> addScormAssetsToArchive(Archive archive, Map<String, String> assetMap) async {
  for (final entry in assetMap.entries) {
    final source = entry.key;
    if (source.startsWith('http://') || source.startsWith('https://') || source.startsWith('data:')) {
      continue;
    }
    final file = File(source);
    if (!await file.exists()) continue;
    final bytes = await file.readAsBytes();
    archive.addFile(ArchiveFile(entry.value, bytes.length, bytes));
  }
}
