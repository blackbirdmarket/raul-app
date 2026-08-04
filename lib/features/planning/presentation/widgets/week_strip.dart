import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../utils/calendar.dart';
import '../../../../utils/date_format.dart';
import '../../../../utils/extensions.dart';
import '../providers/agenda_providers.dart';

/// Tira horizontal con los siete dias de la semana.
///
/// Es el mando de navegacion principal: siempre visible, siempre en el mismo
/// lugar. Cada dia muestra cuanta carga tiene, para que se note de un vistazo
/// donde esta el dia apretado antes siquiera de abrirlo.
class WeekStrip extends ConsumerWidget {
  const WeekStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDayProvider);
    final monday = Calendar.startOfWeek(selected);
    final today = Calendar.today();

    // Los siete dias se calculan una vez y se reutilizan: antes se construia
    // la misma fecha tres veces por celda, con aritmetica de duracion que ya
    // sabemos que se tuerce en los cambios de horario.
    final days = <DateTime>[
      for (var i = 0; i < 7; i++) Calendar.addDays(monday, i),
    ];

    return SizedBox(
      height: 80,
      child: Row(
        children: <Widget>[
          for (final date in days)
            Expanded(
              child: _DayCell(
                date: date,
                isSelected: date == selected,
                isToday: date == today,
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends ConsumerWidget {
  const _DayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final load = ref.watch(dayLoadProvider(date));
    final scheme = context.colors;

    // El dia elegido se tine, no se rellena: sobre el fondo con luz un bloque
    // ambar macizo apagaria todo lo que tiene alrededor.
    final Color background = isSelected
        ? scheme.primary.withValues(alpha: 0.18)
        : context.isDarkMode
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.white.withValues(alpha: 0.5);

    final Color foreground = isSelected
        ? scheme.primary
        : isToday
            ? scheme.primary
            : scheme.onSurface;

    // La celda entera es la pastilla, no solo el numero: da un area de toque
    // mas generosa y deja que el dia elegido se lea como una pieza y no como
    // un circulito suelto.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref.read(selectedDayProvider.notifier).select(date),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        child: AnimatedContainer(
          duration: AppConstants.durationFast,
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
            border: Border.all(
              color: isSelected
                  ? scheme.primary
                  : isToday
                      ? scheme.primary.withValues(alpha: 0.4)
                      : scheme.outlineVariant,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                DateNames.weekdayShort(date),
                style: context.texts.labelSmall?.copyWith(
                  color: isSelected
                      ? foreground.withValues(alpha: 0.75)
                      : scheme.onSurfaceVariant,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${date.day}',
                style: context.texts.titleMedium?.copyWith(
                  color: foreground,
                  height: 1.1,
                  fontWeight: isSelected || isToday
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              _LoadDot(load: load, isSelected: isSelected),
            ],
          ),
        ),
      ),
    );
  }
}

/// Punto bajo cada dia: vacio si no hay nada, relleno segun lo completado.
class _LoadDot extends StatelessWidget {
  const _LoadDot({required this.load, required this.isSelected});

  final DayLoad load;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    if (load.isEmpty) {
      return const SizedBox(height: 5);
    }

    final scheme = context.colors;
    final color = load.isComplete ? scheme.onSurfaceVariant : scheme.primary;

    return Container(
      width: load.isComplete ? 5 : 5 + (load.total.clamp(1, 4) * 3).toDouble(),
      height: 5,
      decoration: BoxDecoration(
        color: isSelected ? scheme.primary : color,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
    );
  }
}
