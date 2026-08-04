import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/agenda_entry.dart';
import '../../../../models/alert_mode.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/date_format.dart';
import '../../../../utils/extensions.dart';
import '../../../../widgets/check_circle.dart';
import '../providers/agenda_providers.dart';
import 'entry_editor_sheet.dart';

/// Abre la ficha de un elemento de la agenda.
Future<void> showEntryDetail(
  BuildContext context, {
  required String entryId,
  required DateTime day,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // Sobre el navegador raiz: si se abre en el del area, la barra flotante
    // de abajo queda dibujada encima y tapa el boton de guardar.
    useRootNavigator: true,
    builder: (_) => _EntryDetailSheet(entryId: entryId, day: day),
  );
}

/// Ficha de lectura de una tarea o un bloque.
///
/// Tocar algo abria el editor, y eso obligaba a entrar en modo edicion solo
/// para mirar. Aqui se ve todo de un vistazo y ademas se pueden tachar los
/// pasos sin tocar nada mas; editar queda detras de un boton propio, que es
/// donde uno espera encontrarlo cuando de verdad quiere cambiar algo.
///
/// Observa la agenda por identificador en vez de recibir el objeto: al marcar
/// un paso la ficha se actualiza sola, sin cerrarse ni quedar desfasada.
class _EntryDetailSheet extends ConsumerWidget {
  const _EntryDetailSheet({required this.entryId, required this.day});

  final String entryId;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(agendaProvider);

    AgendaEntry? found;
    for (final candidate in entries) {
      if (candidate.id == entryId) {
        found = candidate;
        break;
      }
    }

    // Si el elemento se borro desde otro lado, la hoja se cierra sola en vez
    // de quedarse mostrando algo que ya no existe.
    if (found == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox(height: 120);
    }

    final entry = found;
    final block = entry is TimeBlock ? entry : null;
    final accent = block == null
        ? context.colors.primary
        : AppColors.blockAccent(block.colorIndex);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: block == null ? 0.42 : 0.62,
      minChildSize: 0.3,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            AppConstants.spaceMd + 4,
            AppConstants.spaceSm,
            AppConstants.spaceMd + 4,
            AppConstants.spaceXl + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: <Widget>[
            _Head(entry: entry, accent: accent, day: day),
            const SizedBox(height: AppConstants.spaceLg),
            _Figures(entry: entry, accent: accent),
            if (entry.notes != null && entry.notes!.isNotBlank) ...<Widget>[
              const SizedBox(height: AppConstants.spaceMd),
              _Notes(text: entry.notes!),
            ],
            if (block != null && block.subtasks.isNotEmpty) ...<Widget>[
              const SizedBox(height: AppConstants.spaceLg),
              _Label('Pasos'),
              const SizedBox(height: AppConstants.spaceXs),
              for (var i = 0; i < block.subtasks.length; i++)
                _StepRow(
                  block: block,
                  index: i,
                  accent: accent,
                  last: i == block.subtasks.length - 1,
                ),
            ],
            const SizedBox(height: AppConstants.spaceLg),
            _Actions(entry: entry, accent: accent, day: day),
          ],
        );
      },
    );
  }
}

class _Head extends StatelessWidget {
  const _Head({required this.entry, required this.accent, required this.day});

  final AgendaEntry entry;
  final Color accent;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final isBlock = entry is TimeBlock;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          child: Icon(
            isBlock ? Icons.view_agenda_rounded : Icons.bolt_rounded,
            color: accent,
            size: 22,
          ),
        ),
        const SizedBox(width: AppConstants.spaceMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(entry.title, style: context.texts.headlineSmall),
              const SizedBox(height: 2),
              Text(
                isBlock
                    ? '${DateNames.relativeDay(entry.start).capitalized} · '
                        '${DateNames.time(entry.start)} – '
                        '${DateNames.time(entry.end)}'
                    : '${DateNames.relativeDay(entry.start).capitalized} · '
                        '${DateNames.time(entry.start)}',
                style: context.texts.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// La fila de cifras: duracion, avance y aviso.
class _Figures extends StatelessWidget {
  const _Figures({required this.entry, required this.accent});

  final AgendaEntry entry;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final block = entry is TimeBlock ? entry as TimeBlock : null;

    return Row(
      children: <Widget>[
        _Figure(
          label: block == null ? 'Estado' : 'Duracion',
          value: block == null
              ? ((entry as QuickTask).done ? 'Hecha' : 'Pendiente')
              : DateNames.duration(entry.duration),
          color: context.colors.onSurface,
        ),
        const SizedBox(width: AppConstants.spaceSm),
        if (block != null && block.subtasks.isNotEmpty)
          _Figure(
            label: 'Pasos',
            value: '${block.doneCount} / ${block.subtasks.length}',
            color: accent,
          )
        else
          _Figure(
            label: 'Repite',
            value: entry.isRecurring ? 'Si' : 'No',
            color: context.colors.onSurface,
          ),
        const SizedBox(width: AppConstants.spaceSm),
        _Figure(
          label: 'Aviso',
          value: switch (entry.alert) {
            AlertMode.none => 'Ninguno',
            AlertMode.notification => 'Aviso',
            AlertMode.alarm => 'Alarma',
          },
          color: entry.alert == AlertMode.alarm
              ? accent
              : context.colors.onSurface,
        ),
      ],
    );
  }
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
    final scheme = context.colors;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow.withValues(alpha: 0.6),
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
                fontSize: 8.5,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: context.texts.titleSmall?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notes extends StatelessWidget {
  const _Notes({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.5),
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      ),
      child: Text(
        text,
        style: context.texts.bodyMedium?.copyWith(height: 1.5),
      ),
    );
  }
}

