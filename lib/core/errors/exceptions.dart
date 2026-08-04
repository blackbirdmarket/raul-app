/// Excepciones lanzadas por las capas de datos.
///
/// Nunca deben cruzar hacia la interfaz: los repositorios las capturan y las
/// traducen a `Failure`.
class StorageException implements Exception {
  const StorageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'StorageException: $message';
}

class NetworkException implements Exception {
  const NetworkException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => 'NetworkException($statusCode): $message';
}

class CacheException implements Exception {
  const CacheException(this.message);

  final String message;

  @override
  String toString() => 'CacheException: $message';
}
