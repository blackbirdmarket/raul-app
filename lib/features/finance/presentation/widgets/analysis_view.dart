import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/finance_category.dart';
import '../../../../models/money.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/category_icons.dart';
import '../../../../utils/date_format.dart';
import '../../../../utils/extensions.dart';
import '../../../../widgets/category_donut.dart';
import '../../../../widgets/fade_in.dart';
import '../../../../widgets/month_selector.dart';
import '../providers/finance_providers.dart';
import 'category_detail_sheet.dart';

/// En que se fue el mes.
///
/// La dona da la forma del mes de un vistazo y la lista de abajo da el
/// detalle. Las dos comparten color por categoria, que es lo que permite
/// saltar de una a otra sin leyenda aparte.
class AnalysisView extends ConsumerStatefulWidget {
  const AnalysisView({super.key});

  @override
  ConsumerState<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends ConsumerState<AnalysisView> {
  /// Categoria que se esta tocando. Resalta su porcion mientras el dedo esta
  /// encima, para ligar la fila con el trozo del grafico sin explicar nada.
  int? _pressed;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final month = ref.watch(selectedMonthProvider);
    final kind = ref.watch(analysisKindProvider);
    final totals = ref.watch(categoryTotalsProvider((month: month, kind: kind)));
    final monthController = ref.read(selectedMonthProvider.notifier);

    final total = totals.fold<int>(0, (sum, item) => sum + item.amount);

    // El indice resaltado puede quedar viejo si la lista se acorta entre el
    // toque y el redibujado (cambiar de mes con el dedo encima, por ejemplo).
    final pressed =
        _pressed != null && _pressed! < totals.length ? _pressed : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceMd,
        AppConstants.spaceXs,
        AppConstants.spaceMd,
        AppConstants.spaceXxl * 2,
      ),
      children: <Widget>[
        MonthSelector(
          month: month,
          isCurrent: month == SelectedMonthController.currentMonth(),
          onShift: monthController.shift,
          onTapLabel: monthController.goToCurrent,
        ),
        const SizedBox(height: AppConstants.spaceMd),

        _KindSwitch(
          value: kind,
          onChanged: (next) {
            setState(() => _pressed = null);
            ref.read(analysisKindProvider.notifier).select(next);
          },
        ),
        const SizedBox(height: AppConstants.spaceLg),

        Center(
          child: CategoryDonut(
            slices: <DonutSlice>[
              for (final item in totals)
                DonutSlice(
                  value: item.amount.toDouble(),
                  color: AppColors.categoryAccent(item.category.colorIndex),
                ),
            ],
            highlighted: pressed,
            size: 216,
            center: _DonutCenter(
              total: total,
              kind: kind,
              highlighted: pressed == null ? null : totals[pressed],
            ),
          ),
        ),

        const SizedBox(height: AppConstants.spaceXl),

        if (totals.isEmpty)
          _EmptyAnalysis(kind: kind, month: month)
        else
          for (var i = 0; i < totals.length; i++)
            FadeIn(
              delay: Duration(milliseconds: 40 * i.clamp(0, 8)),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spaceSm),
                child: _CategoryRow(
                  total: totals[i],
                  onPressChanged: (pressed) =>
                      setState(() => _pressed = pressed ? i : null),
                  onTap: () => showCategoryDetail(
                    context,
                    categoryId: totals[i].category.id,
                    month: month,
                  ),
                ),
              ),
            ),

        if (totals.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppConstants.spaceSm),
          Text(
            'Toca una categoria para ver en que se fue.',
            textAlign: TextAlign.center,
            style: context.texts.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// El total en el hueco de la dona.
///
/// Cambia al total de una categoria mientras se la toca, para no obligar a
/// mirar dos sitios a la vez.
class _DonutCenter extends StatelessWidget {
  const _DonutCenter({
    required this.total,
    required this.kind,
    this.highlighted,
  });

  final int total;
  final CategoryKind kind;
  final CategoryTotal? highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final item = highlighted;
    final amount = item?.amount ?? total;

    final label = item == null
        ? (kind == CategoryKind.expense ? 'Salio' : 'Entro')
        : item.category.name;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: context.texts.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            Money.format(amount),
            style: context.texts.headlineSmall?.copyWith(
              color: item == null
                  ? scheme.onSurface
                  : AppColors.categoryAccent(item.category.colorIndex),
            ),
          ),
        ),
        if (item != null)
          Text(
            '${item.percent}% del mes',
            style: context.texts.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// Una fila de la lista: icono, nombre, barra de proporcion y monto.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.total,
    required this.onTap,
    required this.onPressChanged,
  });

  final CategoryTotal total;
  final VoidCallback onTap;
  final ValueChanged<bool> onPressChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final color = AppColors.categoryAccent(total.category.colorIndex);
    final radius = BorderRadius.circular(AppConstants.radiusMd);

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onHighlightChanged: onPressChanged,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceSm + 2,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: radius,
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
                  CategoryIcons.resolve(total.category.iconName),
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: AppConstants.spaceSm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            total.category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.texts.titleSmall,
                          ),
                        ),
                        Text(
                          Money.format(total.amount),
                          style: context.texts.titleSmall?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppConstants.radiusFull,
                            ),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: total.share),
                              duration: AppConstants.durationSlow,
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) =>
                                  LinearProgressIndicator(
                                value: value,
                                minHeight: 5,
                                backgroundColor: scheme.surfaceContainerHigh,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppConstants.spaceSm),
                        SizedBox(
                          width: 34,
                          child: Text(
                            '${total.percent}%',
                            textAlign: TextAlign.right,
                            style: context.texts.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
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

/// Gasto / Ingreso, en una linea.
class _KindSwitch extends StatelessWidget {
  const _KindSwitch({required this.value, required this.onChanged});

  final CategoryKind value;
  final ValueChanged<CategoryKind> onChanged;

  static const List<({CategoryKind kind, String label, IconData icon})>
      _options = <({CategoryKind kind, String label, IconData icon})>[
    (
      kind: CategoryKind.expense,
      label: 'Gastos',
      icon: Icons.trending_down_rounded,
    ),
    (
      kind: CategoryKind.income,
      label: 'Ingresos',
      icon: Icons.trending_up_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Row(
        children: <Widget>[
          for (final option in _options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(option.kind),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: AppConstants.durationFast,
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: option.kind == value
                        ? scheme.primary.withValues(alpha: 0.18)
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusFull),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        option.icon,
                        size: 16,
                        color: option.kind == value
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        option.label,
                        style: context.texts.labelLarge?.copyWith(
                          fontSize: 13,
                          color: option.kind == value
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyAnalysis extends StatelessWidget {
  const _EmptyAnalysis({required this.kind, required this.month});

  final CategoryKind kind;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final name = DateNames.month(month);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceXl),
      child: Column(
        children: <Widget>[
          Text(
            kind == CategoryKind.expense
                ? 'Sin gastos este mes'
                : 'Sin ingresos este mes',
            style: context.texts.titleLarge,
          ),
          const SizedBox(height: AppConstants.spaceXs),
          Text(
            'Cuando registres movimientos de $name, aqui vas a ver el '
            'reparto por categoria.',
            textAlign: TextAlign.center,
            style: context.texts.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
