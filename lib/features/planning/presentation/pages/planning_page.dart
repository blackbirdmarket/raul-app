import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../utils/extensions.dart';
import '../providers/agenda_providers.dart';
import '../widgets/agenda_view.dart';
import '../widgets/day_view.dart';
import '../widgets/entry_editor_sheet.dart';

/// Area de planificacion.
///
/// El FAB de agregar se movio a AppShell para que flote sobre la barra Aurora.
/// El pill selector de vista se elimino: el icono de calendario en el header
/// abre un bottom sheet con todas las vistas, al estilo Google Calendar.
class PlanningPage extends ConsumerWidget {
  const PlanningPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(planningViewProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            const _AreaBar(),
            Expanded(
              child: IndexedStack(
                index: view.index,
                children: const <Widget>[
                  DayView(),
                  AgendaView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Header: etiqueta PLANNING + vista activa + icono selector.
class _AreaBar extends ConsumerWidget {
  const _AreaBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(planningViewProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceMd,
        AppConstants.spaceSm,
        AppConstants.spaceXs,
        AppConstants.spaceXs,
      ),
      child: Row(
        children: <Widget>[
          Text(
            'PLANNING',
            style: context.texts.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(width: AppConstants.spaceXs),
          Text(
            '\u00b7 ${view.label.toUpperCase()}',
            style: context.texts.labelSmall?.copyWith(
              color: context.colors.primary,
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => _showViewSheet(context, ref, view),
            icon: const Icon(Icons.calendar_view_day_rounded),
            tooltip: 'Cambiar vista',
            style: IconButton.styleFrom(
              foregroundColor: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showViewSheet(
    BuildContext context,
    WidgetRef ref,
    PlanningView current,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusLg),
        ),
      ),
      builder: (ctx) => _ViewSelectorSheet(
        current: current,
        onSelected: (next) {
          ref.read(planningViewProvider.notifier).select(next);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

/// Bottom sheet con la lista de vistas — patron Google Calendar.
class _ViewSelectorSheet extends StatelessWidget {
  const _ViewSelectorSheet({
    required this.current,
    required this.onSelected,
  });

  final PlanningView current;
  final ValueChanged<PlanningView> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(top: AppConstants.spaceSm),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spaceMd,
              AppConstants.spaceMd,
              AppConstants.spaceMd,
              AppConstants.spaceXs,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Vista',
                style: context.texts.titleSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          for (final view in PlanningView.values)
            ListTile(
              leading: Icon(
                view.icon,
                color: view == current
                    ? scheme.primary
                    : scheme.onSurfaceVariant,
              ),
              title: Text(
                view.label,
                style: context.texts.bodyLarge?.copyWith(
                  color: view == current ? scheme.primary : scheme.onSurface,
                  fontWeight: view == current
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              trailing: view == current
                  ? Icon(Icons.check_rounded, color: scheme.primary)
                  : null,
              onTap: () => onSelected(view),
            ),
          const SizedBox(height: AppConstants.spaceMd),
        ],
      ),
    );
  }
}
