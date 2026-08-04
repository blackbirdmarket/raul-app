import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/finance_category.dart';
import '../../../../models/money.dart';
import '../../../../models/movement.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/category_icons.dart';
import '../../../../utils/date_format.dart';
import '../../../../utils/extensions.dart';
import '../providers/finance_providers.dart';
import 'movements_view.dart';

/// Abre el detalle de una categoria dentro de un mes.
Future<void> showCategoryDetail(
  BuildContext context, {
  required String categoryId,
  required DateTime month,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // Sobre el navegador raiz: si se abre en el del area, la barra flotante
    // de abajo queda dibujada encima y tapa el boton de guardar.
    useRootNavigator: true,
    builder: (_) => _CategoryDetailSheet(categoryId: categoryId, month: month),
  );
}

/// Todo lo que se gasto en una categoria durante un mes.
///
/// La dona responde "cuanto", esta hoja responde "en que". Sin ella el
/// analisis se queda en una cifra bonita que no se puede accionar: uno ve que
/// Comida se llevo la mitad del mes y no tiene forma de saber si fueron dos
/// cuentas grandes o treinta cafes.
class _CategoryDetailSheet extends ConsumerWidget {
  const _CategoryDetailSheet({required this.categoryId, required this.month});

  final String categoryId;
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colors;
    final category = ref.watch(categoryByIdProvider(categoryId));
    final movements = ref.watch(
      movementsForCategoryProvider((month: month, categoryId: categoryId)),
    );

    final color = AppColors.categoryAccent(category?.colorIndex ?? 11);
    final total = movements.fold<int>(0, (sum, m) => sum + m.magnitude);
    final monthTotal = _monthTotal(ref, category?.kind ?? CategoryKind.expense);
    final share = monthTotal == 0 ? 0.0 : total / monthTotal;
    final grouped = _groupByDay(movements);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            AppConstants.spaceMd,
            AppConstants.spaceSm,
            AppConstants.spaceMd,
            AppConstants.spaceXl + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMd),
                  ),
                  child: Icon(
                    CategoryIcons.resolve(category?.iconName ?? 'label'),
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppConstants.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        category?.name ?? 'Sin categoria',
                        style: context.texts.headlineSmall,
                      ),
                      Text(
                        '${DateNames.month(month)} de ${month.year}'
                            .capitalized,
                        style: context.texts.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spaceLg),

            Container(
              padding: const EdgeInsets.all(AppConstants.spaceMd),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                border: Border.all(color: color.withValues(alpha: 0.35)),
                borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              ),
              child: Row(
                children: <Widget>[
                  _Figure(
                    label: 'Total',
                    value: Money.format(total),
                    color: color,
                  ),
                  _Divider(color: scheme.outlineVariant),
                  _Figure(
                    label: 'Del mes',
                    value: '${(share * 100).round()}%',
                    color: scheme.onSurface,
                  ),
                  _Divider(color: scheme.outlineVariant),
                  _Figure(
                    label: movements.length == 1 ? 'Registro' : 'Registros',
                    value: '${movements.length}',
                    color: scheme.onSurface,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spaceLg),

            if (grouped.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.spaceXl,
                ),
                child: Text(
                  'Este mes no hay nada en esta categoria.',
                  textAlign: TextAlign.center,
                  style: context.texts.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final group in grouped) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.only(
                    left: 2,
                    bottom: AppConstants.spaceSm,
                  ),
                  child: Row(
                    children: <Widget>[
                      Text(
                        DateNames.relativeDay(group.day).capitalized,
                        style: context.texts.titleSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: AppConstants.spaceSm),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: scheme.outlineVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                for (final movement in group.movements)
                  Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppConstants.spaceSm,
                    ),
                    child: MovementTile(movement: movement),
                  ),
                const SizedBox(height: AppConstants.spaceMd),
              ],
          ],
        );
      },
    );
  }

  /// Total del mes del mismo tipo (gasto o ingreso) que esta categoria, para
  /// que el porcentaje compare peras con peras.
  int _monthTotal(WidgetRef ref, CategoryKind kind) {
    return ref
        .watch(categoryTotalsProvider((month: month, kind: kind)))
        .fold<int>(0, (sum, total) => sum + total.amount);
  }

  List<_DayGroup> _groupByDay(List<Movement> movements) {
    final map = <DateTime, List<Movement>>{};
    for (final movement in movements) {
      map.putIfAbsent(movement.day, () => <Movement>[]).add(movement);
    }

    final days = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return days
        .map((day) => _DayGroup(day: day, movements: map[day]!))
        .toList();
  }
}

class _DayGroup {
  const _DayGroup({required this.day, required this.movements});

  final DateTime day;
  final List<Movement> movements;
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: context.texts.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: context.texts.titleMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.spaceSm),
      color: color,
    );
  }
}
