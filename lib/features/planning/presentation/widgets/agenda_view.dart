import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/agenda_entry.dart';
import '../../../../utils/date_format.dart';
import '../../../../utils/extensions.dart';
import '../../../../widgets/fade_in.dart';
import '../../../../widgets/progress_bar.dart';
import '../providers/agenda_providers.dart';
import 'entry_detail_sheet.dart';
import 'entry_editor_sheet.dart';
import 'quick_task_tile.dart';
import 'time_block_card.dart';

/// Clave con la que se pliega el bloque de atrasados.
///
/// Es una fecha imposible en vez de un booleano aparte, para que atrasados y
/// dias compartan exactamente el mismo mecanismo de plegado.
final DateTime _overdueKey = DateTime(1970);

/// Todo lo que viene, agrupado por dia, mas lo que quedo atras.
///
/// No dibuja horas a proposito: aqui lo que importa es la secuencia y poder
/// mirar semanas o meses adelante sin perderse.
class AgendaView extends ConsumerWidget {
  const AgendaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(agendaProvider);
    final overdue = ref.watch(overdueProvider);
    final today = SelectedDayController.today();

    final upcoming = all.where((e) => !e.day.isBefore(today)).toList();
    final grouped = _groupByDay(upcoming);

    if (grouped.isEmpty && overdue.isEmpty) return const _EmptyAgenda();

    final pending = upcoming.where((e) => !e.isComplete).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.spaceMd,
            AppConstants.spaceXs,
            AppConstants.spaceMd,
            AppConstants.spaceMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Lo que viene', style: context.texts.headlineMedium),
              const SizedBox(height: 2),
              Text(
                pending == 1
                    ? '1 pendiente en ${grouped.length} dia'
                    : '$pending pendientes en ${grouped.length} dias',
                style: context.texts.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spaceMd,
              0,
              AppConstants.spaceMd,
              AppConstants.spaceXxl * 2,
            ),
            children: <Widget>[
              if (overdue.isNotEmpty)
                FadeIn(child: _OverdueSection(entries: overdue)),
              for (var i = 0; i < grouped.length; i++)
                FadeIn(
                  delay: Duration(milliseconds: 40 * i.clamp(0, 8)),
                  child: _DaySection(
                    day: grouped[i].day,
                    entries: grouped[i].entries,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<_DayGroup> _groupByDay(List<AgendaEntry> entries) {
    final map = <DateTime, List<AgendaEntry>>{};
    for (final entry in entries) {
      map.putIfAbsent(entry.day, () => <AgendaEntry>[]).add(entry);
    }

    final days = map.keys.toList()..sort();
    return days.map((day) => _DayGroup(day: day, entries: map[day]!)).toList();
  }
}

class _DayGroup {
  const _DayGroup({required this.day, required this.entries});

  final DateTime day;
  final List<AgendaEntry> entries;
}

/// Lo que quedo pendiente en dias que ya pasaron.
class _OverdueSection extends ConsumerWidget {
  const _OverdueSection({required this.entries});

  final List<AgendaEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colors;
    final collapsed = ref.watch(collapsedDaysProvider).contains(_overdueKey);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () =>
                ref.read(collapsedDaysProvider.notifier).toggle(_overdueKey),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.spaceSm),
              child: Row(
                children: <Widget>[
                  _Chevron(collapsed: collapsed, color: scheme.error),
                  const SizedBox(width: 4),
                  Text(
                    'Atrasados',
                    style: context.texts.titleMedium?.copyWith(
                      color: scheme.error,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceSm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.error.withValues(alpha: 0.16),
                      borderRadius:
                          BorderRadius.circular(AppConstants.radiusFull),
                    ),
                    child: Text(
                      '${entries.length}',
                      style: context.texts.labelMedium?.copyWith(
                        color: scheme.error,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          if (!collapsed)
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spaceSm),
                child: _OverdueEntry(entry: entry),
              ),
        ],
      ),
    );
  }
}

/// Un atrasado, con su fecha original y un atajo para traerlo a hoy.
class _OverdueEntry extends ConsumerWidget {
  const _OverdueEntry({required this.entry});

