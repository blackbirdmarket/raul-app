import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/agenda_entry.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/calendar.dart';
import '../../../../utils/date_format.dart';
import '../../../../utils/extensions.dart';

/// La rejilla del mes.
///
/// Cada dia con algo lleva hasta tres puntos del color de sus bloques. Es la
/// unica forma de que el mes informe sin abrir nada: de un vistazo se ve que
/// semanas estan cargadas y donde quedan huecos, que es justo para lo que uno
/// mira un mes completo.
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    required this.month,
    required this.selected,
    required this.entriesByDay,
    required this.onSelect,
    super.key,
  });

  final DateTime month;
  final DateTime selected;
  final Map<DateTime, List<AgendaEntry>> entriesByDay;
  final ValueChanged<DateTime> onSelect;

  /// Todos los dias que se dibujan, incluidos los del mes vecino que rellenan
  /// la primera y la ultima semana.
  ///
  /// Se calcula con `Calendar.addDays` y no sumando duraciones: en los cambios
  /// de horario de Chile un dia no dura veinticuatro horas y la rejilla se
  /// desalinearia justo esa semana.
  List<DateTime> _days() {
    final first = DateTime(month.year, month.month);
    final start = Calendar.startOfWeek(first);
    return <DateTime>[
      for (var i = 0; i < 42; i++) Calendar.addDays(start, i),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final days = _days();
    final today = Calendar.today();

    // Seis semanas solo cuando hacen falta: con cinco basta en la mayoria de
    // los meses y la lista de abajo gana una fila entera de alto.
    final rows = days[35].month == month.month ? 6 : 5;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spaceMd),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              for (final label in DateNames.weekdaysShort)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      label.substring(0, 1),
                      textAlign: TextAlign.center,
                      style: context.texts.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 9,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (var week = 0; week < rows; week++)
            Row(
              children: <Widget>[
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: _Cell(
                      day: days[week * 7 + i],
                      inMonth: days[week * 7 + i].month == month.month,
                      isToday: days[week * 7 + i] == today,
                      isSelected: days[week * 7 + i] == selected,
                      entries: entriesByDay[days[week * 7 + i]] ??
                          const <AgendaEntry>[],
                      onTap: () => onSelect(days[week * 7 + i]),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.entries,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final List<AgendaEntry> entries;
  final VoidCallback onTap;

  /// Colores de los puntos, sin repetir y como maximo tres.
  ///
  /// Tres es el limite en que los puntos siguen distinguiendose dentro de una
  /// celda de este tamano; mas alla se vuelven una linea sucia.
  List<Color> _dots() {
    final seen = <int>{};
    final colors = <Color>[];

    for (final entry in entries) {
      final index = entry is TimeBlock ? entry.colorIndex : -1;
      if (!seen.add(index)) continue;
      colors.add(
        index < 0 ? AppColors.accent : AppColors.blockAccent(index),
      );
      if (colors.length == 3) break;
    }
    return colors;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final dots = _dots();

    final Color text;
    if (isSelected) {
      text = scheme.primary;
    } else if (!inMonth) {
      text = scheme.onSurfaceVariant.withValues(alpha: 0.45);
    } else {
      text = scheme.onSurface;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: AnimatedContainer(
          duration: AppConstants.durationFast,
          curve: Curves.easeOut,
          height: 42,
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primary.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: isSelected
                  ? scheme.primary
                  : isToday
                      ? scheme.primary.withValues(alpha: 0.45)
                      : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '${day.day}',
                style: context.texts.bodyMedium?.copyWith(
                  color: text,
                  fontSize: 12.5,
                  fontWeight:
                      isSelected || isToday ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 4,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (final color in dots)
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1.2),
                        decoration: BoxDecoration(
                          color: inMonth
                              ? color
                              : color.withValues(alpha: 0.35),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
