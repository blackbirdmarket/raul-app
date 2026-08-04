import 'dart:developer' as developer;

import '../core/config/app_config.dart';

/// Niveles de severidad de un registro.
enum LogLevel { debug, info, warning, error }

/// Registro centralizado de eventos.
///
/// Todo el logging pasa por aqui en vez de usar `print`, por dos razones: se
/// silencia automaticamente en produccion, y el dia que haga falta enviar los
/// errores a un servicio externo se cambia un solo archivo.
class LoggerService {
  const LoggerService._();

  static void debug(String message, {String? tag}) =>
      _log(LogLevel.debug, message, tag: tag);

  static void info(String message, {String? tag}) =>
      _log(LogLevel.info, message, tag: tag);

  static void warning(String message, {String? tag}) =>
      _log(LogLevel.warning, message, tag: tag);

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      _log(
        LogLevel.error,
        message,
        tag: tag,
        error: error,
        stackTrace: stackTrace,
      );

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!AppConfig.instance.enableLogging) return;

    developer.log(
      message,
      name: tag ?? level.name.toUpperCase(),
      level: switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warning => 900,
        LogLevel.error => 1000,
      },
      error: error,
      stackTrace: stackTrace,
    );
  }
}
