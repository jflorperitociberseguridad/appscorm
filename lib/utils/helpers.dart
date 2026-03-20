import 'package:uuid/uuid.dart';

class AppHelpers {
  static const _uuid = Uuid();

  /// Genera un ID único para bloques o módulos
  static String generateId() {
    return _uuid.v4();
  }

  /// Formatea la duración (ej: segundos a mm:ss)
  static String formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Limpia texto HTML simple para previews
  static String stripHtml(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim();
  }
}