import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failure.dart';
import '../../../core/result/result.dart';
import '../../../database/hive_setup.dart';
import '../../../models/agenda_entry.dart';
import '../../../services/logger_service.dart';
import '../../../services/storage_service.dart';

final agendaRepositoryProvider = Provider<AgendaRepository>((ref) {
  return AgendaRepository(ref.watch(storageServiceProvider));
});

/// Acceso a las tareas y bloques guardados.
///
/// Cada elemento se guarda bajo su propio id en vez de como una lista unica.
/// Asi editar una tarea reescribe solo esa clave, y un dato corrupto no se
/// lleva por delante toda la agenda.
class AgendaRepository {
  const AgendaRepository(this._storage);

  final StorageService _storage;

  /// Carga todo, ordenado por hora de inicio.
  ///
  /// Un elemento que no se pueda leer se descarta con un aviso en el log en
  /// vez de romper la carga completa: es preferible perder una tarea a que la
  /// aplicacion no abra.
  List<AgendaEntry> loadAll() {
    final entries = <AgendaEntry>[];

    for (final raw in _storage.values(box: HiveBoxes.agenda)) {
      if (raw is! Map) continue;
      try {
        entries.add(AgendaEntry.fromMap(raw));
      } catch (error) {
        LoggerService.warning(
          'Elemento ilegible descartado: $error',
          tag: 'AGENDA',
        );
      }
    }

    entries.sort((a, b) => a.start.compareTo(b.start));
    return entries;
  }

  Future<Result<void>> save(AgendaEntry entry) {
    return _storage.write(entry.id, entry.toMap(), box: HiveBoxes.agenda);
  }

  Future<Result<void>> remove(String id) async {
    try {
      await _storage.delete(id, box: HiveBoxes.agenda);
      return const Result<void>.success(null);
    } catch (error, stackTrace) {
      LoggerService.error(
        'No se pudo borrar "$id".',
        tag: 'AGENDA',
        error: error,
        stackTrace: stackTrace,
      );
      return const Result<void>.failure(
        StorageFailure('No se pudo borrar el elemento.'),
      );
    }
  }

  Future<void> clear() => _storage.clear(box: HiveBoxes.agenda);
}
