import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../utils/extensions.dart';
import '../../../../widgets/add_button.dart';
import '../providers/finance_providers.dart';
import '../widgets/accounts_view.dart';
import '../widgets/analysis_view.dart';
import '../widgets/movement_editor_sheet.dart';
import '../widgets/movements_view.dart';

/// Area de finanzas.
///
/// Sigue la misma forma que Planning: el nombre del area arriba, el cambio de
/// vista justo debajo, y todo lo demas dentro. Que las dos areas se comporten
/// igual es lo que hace que la app se sienta una sola cosa y no dos apps
/// pegadas.
class FinancePage extends ConsumerWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(financeViewProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            const _AreaBar(),
            Expanded(
              child: IndexedStack(
                index: view.index,
                children: const <Widget>[
                  MovementsView(),
                  AccountsView(),
                  AnalysisView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaBar extends ConsumerWidget {
  const _AreaBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(financeViewProvider);

    // Con tres vistas la pastilla ya no cabe al lado del titulo, asi que baja
    // a su propia linea y ocupa el ancho completo. De paso los tres destinos
    // quedan del mismo tamano, que es lo que hace que se lean como iguales.
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceMd,
        AppConstants.spaceSm,
        AppConstants.spaceMd,
        AppConstants.spaceXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'FINANZAS',
                style: context.texts.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 10,
                  letterSpacing: 1.6,
                ),
              ),
              const Spacer(),
              AddButton(
                onPressed: () => showMovementEditor(context),
                tooltip: 'Registrar movimiento',
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spaceSm),
          _ViewSwitch(
            value: view,
            onChanged: (next) =>
                ref.read(financeViewProvider.notifier).select(next),
          ),
        ],
      ),
    );
  }
}

class _ViewSwitch extends StatelessWidget {
  const _ViewSwitch({required this.value, required this.onChanged});

  final FinanceView value;
  final ValueChanged<FinanceView> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Row(
        children: <Widget>[
          for (final option in FinanceView.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(option),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: AppConstants.durationFast,
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        option == value ? scheme.primary : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusFull),
                  ),
                  child: Text(
                    option.label,
                    textAlign: TextAlign.center,
                    style: context.texts.labelLarge?.copyWith(
                      fontSize: 13,
                      color: option == value
                          ? scheme.onPrimary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
