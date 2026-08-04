import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../utils/calendar.dart';
import '../../../../utils/date_format.dart';
import '../../../../utils/extensions.dart';
import '../providers/agenda_providers.dart';
import '../providers/day_load_provider.dart';

/// Tira horizontal con los siete dias de la semana.
class WeekStrip extends ConsumerWidget {
  const WeekStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDayProvider);
    final monday = Calendar.startOfWeek(selected);
    final today = Calendar.today();

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
      width: load.isComplete
          ? 5.0
          : 5.0 + (load.total.clamp(1, 4) * 3).toDouble(),
      height: 5,
      decoration: BoxDecoration(
        color: isSelected ? scheme.primary : color,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
    );
  }
}
