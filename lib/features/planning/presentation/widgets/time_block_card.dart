import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/agenda_entry.dart';
import '../../../../models/alert_mode.dart';
import '../../../../models/sub_task.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/date_format.dart';
import '../../../../utils/extensions.dart';
import '../../../../widgets/check_circle.dart';
import '../providers/agenda_providers.dart';
import '../providers/now_provider.dart';

class TimeBlockCard extends ConsumerWidget {
  const TimeBlockCard({
    required this.block,
    this.height,
    this.onTap,
    this.showSubtasks = true,
    super.key,
  });

  final TimeBlock block;
  final double? height;
  final VoidCallback? onTap;
  final bool showSubtasks;

  Widget _subtasksSlot(Color accent, bool live) {
    final content = Padding(
      padding: const EdgeInsets.only(top: 10),
      child: _SubtaskList(block: block, accent: accent, live: live),
    );
    return height == null ? content : Flexible(child: content);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colors;
    final accent = AppColors.blockAccent(block.colorIndex);
    final complete = block.isComplete;

    // nowProvider es un StreamProvider: usamos .value con fallback a now()
    final now = ref.watch(nowProvider).value ?? DateTime.now();
    final live =
        !complete && !now.isBefore(block.start) && now.isBefore(block.end);

    final radius = BorderRadius.circular(AppConstants.radiusLg);
    final onFull = AppColors.onColor(accent);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withValues(alpha: live ? 0.34 : 0.13),
            blurRadius: live ? 30 : 22,
            spreadRadius: live ? -2 : -6,
          ),
        ],
      ),
      child: Material(
        color: live
            ? accent
            : (context.isDarkMode
                ? const Color(0xFF0E0E16).withValues(alpha: 0.62)
                : scheme.surfaceContainerLowest.withValues(alpha: 0.88)),
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: live ? onFull.withValues(alpha: 0.08) : null,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: live
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Color.lerp(accent, Colors.white, 0.18)!,
                        accent,
                      ],
                    )
                  : null,
              border: Border.all(
                color: live
                    ? Colors.transparent
                    : complete
                        ? scheme.outlineVariant
                        : accent.withValues(alpha: 0.42),
                width: live ? 0 : 1.2,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(14, 12, 13, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _Header(block: block, accent: accent, live: live),
                if (showSubtasks && block.subtasks.isNotEmpty)
                  _subtasksSlot(accent, live),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.block,
    required this.accent,
    required this.live,
  });

  final TimeBlock block;
  final Color accent;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final onFull = AppColors.onColor(accent);

    final strong = live
        ? onFull
        : block.isComplete
            ? scheme.onSurfaceVariant
            : scheme.onSurface;
    final soft =
        live ? onFull.withValues(alpha: 0.68) : scheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                block.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.titleMedium?.copyWith(
                  color: strong,
                  fontWeight: live ? FontWeight.w700 : null,
                  decoration:
                      block.isComplete ? TextDecoration.lineThrough : null,
                  decorationColor: scheme.onSurfaceVariant,
                ),
              ),
            ),
            if (live)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: onFull.withValues(alpha: 0.16),
                  borderRadius:
                      BorderRadius.circular(AppConstants.radiusFull),
                ),
                child: Text(
                  'AHORA',
                  style: context.texts.labelSmall?.copyWith(
                    color: onFull,
                    fontSize: 8.5,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: <Widget>[
            Text(
              '${DateNames.time(block.start)} - ${DateNames.time(block.end)}',
              style: context.texts.labelMedium?.copyWith(
                color: soft,
                letterSpacing: 0,
              ),
            ),
            if (block.isRecurring) ...<Widget>[
              const SizedBox(width: 6),
              Icon(Icons.repeat_rounded, size: 13, color: soft),
            ],
            if (block.alert != AlertMode.none) ...<Widget>[
              const SizedBox(width: 6),
              Icon(
                block.alert == AlertMode.alarm
                    ? Icons.alarm_rounded
                    : Icons.notifications_none_rounded,
                size: 13,
                color: soft,
              ),
            ],
            if (block.subtasks.isNotEmpty) ...<Widget>[
              const Spacer(),
              Text(
                '${block.doneCount}/${block.subtasks.length}',
                style: context.texts.labelMedium?.copyWith(
                  color: live ? onFull : accent,
                  letterSpacing: 0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        if (block.subtasks.isNotEmpty) ...<Widget>[
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusFull),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: block.progress),
              duration: AppConstants.durationSlow,
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 4,
                backgroundColor: live
                    ? onFull.withValues(alpha: 0.22)
                    : scheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation<Color>(
                  live ? onFull.withValues(alpha: 0.85) : accent,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SubtaskList extends StatelessWidget {
  const _SubtaskList({
    required this.block,
    required this.accent,
    required this.live,
  });

  final TimeBlock block;
  final Color accent;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final subtask in block.subtasks)
            _SubtaskRow(
              blockId: block.id,
              subtask: subtask,
              accent: accent,
              live: live,
            ),
        ],
      ),
    );
  }
}

class _SubtaskRow extends ConsumerWidget {
  const _SubtaskRow({
    required this.blockId,
    required this.subtask,
    required this.accent,
    required this.live,
  });

  final String blockId;
  final SubTask subtask;
  final Color accent;
  final bool live;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colors;
    final onFull = AppColors.onColor(accent);

    final strong = live ? onFull : scheme.onSurface;
    final soft =
        live ? onFull.withValues(alpha: 0.6) : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: <Widget>[
          CheckCircle(
            checked: subtask.done,
            size: 18,
            color: live ? onFull : accent,
            onTap: () {
              HapticFeedback.selectionClick();
              ref
                  .read(agendaProvider.notifier)
                  .toggleSubTask(blockId, subtask.id);
            },
          ),
          Expanded(
            child: Text(
              subtask.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.bodyMedium?.copyWith(
                color: subtask.done ? soft : strong,
                decoration: subtask.done ? TextDecoration.lineThrough : null,
                decorationColor: soft,
              ),
            ),
          ),
          if (subtask.hasReminder)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(
                subtask.alert == AlertMode.alarm
                    ? Icons.alarm_rounded
                    : Icons.notifications_none_rounded,
                size: 13,
                color: soft,
              ),
            ),
        ],
      ),
    );
  }
}
