import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../../models/course_model.dart';
import 'scorm_export_assets_io.dart'
    if (dart.library.html) 'scorm_export_assets_web.dart' as impl;

Map<String, String> buildScormAssetMap(CourseModel course) {
  final assets = <String, String>{};
  final nameCounts = <String, int>{};
  for (final file in course.contentBank.files) {
    final source = (file['path'] ?? '').trim();
    if (source.isEmpty) continue;
    var name = (file['name'] ?? '').trim();
    if (name.isEmpty) name = p.basename(source);
    final key = name.toLowerCase();
    final count = nameCounts[key] ?? 0;
    if (count > 0) {
      final ext = p.extension(name);
      final base = ext.isNotEmpty ? name.substring(0, name.length - ext.length) : name;
      name = '${base}_$count$ext';
    }
    nameCounts[key] = count + 1;
    assets[source] = p.posix.join('materials', name);
  }
  return assets;
}

Future<void> addScormAssetsToArchive(Archive archive, Map<String, String> assetMap) async {
  await impl.addScormAssetsToArchive(archive, assetMap);
}
