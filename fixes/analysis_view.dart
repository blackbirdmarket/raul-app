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

        // FIX 3 — SegmentedButton nativo de Material 3 reemplaza al widget
        // propio _KindSwitch. Mismo comportamiento, menos codigo, y el estilo
        // de pastilla queda alineado con el resto del tema sin mantenimiento.
        SegmentedButton<CategoryKind>(
          segments: const <ButtonSegment<CategoryKind>>[
            ButtonSegment<CategoryKind>(
              value: CategoryKind.expense,
              label: Text('Gastos'),
            ),
            ButtonSegment<CategoryKind>(
              value: CategoryKind.income,
              label: Text('Ingresos'),
            ),
          ],
          selected: <CategoryKind>{kind},
          onSelectionChanged: (Set<CategoryKind> val) {
            setState(() => _pressed = null);
            ref.read(analysisKindProvider.notifier).select(val.first);
          },
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: scheme.primary,
            selectedForegroundColor: scheme.onPrimary,
            foregroundColor: scheme.onSurfaceVariant,
          ),
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
                  // FIX 1 — se pasa isHighlighted para que la barra de
                  // proporcion se ilumine junto con la porcion de la dona.
                  isHighlighted: pressed == i,
                  onPressChanged: (active) =>
                      setState(() => _pressed = active ? i : null),
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

    final amountColor = item == null
        ? scheme.onSurface
        : AppColors.categoryAccent(item.category.colorIndex);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // FIX 2a — label animado: cuando se toca una categoria el nombre
        // reemplaza "SALIO"/"ENTRO" con un crossfade suave.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: Text(
            label.toUpperCase(),
            key: ValueKey<String>(label),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: context.texts.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
        ),
        const SizedBox(height: 2),

        // FIX 2b — monto animado: crossfade de 220ms al cambiar categoria.
        // La ValueKey sobre el amount garantiza que Flutter detecte el cambio
        // aunque el widget sea del mismo tipo.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: FittedBox(
            key: ValueKey<int>(amount),
            fit: BoxFit.scaleDown,
            child: Text(
              Money.format(amount),
              style: context.texts.headlineSmall?.copyWith(
                color: amountColor,
              ),
            ),
          ),
        ),

        // FIX 2c — el porcentaje aparece/desaparece con AnimatedSize para
        // que el centro no salte cuando cambia su altura.
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: item != null
              ? Text(
                  '${item.percent}% del mes',
                  style: context.texts.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              : const SizedBox.shrink(),
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
    // FIX 1 — nuevo parametro: la fila sabe si esta resaltada para animar
    // su barra de color junto con la porcion de la dona.
    this.isHighlighted = false,
  });

  final CategoryTotal total;
  final VoidCallback onTap;
  final ValueChanged<bool> onPressChanged;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final color = AppColors.categoryAccent(total.category.colorIndex);
    final radius = BorderRadius.circular(AppConstants.radiusMd);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        // FIX 1 — fondo levemente tintado con el color de la categoria
        // cuando isHighlighted es true, creando el lazo visual con la dona.
        color: isHighlighted
            ? color.withValues(alpha: 0.10)
            : scheme.surfaceContainerLow,
        border: Border.all(
          color: isHighlighted
              ? color.withValues(alpha: 0.35)
              : scheme.outlineVariant,
        ),
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          onHighlightChanged: onPressChanged,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spaceSm + 2,
              vertical: 11,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isHighlighted ? 0.28 : 0.18),
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
                            width: 36,
                            child: Text(
                              '${total.percent}%',
                              textAlign: TextAlign.end,
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estado vacio
// ---------------------------------------------------------------------------

class _EmptyAnalysis extends StatelessWidget {
  const _EmptyAnalysis({required this.kind, required this.month});

  final CategoryKind kind;
  final ({int year, int month}) month;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final label = kind == CategoryKind.expense ? 'gastos' : 'ingresos';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.pie_chart_outline_rounded,
            size: 48,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppConstants.spaceMd),
          Text(
            'Sin $label este mes',
            style: context.texts.titleMedium?.copyWith(
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: AppConstants.spaceXs),
          Text(
            'Agrega un movimiento para ver el analisis.',
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
