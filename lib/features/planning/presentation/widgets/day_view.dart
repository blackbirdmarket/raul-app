import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../utils/date_format.dart';
import '../../../../utils/extensions.dart';
import '../providers/agenda_providers.dart';
import 'entry_detail_sheet.dart';
import 'entry_editor_sheet.dart';
import 'timeline_rail.dart';
import 'week_strip.dart';

/// El dia en su riel de horas. La vista para ejecutar.
class DayView extends ConsumerWidget {
  const DayView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDayProvider);
    final entries = ref.watch(entriesForDayProvider(day));
    final load = ref.watch(dayLoadProvider(day));

    final now = DateTime.now();
    final isToday = DateTime(now.year, now.month, now.day) == day;

    return Column(
      children: <Widget>[
        _DayHeader(day: day, isToday: isToday, load: load),
        const WeekStrip(),
        const SizedBox(height: AppConstants.spaceXs),
        Expanded(
          child: entries.isEmpty
              ? _EmptyDay(onCreate: () => showEntryEditor(context, day: day))
              : Padding(
                  padding: const EdgeInsets.only(
                    top: AppConstants.spaceMd,
                    right: AppConstants.spaceMd,
                  ),
                  child: TimelineRail(
                    // La clave fuerza reconstruir el riel al cambiar de dia,
                    // para que vuelva a posicionar el scroll.
                    key: ValueKey<DateTime>(day),
                    day: day,
                    entries: entries,
                    // Tocar algo abre su ficha, no el editor: mirar es lo
                    // que uno hace mil veces, editar es la excepcion.
                    onEntryTap: (entry) => showEntryDetail(
                      context,
                      day: day,
                      entryId: entry.id,
                    ),
                    onEmptyTap: (at) => showEntryEditor(
                      context,
                      day: day,
                      initialAt: at,
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _DayHeader extends ConsumerWidget {
  const _DayHeader({
    required this.day,
    required this.isToday,
    required this.load,
  });

  final DateTime day;
  final bool isToday;
  final DayLoad load;

  String get _summary {
    if (load.isEmpty) return 'Sin nada planificado';
    if (load.isComplete) return 'Todo listo';
    final pending = load.total - load.done;
    return pending == 1 ? '1 pendiente' : '$pending pendientes';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceMd,
        AppConstants.spaceXs,
        AppConstants.spaceMd,
        AppConstants.spaceMd,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  DateNames.dayTitle(day).capitalized,
                  style: context.texts.headlineMedium,
                ),
                const SizedBox(height: 2),
                Row(
                  children: <Widget>[
                    Flexible(
                      child: Text(
                        DateNames.mediumDate(day),
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      '  ·  ',
                      style: context.texts.bodyMedium?.copyWith(
                        color: scheme.outline,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        _summary,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodyMedium?.copyWith(
                          color: load.isComplete
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                          fontWeight: load.isComplete ? FontWeight.w600 : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isToday)
            TextButton(
              onPressed: () =>
                  ref.read(selectedDayProvider.notifier).goToToday(),
              child: const Text('Hoy'),
            ),
        ],
      ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  const _EmptyDay({required this.onCreate});

  final VoidCallback onCreate;

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
                Icons.wb_twilight_rounded,
                size: 34,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppConstants.spaceLg),
            Text('Dia libre', style: context.texts.titleLarge),
            const SizedBox(height: AppConstants.spaceXs),
            Text(
              'Nada planificado todavia.',
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppConstants.spaceLg),
            SizedBox(
              width: 220,
              child: OutlinedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Planificar algo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
