import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/errors/failure.dart';
import '../core/result/result.dart';
import '../database/hive_setup.dart';
import 'logger_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return const StorageService();
});

/// Lectura y escritura en el almacenamiento local.
///
/// Envuelve Hive para que ninguna otra parte de la aplicacion lo importe
/// directamente. Si algun dia se cambia el motor de base de datos, se
/// reescribe este archivo y nada mas.
class StorageService {
  const StorageService();

  Box<dynamic> _box(String name) => Hive.box<dynamic>(name);

  /// Guarda un valor. Devuelve un `Result` en vez de lanzar, porque un fallo
  /// de escritura casi siempre se quiere mostrar al usuario, no propagar.
  Future<Result<void>> write(
    String key,
    Object? value, {
    String box = HiveBoxes.app,
  }) async {
    try {
      await _box(box).put(key, value);
      return const Result<void>.success(null);
    } catch (error, stackTrace) {
      LoggerService.error(
        'No se pudo escribir "$key".',
        tag: 'STORAGE',
        error: error,
        stackTrace: stackTrace,
      );
      return const Result<void>.failure(
        StorageFailure('No se pudieron guardar los datos.'),
      );
    }
  }

  /// Lee un valor tipado. Devuelve `null` si no existe o si el tipo guardado
  /// no coincide, en vez de reventar en tiempo de ejecucion.
  T? read<T>(String key, {String box = HiveBoxes.app}) {
    final value = _box(box).get(key);
    if (value is T) return value;
    if (value != null) {
      LoggerService.warning(
        'La clave "$key" contiene ${value.runtimeType}, se esperaba $T.',
        tag: 'STORAGE',
      );
    }
    return null;
  }

  /// Todos los valores de una caja, para reconstruir colecciones completas.
  Iterable<dynamic> values({String box = HiveBoxes.app}) =>
      _box(box).values;

  bool contains(String key, {String box = HiveBoxes.app}) =>
      _box(box).containsKey(key);

  Future<void> delete(String key, {String box = HiveBoxes.app}) =>
      _box(box).delete(key);

  Future<void> clear({String box = HiveBoxes.app}) => _box(box).clear();
}
