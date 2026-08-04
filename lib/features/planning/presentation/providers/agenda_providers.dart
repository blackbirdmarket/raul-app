import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/agenda_entry.dart';
import '../../../../models/sub_task.dart';
import '../../../../services/notification_service.dart';
import '../../../../utils/calendar.dart';
import '../../data/agenda_repository.dart';

/// Las dos maneras de mirar lo planificado.
///
/// El dia sirve para ejecutar, la agenda para planificar. Son la misma
/// informacion con dos lecturas, por eso viven en la misma area y no en
/// pestanas separadas: la barra de abajo queda libre para las otras areas
/// que vengan despues.
enum PlanningView {
  day('Dia', Icons.view_day_rounded),
  agenda('Agenda', Icons.view_agenda_rounded);

  const PlanningView(this.label, this.icon);

  final String label;
  final IconData icon;
}

final planningViewProvider =
    NotifierProvider<PlanningViewController, PlanningView>(
  PlanningViewController.new,
);

class PlanningViewController extends Notifier<PlanningView> {
  @override
  PlanningView build() => PlanningView.day;

  void select(PlanningView view) => state = view;
}

/// Dia que se esta mirando. Siempre normalizado a medianoche.
final selectedDayProvider =
    NotifierProvider<SelectedDayController, DateTime>(SelectedDayController.new);

class SelectedDayController extends Notifier<DateTime> {
  @override
  DateTime build() => today();

  static DateTime today() => Calendar.today();

  void select(DateTime day) => state = Calendar.dayOf(day);

  void goToToday() => state = today();

  void shiftDays(int days) => state = Calendar.addDays(state, days);
}

/// Dias plegados en la vista de agenda.
///
/// Vive en un provider y no dentro del widget para que se conserve al ir a
/// otra pestana y volver.
final collapsedDaysProvider =
    NotifierProvider<CollapsedDaysController, Set<DateTime>>(
  CollapsedDaysController.new,
);

class CollapsedDaysController extends Notifier<Set<DateTime>> {
  @override
  Set<DateTime> build() => <DateTime>{};

  void toggle(DateTime day) {
    final next = <DateTime>{...state};
    if (!next.remove(day)) next.add(day);
    state = next;
  }

  bool isCollapsed(DateTime day) => state.contains(day);
}

/// Hasta cuando se generan las repeticiones por adelantado.
const int _horizonDays = 90;

/// Toda la agenda en memoria, ordenada por hora.
final agendaProvider =
    NotifierProvider<AgendaController, List<AgendaEntry>>(AgendaController.new);

class AgendaController extends Notifier<List<AgendaEntry>> {
  @override
  List<AgendaEntry> build() {
    final stored = ref.watch(agendaRepositoryProvider).loadAll();
    final pending = _missingOccurrences(stored);

    if (pending.isNotEmpty) {
      Future<void>.microtask(() async {
        for (final entry in pending) {
          await _repository.save(entry);
        }
      });
    }

    final all = <AgendaEntry>[...stored, ...pending]
      ..sort((a, b) => a.start.compareTo(b.start));

    _scheduleAlerts(all);
    return all;
  }

  AgendaRepository get _repository => ref.read(agendaRepositoryProvider);

  void _scheduleAlerts(List<AgendaEntry> entries) {
    Future<void>.microtask(
      () => NotificationService.instance.syncAll(entries),
    );
  }

  List<AgendaEntry> _missingOccurrences(List<AgendaEntry> stored) {
    final bySeries = <String, List<AgendaEntry>>{};
    for (final entry in stored) {
      final series = entry.seriesId;
      if (series == null || !entry.recurrence.isActive) continue;
      bySeries.putIfAbsent(series, () => <AgendaEntry>[]).add(entry);
    }

    final horizon = Calendar.addDays(DateTime.now(), _horizonDays);
    final generated = <AgendaEntry>[];

    for (final occurrences in bySeries.values) {
      final last = occurrences.reduce(
        (a, b) => a.start.isAfter(b.start) ? a : b,
      );

      var cursor = last.recurrence.nextAfter(last.start);
      var guard = 0;

      while (cursor != null && !cursor.isAfter(horizon) && guard < 400) {
        generated.add(
          last.occurrenceAt(
            cursor,
            newId: newEntryId(),
            series: last.seriesId!,
          ),
        );
        cursor = last.recurrence.nextAfter(cursor);
        guard++;
      }
    }

    return generated;
  }

