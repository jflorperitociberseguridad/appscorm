class ApiConfig {
  /// Base URL for the REST backend (update to point at your MariaDB-backed API).
  static const String baseUrl = 'https://gestion.cibermedida.es';
  static const String apiPrefix = '/api';

  static Uri endpoint(String path, [Map<String, dynamic>? query]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$baseUrl$apiPrefix$normalizedPath');
    if (query == null || query.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...query.map((key, value) => MapEntry(key, value.toString())),
    });
  }
}
