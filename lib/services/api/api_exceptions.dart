class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Object? details;

  ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message, details: $details)';
}