  Future<void> upsert(AgendaEntry entry) async {
    final next = <AgendaEntry>[
      ...state.where((e) => e.id != entry.id),
      entry,
    ]..sort((a, b) => a.start.compareTo(b.start));

    state = next;
    await _repository.save(entry);
    _scheduleAlerts(state);
  }

  Future<void> createSeries(AgendaEntry first) async {
    if (!first.recurrence.isActive) {
      await upsert(first);
      return;
    }

    final series = first.seriesId ?? newEntryId();
    final occurrences = <AgendaEntry>[
      first.occurrenceAt(first.start, newId: first.id, series: series),
    ];

    final horizon = Calendar.addDays(DateTime.now(), _horizonDays);
    var cursor = first.recurrence.nextAfter(first.start);
    var guard = 0;

    while (cursor != null && !cursor.isAfter(horizon) && guard < 400) {
      occurrences.add(
        first.occurrenceAt(cursor, newId: newEntryId(), series: series),
      );
      cursor = first.recurrence.nextAfter(cursor);
      guard++;
    }

    state = <AgendaEntry>[...state, ...occurrences]
      ..sort((a, b) => a.start.compareTo(b.start));

    for (final entry in occurrences) {
      await _repository.save(entry);
    }
    _scheduleAlerts(state);
  }

  Future<void> remove(String id) async {
    state = state.where((e) => e.id != id).toList();
    await _repository.remove(id);
    _scheduleAlerts(state);
  }

  Future<void> removeSeries(String seriesId) async {
    final doomed = state.where((e) => e.seriesId == seriesId).toList();
    state = state.where((e) => e.seriesId != seriesId).toList();

    for (final entry in doomed) {
      await _repository.remove(entry.id);
    }
    _scheduleAlerts(state);
  }

  AgendaEntry? _find(String id) {
    for (final entry in state) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  Future<void> toggleTask(String id) async {
    final task = _find(id);
    if (task is! QuickTask) return;
    await upsert(task.copyWith(done: !task.done));
  }

  Future<void> toggleSubTask(String blockId, String subTaskId) async {
    final block = _find(blockId);
    if (block is! TimeBlock) return;

    final updated = block.subtasks
        .map((s) => s.id == subTaskId ? s.copyWith(done: !s.done) : s)
        .toList();

    await upsert(block.copyWith(subtasks: updated));
  }

  Future<void> addSubTask(String blockId, String title) async {
    final block = _find(blockId);
    if (block is! TimeBlock) return;

    final subtask = SubTask(id: newEntryId(), title: title.trim());
    await upsert(
      block.copyWith(subtasks: <SubTask>[...block.subtasks, subtask]),
    );
  }

  Future<void> moveToToday(String id) async {
    final entry = _find(id);
    if (entry == null) return;

    final today = SelectedDayController.today();
    final newStart = DateTime(
      today.year,
      today.month,
      today.day,
      entry.start.hour,
      entry.start.minute,
    );

    switch (entry) {
      case QuickTask():
        await upsert(entry.copyWith(start: newStart));
      case TimeBlock():
        await upsert(
          entry.copyWith(start: newStart, end: newStart.add(entry.duration)),
        );
    }
  }
}

/// Elementos de un dia concreto, ya ordenados.
final entriesForDayProvider =
    Provider.family<List<AgendaEntry>, DateTime>((ref, day) {
  final target = Calendar.dayOf(day);
  return ref.watch(agendaProvider).where((e) => e.day == target).toList();
});

/// Lo que quedo pendiente en dias que ya pasaron.
final overdueProvider = Provider<List<AgendaEntry>>((ref) {
  final today = SelectedDayController.today();
  return ref
      .watch(agendaProvider)
      .where((e) => e.day.isBefore(today) && !e.isComplete)
      .toList()
      .reversed
      .toList();
});
