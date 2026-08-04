import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/money.dart';
import '../../../../models/movement.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/category_icons.dart';
import '../../../../utils/date_format.dart';
import '../../../../utils/extensions.dart';
import '../../../../widgets/fade_in.dart';
import '../../../../widgets/month_selector.dart';
import '../providers/finance_providers.dart';
import 'movement_editor_sheet.dart';

/// Movimientos del mes, agrupados por dia.
class MovementsView extends ConsumerWidget {
  const MovementsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final movements = ref.watch(movementsForMonthProvider(month));
    final summary = ref.watch(monthSummaryProvider(month));
    final controller = ref.read(selectedMonthProvider.notifier);

    final grouped = _groupByDay(movements);

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.spaceSm,
            AppConstants.spaceXs,
            AppConstants.spaceSm,
            AppConstants.spaceMd,
          ),
          child: MonthSelector(
            month: month,
            isCurrent: month == SelectedMonthController.currentMonth(),
            onShift: controller.shift,
            onTapLabel: controller.goToCurrent,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceMd,
          ),
          child: _SummaryRow(summary: summary),
        ),
        const SizedBox(height: AppConstants.spaceMd),
        Expanded(
          child: grouped.isEmpty
              ? const _EmptyMonth()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.spaceMd,
                    0,
                    AppConstants.spaceMd,
                    AppConstants.spaceXxl * 2,
                  ),
                  itemCount: grouped.length,
                  itemBuilder: (context, index) {
                    final group = grouped[index];
                    return FadeIn(
                      delay: Duration(milliseconds: 35 * index.clamp(0, 8)),
                      child: _DayGroup(
                        day: group.day,
                        movements: group.movements,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<_MovementGroup> _groupByDay(List<Movement> movements) {
    final map = <DateTime, List<Movement>>{};
    for (final movement in movements) {
      map.putIfAbsent(movement.day, () => <Movement>[]).add(movement);
    }

    final days = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return days
        .map((day) => _MovementGroup(day: day, movements: map[day]!))
        .toList();
  }
}

class _MovementGroup {
  const _MovementGroup({required this.day, required this.movements});

  final DateTime day;
  final List<Movement> movements;
}

/// Entro, salio y como queda el mes.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary});

  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Row(
      children: <Widget>[
        Expanded(
          child: _SummaryTile(
            label: 'Entro',
            amount: summary.income,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppConstants.spaceSm),
        Expanded(
          child: _SummaryTile(
            label: 'Salio',
            amount: summary.expense,
            color: scheme.error,
          ),
        ),
        const SizedBox(width: AppConstants.spaceSm),
        Expanded(
          child: _SummaryTile(
            label: 'Balance',
            amount: summary.balance,
            color: summary.balance < 0 ? scheme.error : scheme.primary,
            signed: true,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.color,
    this.signed = false,
  });

  final String label;
  final int amount;
  final Color color;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceSm,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: context.texts.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              signed ? Money.format(amount, sign: true) : Money.format(amount),
              style: context.texts.titleMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.day, required this.movements});

  final DateTime day;
  final List<Movement> movements;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final total = movements.fold<int>(0, (sum, m) => sum + m.amount);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
              left: 2,
              bottom: AppConstants.spaceSm,
            ),
            child: Row(
              children: <Widget>[
                Text(
                  DateNames.relativeDay(day).capitalized,
                  style: context.texts.titleSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppConstants.spaceSm),
                Expanded(
                  child: Container(height: 1, color: scheme.outlineVariant),
                ),
                const SizedBox(width: AppConstants.spaceSm),
                Text(
                  Money.format(total, sign: true),
                  style: context.texts.labelMedium?.copyWith(
                    color: total < 0 ? scheme.onSurfaceVariant : AppColors.success,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          for (final movement in movements)
            Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.spaceSm),
              child: MovementTile(movement: movement),
            ),
        ],
      ),
    );
  }
}

/// Una fila de movimiento, con el icono y el color de su categoria.
class MovementTile extends ConsumerWidget {
  const MovementTile({required this.movement, super.key});

  final Movement movement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colors;
    final category = ref.watch(categoryByIdProvider(movement.categoryId));
    final color = AppColors.categoryAccent(category?.colorIndex ?? 11);

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showMovementEditor(context, existing: movement),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceSm + 2,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Icon(
                  CategoryIcons.resolve(category?.iconName ?? 'label'),
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: AppConstants.spaceSm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      movement.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.titleSmall,
                    ),
                    Text(
                      category?.name ?? 'Sin categoria',
                      style: context.texts.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.spaceSm),
              Text(
                Money.format(movement.amount, sign: true),
                style: context.texts.titleSmall?.copyWith(
                  color: movement.isExpense ? scheme.error : AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMonth extends StatelessWidget {
  const _EmptyMonth();

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
                Icons.receipt_long_rounded,
                size: 34,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppConstants.spaceLg),
            Text('Mes sin movimientos', style: context.texts.titleLarge),
            const SizedBox(height: AppConstants.spaceXs),
            Text(
              'Toca el mas para registrar un gasto o un ingreso.',
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
