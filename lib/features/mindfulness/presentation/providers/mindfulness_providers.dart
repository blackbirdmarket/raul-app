import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/agenda_entry.dart' show newEntryId;
import '../../../../models/journal_entry.dart';
import '../../../../models/mood_entry.dart';
import '../../../../utils/calendar.dart';
import '../../data/mindfulness_repository.dart';

// --- El cuaderno ---

/// Todos los escritos: primero los fijados, despues los mas recientes.
///
/// Los fijados arriba porque son los que se releen a diario; el resto por
/// fecha porque lo ultimo escrito es lo que uno busca al volver.
final journalProvider =
    NotifierProvider<JournalController, List<JournalEntry>>(
  JournalController.new,
);

class JournalController extends Notifier<List<JournalEntry>> {
  @override
  List<JournalEntry> build() =>
      _sorted(ref.watch(journalRepositoryProvider).loadEntries());

  JournalRepository get _repository => ref.read(journalRepositoryProvider);

  static List<JournalEntry> _sorted(List<JournalEntry> entries) {
    return entries
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  /// Guarda un escrito nuevo o reemplaza el que ya existia.
  ///
  /// Un escrito vacio se borra en vez de guardarse: si alguien abre la hoja,
  /// se arrepiente y sale, lo que espera es que no quede nada, no una entrada
  /// en blanco ensuciando la lista.
  Future<void> save(JournalEntry entry) async {
    if (entry.text.trim().isEmpty) {
      await remove(entry.id);
      return;
    }

    state = _sorted(<JournalEntry>[
      ...state.where((e) => e.id != entry.id),
      entry,
    ]);

    await _repository.saveEntry(entry);
  }

  Future<void> remove(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _repository.removeEntry(id);
  }

  Future<void> togglePinned(String id) async {
    final entry = byId(id);
    if (entry == null) return;
    await save(entry.copyWith(pinned: !entry.pinned));
  }

  JournalEntry? byId(String id) {
    for (final entry in state) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  String newId() => newEntryId();
}

/// Texto que se esta buscando en el cuaderno.
final journalQueryProvider =
    NotifierProvider<JournalQueryController, String>(
  JournalQueryController.new,
);

class JournalQueryController extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
  void clear() => state = '';
}

/// Los escritos que coinciden con la busqueda.
///
/// Busca en el titulo y en el cuerpo, sin distinguir mayusculas: un cuaderno
/// que solo encuentra por titulo es inutil cuando lo que uno recuerda es una
/// frase suelta de hace tres meses.
final visibleJournalProvider = Provider<List<JournalEntry>>((ref) {
  final entries = ref.watch(journalProvider);
  final query = ref.watch(journalQueryProvider).trim().toLowerCase();

  if (query.isEmpty) return entries;

  return entries.where((entry) {
    final title = entry.title?.toLowerCase() ?? '';
    return title.contains(query) || entry.text.toLowerCase().contains(query);
  }).toList();
});

/// Cuantos escritos hay y cuantas palabras suman.
class JournalSummary {
  const JournalSummary({
    required this.entries,
    required this.words,
    required this.thisMonth,
  });

  final int entries;
  final int words;
  final int thisMonth;
}

final journalSummaryProvider = Provider<JournalSummary>((ref) {
  final entries = ref.watch(journalProvider);
  final now = DateTime.now();

  var words = 0;
  var thisMonth = 0;

  for (final entry in entries) {
    words += entry.wordCount;
    if (entry.createdAt.year == now.year &&
        entry.createdAt.month == now.month) {
      thisMonth++;
    }
  }

  return JournalSummary(
    entries: entries.length,
    words: words,
    thisMonth: thisMonth,
  );
});

// --- Animo ---

final moodsProvider =
    NotifierProvider<MoodsController, List<MoodEntry>>(MoodsController.new);

class MoodsController extends Notifier<List<MoodEntry>> {
  @override
  List<MoodEntry> build() => ref.watch(journalRepositoryProvider).loadMoods();

  JournalRepository get _repository => ref.read(journalRepositoryProvider);

  /// Guarda el animo de un dia, reemplazando el que hubiera.
  Future<void> record(MoodEntry mood) async {
    state = <MoodEntry>[
      ...state.where((m) => m.key != mood.key),
      mood,
    ]..sort((a, b) => b.day.compareTo(a.day));

    await _repository.saveMood(mood);
  }

  MoodEntry? forDay(DateTime day) {
    final target = Calendar.dayOf(day);
    for (final mood in state) {
      if (mood.day == target) return mood;
    }
    return null;
  }
}

/// El animo de hoy, o nada si todavia no se registro.
final todayMoodProvider = Provider<MoodEntry?>((ref) {
  final today = Calendar.today();
  for (final mood in ref.watch(moodsProvider)) {
    if (mood.day == today) return mood;
  }
  return null;
});
