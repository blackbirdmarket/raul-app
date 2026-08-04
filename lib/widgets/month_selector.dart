import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../utils/date_format.dart';
import '../utils/extensions.dart';

/// Navegador de meses: "‹ agosto de 2026 ›".
///
/// Es el control que hoy falta para moverse por periodos largos. Tocar el
/// nombre del mes vuelve al actual, que es el gesto que uno intenta sin que
/// nadie se lo explique.
class MonthSelector extends StatelessWidget {
  const MonthSelector({
    required this.month,
    required this.onShift,
    this.onTapLabel,
    this.isCurrent = true,
    super.key,
  });

  final DateTime month;

  /// -1 para el mes anterior, 1 para el siguiente.
  final ValueChanged<int> onShift;

  final VoidCallback? onTapLabel;

  /// Cuando no es el mes actual, el control se marca para que se note que uno
  /// esta mirando otro periodo.
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final label = '${DateNames.month(month)} de ${month.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _Arrow(
          icon: Icons.chevron_left_rounded,
          onTap: () => onShift(-1),
        ),
        Expanded(
          child: GestureDetector(
            onTap: onTapLabel,
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: AppConstants.durationFast,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spaceMd,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: isCurrent
                    ? scheme.surfaceContainer
                    : scheme.primary.withValues(alpha: 0.16),
                border: Border.all(
                  color: isCurrent ? scheme.outlineVariant : scheme.primary,
                ),
                borderRadius: BorderRadius.circular(AppConstants.radiusFull),
              ),
              child: Text(
                label.capitalized,
                textAlign: TextAlign.center,
                style: context.texts.titleSmall?.copyWith(
                  color: isCurrent ? scheme.onSurface : scheme.primary,
                ),
              ),
            ),
          ),
        ),
        _Arrow(
          icon: Icons.chevron_right_rounded,
          onTap: () => onShift(1),
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Icon(icon, size: 24, color: scheme.onSurfaceVariant),
      ),
    );
  }
}
