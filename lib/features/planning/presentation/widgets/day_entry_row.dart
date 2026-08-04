import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/agenda_entry.dart';
import '../../../../models/alert_mode.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/date_format.dart';
import '../../../../utils/extensions.dart';
import 'entry_detail_sheet.dart';

/// Una fila de la lista del dia en el calendario.
///
/// Deliberadamente mas compacta que la tarjeta del riel: aqui no importa
/// cuanto dura cada cosa —el riel ya cuenta eso— sino que hay y en que orden.
/// Por eso el color se reduce a una franja lateral y cabe el dia entero sin
/// desplazarse.
class DayEntryRow extends ConsumerWidget {
  const DayEntryRow({required this.entry, required this.day, super.key});

  final AgendaEntry entry;
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colors;
    final item = entry;
    final block = item is TimeBlock ? item : null;

    final accent =
        block == null ? scheme.primary : AppColors.blockAccent(block.colorIndex);
    final complete = item.isComplete;
    final radius = BorderRadius.circular(AppConstants.radiusMd);

    final String subtitle;
    if (block == null) {
      subtitle = '${DateNames.time(item.start)} · tarea rapida';
    } else if (block.subtasks.isEmpty) {
      subtitle = '${DateNames.time(block.start)} – '
          '${DateNames.time(block.end)}';
    } else {
      subtitle = '${DateNames.time(block.start)} – '
          '${DateNames.time(block.end)} · '
          '${block.doneCount} de ${block.subtasks.length} pasos';
    }

    return Material(
      color: context.isDarkMode
          ? const Color(0xFF0E0E16).withValues(alpha: 0.6)
          : scheme.surfaceContainerLowest.withValues(alpha: 0.88),
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showEntryDetail(context, entryId: item.id, day: day),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: scheme.outlineVariant),
          ),
          padding: const EdgeInsets.fromLTRB(11, 11, 13, 11),
          child: Row(
            children: <Widget>[
              Container(
                width: 3,
                height: 34,
                decoration: BoxDecoration(
                  color: complete ? scheme.outline : accent,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: AppConstants.spaceSm + 3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.titleSmall?.copyWith(
                        color: complete
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                        decoration:
                            complete ? TextDecoration.lineThrough : null,
                        decorationColor: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: context.texts.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.isRecurring) ...<Widget>[
                const SizedBox(width: 6),
                Icon(
                  Icons.repeat_rounded,
                  size: 15,
                  color: scheme.onSurfaceVariant,
                ),
              ],
              if (item.alert != AlertMode.none) ...<Widget>[
                const SizedBox(width: 6),
                Icon(
                  item.alert == AlertMode.alarm
                      ? Icons.alarm_rounded
                      : Icons.notifications_none_rounded,
                  size: 15,
                  color: item.alert == AlertMode.alarm
                      ? accent
                      : scheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
