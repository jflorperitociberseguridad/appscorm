import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

Future<void> addScormAssetsToArchive(Archive archive, Map<String, String> assetMap) async {
  if (assetMap.isNotEmpty) {
    debugPrint('[SCORM] Assets omitidos en Web: rutas locales no disponibles.');
  }
}
