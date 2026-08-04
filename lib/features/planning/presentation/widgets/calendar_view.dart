import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/agenda_entry.dart';
import '../../../../utils/calendar.dart';
import '../../../../utils/date_format.dart';
import '../../../../utils/extensions.dart';
import '../../../../widgets/add_button.dart';
import '../../../../widgets/fade_in.dart';
import '../providers/agenda_providers.dart';
import '../providers/calendar_providers.dart';
import 'day_entry_row.dart';
import 'entry_editor_sheet.dart';
import 'month_grid.dart';

/// El mes completo, con puntos de color por dia y el detalle del que se
/// toque debajo.
///
/// Vive junto al dia y la agenda dentro de planning: las tres son la misma
/// informacion con distinta escala de tiempo, no areas separadas.
class CalendarView extends ConsumerWidget {
  const CalendarView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(calendarMonthProvider);
    final selected = ref.watch(calendarDayProvider);
    final entries = ref.watch(agendaProvider);

    final byDay = _groupByDay(entries);
    final selectedEntries = byDay[selected] ?? const <AgendaEntry>[];

    final today = Calendar.today();
    final isCurrentMonth =
        month.year == today.year && month.month == today.month;

    return Column(
      children: <Widget>[
        _MonthBar(
          month: month,
          isCurrent: isCurrentMonth,
          onShift: ref.read(calendarMonthProvider.notifier).shift,
          onToday: ref.read(calendarDayProvider.notifier).goToToday,
          onCreate: () => showEntryEditor(context, day: selected),
        ),
        MonthGrid(
          month: month,
          selected: selected,
          entriesByDay: byDay,
          onSelect: (day) {
            HapticFeedback.selectionClick();
            ref.read(calendarDayProvider.notifier).select(day);
          },
        ),
        const SizedBox(height: AppConstants.spaceSm),
        Expanded(
          child: _DayList(day: selected, entries: selectedEntries),
        ),
      ],
    );
  }

  /// Agrupa toda la agenda por dia, una sola vez por reconstruccion.
  Map<DateTime, List<AgendaEntry>> _groupByDay(List<AgendaEntry> entries) {
    final map = <DateTime, List<AgendaEntry>>{};
    for (final entry in entries) {
      map.putIfAbsent(entry.day, () => <AgendaEntry>[]).add(entry);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.start.compareTo(b.start));
    }
    return map;
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.month,
    required this.isCurrent,
    required this.onShift,
    required this.onToday,
    required this.onCreate,
  });

  final DateTime month;
  final bool isCurrent;
  final ValueChanged<int> onShift;
  final VoidCallback onToday;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceMd,
        0,
        AppConstants.spaceSm,
        AppConstants.spaceXs,
      ),
      child: Row(
        children: <Widget>[
          Text(
            '${DateNames.month(month)} de ${month.year}'.capitalized,
            style: context.texts.titleMedium,
          ),
          const Spacer(),
          _Round(icon: Icons.chevron_left_rounded, onTap: () => onShift(-1)),
          if (!isCurrent)
            _Round(icon: Icons.today_rounded, onTap: onToday, accent: true),
          _Round(icon: Icons.chevron_right_rounded, onTap: () => onShift(1)),
          const SizedBox(width: AppConstants.spaceXs),
          AddButton(onPressed: onCreate, tooltip: 'Agregar en este dia'),
        ],
      ),
    );
  }
}

class _Round extends StatelessWidget {
  const _Round({
    required this.icon,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: accent ? 20 : 26),
      color: accent ? scheme.primary : scheme.onSurfaceVariant,
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Lo que hay en el dia elegido, en orden de hora.
class _DayList extends StatelessWidget {
  const _DayList({required this.day, required this.entries});

  final DateTime day;
  final List<AgendaEntry> entries;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    var planned = Duration.zero;
    for (final entry in entries) {
      if (entry is TimeBlock) planned += entry.duration;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.spaceMd + 2,
            AppConstants.spaceXs,
            AppConstants.spaceMd + 2,
            AppConstants.spaceSm,
          ),
          child: Row(
            children: <Widget>[
              Text(
                DateNames.relativeDay(day).capitalized,
                style: context.texts.titleSmall,
              ),
              const Spacer(),
              Text(
                entries.isEmpty
                    ? 'Sin nada'
                    : planned == Duration.zero
                        ? '${entries.length} ${entries.length == 1 ? "cosa" : "cosas"}'
                        : '${entries.length} · ${DateNames.duration(planned)}',
                style: context.texts.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? _EmptyDay(day: day)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.spaceMd,
                    0,
                    AppConstants.spaceMd,
                    AppConstants.spaceXxl * 2,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, index) => FadeIn(
                    delay: Duration(milliseconds: 35 * index.clamp(0, 8)),
                    child: Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppConstants.spaceSm),
                      child: DayEntryRow(entry: entries[index], day: day),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.spaceXl,
          0,
          AppConstants.spaceXl,
          AppConstants.spaceXxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.event_available_rounded,
              size: 34,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppConstants.spaceSm),
            Text(
              'Dia libre',
              style: context.texts.titleMedium,
            ),
            const SizedBox(height: AppConstants.spaceXs),
            Text(
              'Toca el mas para poner algo aqui.',
              textAlign: TextAlign.center,
              style: context.texts.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
