import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Handles loading secrets from the local asset bundle in a safe way.
class SecretLoader {
  SecretLoader._();

  static const _assetPath = 'assets/config/secrets.json';

  /// Loads the secrets map. Returns an empty map if the file is missing, empty,
  /// or invalid, and logs a warning so developers can restore it manually.
  static Future<Map<String, String>> load() async {
    try {
      final content = await rootBundle.loadString(_assetPath);
      if (content.trim().isEmpty) {
        _logMissing();
        return {};
      }

      final raw = json.decode(content) as Map<String, dynamic>;
      return raw.map((key, value) => MapEntry(key, value?.toString() ?? ''));
    } catch (error) {
      if (error is FlutterError) {
        _logMissing();
      } else if (error is FormatException) {
        _logInvalid(error);
      } else {
        _logUnexpected(error);
      }
      return {};
    }
  }

  static void _logMissing() {
    debugPrint(
      '⚠️ Archivo secrets.json no encontrado. Usando configuración por defecto o variables de entorno.',
    );
  }

  static void _logInvalid(FormatException error) {
    debugPrint(
      '⚠️ Archivo secrets.json contiene JSON inválido (${error.message}). Usando configuración por defecto o variables de entorno.',
    );
  }

  static void _logUnexpected(Object error) {
    debugPrint(
      '⚠️ Error inesperado al cargar secrets.json (${error.runtimeType}). Usando configuración por defecto o variables de entorno.',
    );
  }
}
