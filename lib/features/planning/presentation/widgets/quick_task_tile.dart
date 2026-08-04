import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/agenda_entry.dart';
import '../../../../models/alert_mode.dart';
import '../../../../utils/date_format.dart';
import '../../../../utils/extensions.dart';
import '../../../../widgets/check_circle.dart';
import '../providers/agenda_providers.dart';

/// Una tarea rapida dentro del riel.
///
/// Se dibuja como una pildora baja de vidrio, deliberadamente mas liviana que
/// un bloque: la jerarquia visual tiene que decir "esto se despacha en un
/// momento" sin que haya que leer nada. Al ser translucida deja pasar la luz
/// del fondo, y eso es lo que la separa de una fila de lista cualquiera.
class QuickTaskTile extends ConsumerWidget {
  const QuickTaskTile({
    required this.task,
    this.onTap,
    super.key,
  });

  final QuickTask task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colors;

    final radius = BorderRadius.circular(AppConstants.radiusMd);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDarkMode ? 0.3 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
      color: context.isDarkMode
          ? const Color(0xFF0E0E16).withValues(alpha: 0.58)
          : scheme.surfaceContainerLowest.withValues(alpha: 0.88),
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: radius,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceSm + 2,
            vertical: 8,
          ),
          child: Row(
            children: <Widget>[
              CheckCircle(
                checked: task.done,
                size: 22,
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(agendaProvider.notifier).toggleTask(task.id);
                },
              ),
              const SizedBox(width: AppConstants.spaceSm),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: AppConstants.durationFast,
                  style: context.texts.bodyLarge!.copyWith(
                    color: task.done
                        ? scheme.onSurfaceVariant
                        : scheme.onSurface,
                    decoration:
                        task.done ? TextDecoration.lineThrough : null,
                    decorationColor: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  child: Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (task.isRecurring) ...<Widget>[
                const SizedBox(width: 6),
                Icon(
                  Icons.repeat_rounded,
                  size: 15,
                  color: scheme.onSurfaceVariant,
                ),
              ],
              if (task.alert != AlertMode.none) ...<Widget>[
                const SizedBox(width: AppConstants.spaceSm),
                Icon(
                  task.alert == AlertMode.alarm
                      ? Icons.alarm_rounded
                      : Icons.notifications_none_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
              ],
              const SizedBox(width: AppConstants.spaceSm),
              Text(
                DateNames.time(task.start),
                style: context.texts.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0,
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
