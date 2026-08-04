import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../../../database/hive_setup.dart';
import '../../../models/journal_entry.dart';
import '../../../models/mood_entry.dart';
import '../../../services/logger_service.dart';
import '../../../services/storage_service.dart';

final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository(ref.watch(storageServiceProvider));
});

/// Acceso al cuaderno y a los registros de animo.
///
/// Sigue el mismo patron que las otras areas: mapas planos, una clave por
/// elemento, y lo que no se pueda leer se descarta con un aviso en vez de
/// tumbar la carga completa. En un cuaderno eso importa mas que en ningun otro
/// sitio: perder un escrito por un dato raro seria imperdonable, pero no abrir
/// la aplicacion y perderlos todos lo seria mas.
class JournalRepository {
  const JournalRepository(this._storage);

  final StorageService _storage;

  // --- Escritos ---

  List<JournalEntry> loadEntries() {
    final entries = <JournalEntry>[];

    for (final raw in _storage.values(box: HiveBoxes.journal)) {
      if (raw is! Map) continue;
      try {
        entries.add(JournalEntry.fromMap(raw));
      } catch (error) {
        LoggerService.warning(
          'Se descarto un escrito ilegible: $error',
          tag: 'DIARIO',
        );
      }
    }

    return entries;
  }

  Future<Result<void>> saveEntry(JournalEntry entry) =>
      _storage.write(entry.id, entry.toMap(), box: HiveBoxes.journal);

  Future<void> removeEntry(String id) =>
      _storage.delete(id, box: HiveBoxes.journal);

  // --- Animo ---

  List<MoodEntry> loadMoods() {
    final moods = <MoodEntry>[];

    for (final raw in _storage.values(box: HiveBoxes.moods)) {
      if (raw is! Map) continue;
      try {
        moods.add(MoodEntry.fromMap(raw));
      } catch (error) {
        LoggerService.warning(
          'Se descarto un registro de animo ilegible: $error',
          tag: 'DIARIO',
        );
      }
    }

    moods.sort((a, b) => b.day.compareTo(a.day));
    return moods;
  }

  Future<Result<void>> saveMood(MoodEntry mood) =>
      _storage.write(mood.key, mood.toMap(), box: HiveBoxes.moods);

  Future<void> removeMood(String key) =>
      _storage.delete(key, box: HiveBoxes.moods);

  Future<void> clearAll() async {
    await _storage.clear(box: HiveBoxes.journal);
    await _storage.clear(box: HiveBoxes.moods);
  }
}