  final AgendaEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colors;

    // Copia local: Dart solo afina el tipo dentro del switch sobre variables
    // locales, no sobre campos de un widget. Sin esto, `entry` sigue siendo
    // AgendaEntry en ambas ramas y no compila.
    final item = entry;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        switch (item) {
          TimeBlock() => TimeBlockCard(
              block: item,
              onTap: () => showEntryDetail(
                context,
                day: item.day,
                entryId: item.id,
              ),
            ),
          QuickTask() => QuickTaskTile(
              task: item,
              onTap: () => showEntryDetail(
                context,
                day: item.day,
                entryId: item.id,
              ),
            ),
        },
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 4),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.event_busy_rounded,
                size: 13,
                color: scheme.error,
              ),
              const SizedBox(width: 5),
              Text(
                DateNames.mediumDate(entry.day),
                style: context.texts.bodySmall?.copyWith(color: scheme.error),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    ref.read(agendaProvider.notifier).moveToToday(entry.id),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Text(
                    'Mover a hoy',
                    style: context.texts.labelMedium?.copyWith(
                      color: scheme.primary,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DaySection extends ConsumerWidget {
  const _DaySection({required this.day, required this.entries});

  final DateTime day;
  final List<AgendaEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colors;
    final load = ref.watch(dayLoadProvider(day));
    final collapsed = ref.watch(collapsedDaysProvider).contains(day);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => ref.read(collapsedDaysProvider.notifier).toggle(day),
            child: Row(
              children: <Widget>[
                _Chevron(collapsed: collapsed, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    DateNames.relativeDay(day).capitalized,
                    style: context.texts.titleMedium,
                  ),
                ),
                // Doble toque de informacion: el texto dice cuanto queda, la
                // barra de abajo dice cuanto se avanzo.
                Text(
                  load.isComplete
                      ? 'listo'
                      : '${load.done} de ${load.total}',
                  style: context.texts.labelMedium?.copyWith(
                    color: load.isComplete
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(width: AppConstants.spaceSm),
                // Abrir el dia en el riel: el puente entre planificar y
                // ejecutar.
                GestureDetector(
                  onTap: () {
                    ref.read(selectedDayProvider.notifier).select(day);
                    ref
                        .read(planningViewProvider.notifier)
                        .select(PlanningView.day);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Icon(
                    Icons.north_east_rounded,
                    size: 15,
                    color: scheme.outline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Expanded(
                child: ProgressBar(
                  progress: load.progress,
                  color: load.isComplete ? scheme.primary : scheme.primary,
                ),
              ),
              const SizedBox(width: AppConstants.spaceSm),
              SizedBox(
                width: 34,
                child: Text(
                  '${load.percent}%',
                  textAlign: TextAlign.right,
                  style: context.texts.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 10,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spaceMd),
          if (!collapsed)
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spaceSm),
                child: switch (entry) {
                  TimeBlock() => TimeBlockCard(
                      block: entry,
                      onTap: () => showEntryDetail(
                        context,
                        day: day,
                        entryId: entry.id,
                      ),
                    ),
                  QuickTask() => QuickTaskTile(
                      task: entry,
                      onTap: () => showEntryDetail(
                        context,
                        day: day,
                        entryId: entry.id,
                      ),
                    ),
                },
              ),
        ],
      ),
    );
  }
}

/// Flecha que gira al plegar.
class _Chevron extends StatelessWidget {
  const _Chevron({required this.collapsed, required this.color});

  final bool collapsed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      duration: AppConstants.durationFast,
      curve: Curves.easeOut,
      turns: collapsed ? -0.25 : 0,
      child: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: color),
    );
  }
}

class _EmptyAgenda extends StatelessWidget {
  const _EmptyAgenda();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_note_rounded,
                size: 34,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppConstants.spaceLg),
            Text('Nada por delante', style: context.texts.titleLarge),
            const SizedBox(height: AppConstants.spaceXs),
            Text(
              'Lo que planifiques va a aparecer aqui,\nordenado dia por dia.',
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
