import '../errors/failure.dart';

/// Resultado de una operacion que puede fallar.
///
/// Se usa en vez de lanzar excepciones hacia arriba porque obliga a quien
/// llama a considerar el caso de error: el compilador no deja acceder al
/// valor sin antes distinguir entre exito y fallo.
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Failure failure) = FailureResult<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is FailureResult<T>;

  /// Valor si hubo exito, `null` si no. Util cuando el fallo ya se manejo.
  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        FailureResult<T>() => null,
      };

  /// Fallo si lo hubo, `null` si la operacion salio bien.
  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        FailureResult<T>(:final failure) => failure,
      };

  /// Resuelve ambos casos en un solo valor. Es la forma preferida de
  /// consumir un `Result` desde la interfaz.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) =>
      switch (this) {
        Success<T>(:final value) => onSuccess(value),
        FailureResult<T>(:final failure) => onFailure(failure),
      };

  /// Transforma el valor de exito, dejando el fallo intacto.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success<T>(:final value) => Result<R>.success(transform(value)),
        FailureResult<T>(:final failure) => Result<R>.failure(failure),
      };
}

final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);

  final Failure failure;
}