class _StepRow extends ConsumerWidget {
  const _StepRow({
    required this.block,
    required this.index,
    required this.accent,
    required this.last,
  });

  final TimeBlock block;
  final int index;
  final Color accent;
  final bool last;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colors;
    final step = block.subtasks[index];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: <Widget>[
          CheckCircle(
            checked: step.done,
            size: 22,
            color: accent,
            onTap: () {
              HapticFeedback.selectionClick();
              ref
                  .read(agendaProvider.notifier)
                  .toggleSubTask(block.id, step.id);
            },
          ),
          const SizedBox(width: AppConstants.spaceSm),
          Expanded(
            child: Text(
              step.title,
              style: context.texts.bodyLarge?.copyWith(
                color: step.done ? scheme.onSurfaceVariant : scheme.onSurface,
                decoration: step.done ? TextDecoration.lineThrough : null,
                decorationColor: scheme.onSurfaceVariant,
              ),
            ),
          ),
          if (step.hasReminder) ...<Widget>[
            const SizedBox(width: AppConstants.spaceSm),
            Icon(
              step.alert == AlertMode.alarm
                  ? Icons.alarm_rounded
                  : Icons.notifications_none_rounded,
              size: 15,
              color: step.alert == AlertMode.alarm
                  ? accent
                  : scheme.onSurfaceVariant,
            ),
            if (step.remindAt != null) ...<Widget>[
              const SizedBox(width: 4),
              Text(
                DateNames.time(step.remindAt!),
                style: context.texts.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  const _Actions({
    required this.entry,
    required this.accent,
    required this.day,
  });

  final AgendaEntry entry;
  final Color accent;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colors;
    final block = entry is TimeBlock ? entry as TimeBlock : null;
    final complete = entry.isComplete;

    // La accion principal cambia segun lo que sea y como este: para una tarea
    // es marcarla, para un bloque es despachar todos sus pasos de una.
    final String primary;
    if (block == null) {
      primary = complete ? 'Marcar pendiente' : 'Marcar hecha';
    } else if (block.subtasks.isEmpty) {
      primary = 'Sin pasos que marcar';
    } else {
      primary = complete ? 'Reabrir los pasos' : 'Completar todo';
    }

    final enabled = block == null || block.subtasks.isNotEmpty;

    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              showEntryEditor(context, day: day, existing: entry);
            },
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Editar'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: BorderSide(color: scheme.outline),
              foregroundColor: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: AppConstants.spaceSm),
        Expanded(
          child: FilledButton.icon(
            onPressed: enabled
                ? () {
                    HapticFeedback.mediumImpact();
                    _apply(ref, complete: complete);
                  }
                : null,
            icon: Icon(
              complete
                  ? Icons.replay_rounded
                  : Icons.done_all_rounded,
              size: 18,
            ),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(primary),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ],
    );
  }

  void _apply(WidgetRef ref, {required bool complete}) {
    final controller = ref.read(agendaProvider.notifier);
    final item = entry;

    if (item is QuickTask) {
      controller.toggleTask(item.id);
      return;
    }
    if (item is TimeBlock) {
      // Se recorre y se cambia solo lo que hace falta, en vez de reescribir
      // todos los pasos: asi no se pierde la hora de aviso de ninguno.
      for (final step in item.subtasks) {
        if (step.done == !complete) continue;
        controller.toggleSubTask(item.id, step.id);
      }
    }
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: context.texts.labelSmall?.copyWith(
        color: context.colors.onSurfaceVariant,
        fontSize: 9.5,
        letterSpacing: 1.4,
      ),
    );
  }
}
