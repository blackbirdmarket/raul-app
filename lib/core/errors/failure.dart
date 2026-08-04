/// Representa un error ya manejado, listo para mostrarse al usuario.
///
/// La diferencia con una excepcion es intencional: las excepciones se lanzan
/// en las capas bajas (red, base de datos) y se traducen a `Failure` antes de
/// llegar a la interfaz. Asi la UI nunca tiene que saber de que capa vino el
/// problema ni interpretar mensajes tecnicos.
sealed class Failure {
  const Failure(this.message, {this.cause});

  /// Mensaje en lenguaje humano, apto para mostrar en pantalla.
  final String message;

  /// Error original, util para logging. Nunca se muestra al usuario.
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Fallo al leer o escribir en el almacenamiento local.
class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.cause});
}

/// Fallo de red o de un servicio remoto.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause});
}

/// Los datos recibidos no tienen la forma esperada.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.cause});
}

/// Cualquier fallo no previsto. Si aparece seguido en los logs, merece su
/// propio tipo.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([
    super.message = 'Ocurrio un error inesperado.',
    Object? cause,
  ]) : super(cause: cause);
}
