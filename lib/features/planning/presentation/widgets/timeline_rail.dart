import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/agenda_entry.dart';
import '../../../../utils/extensions.dart';
import 'quick_task_tile.dart';
import 'time_block_card.dart';

/// Riel de horas del dia.
///
/// Dibuja las horas a la izquierda y coloca cada elemento en su posicion real:
/// un bloque de dos horas ocupa el doble que uno de una. Eso es lo que hace
/// que los huecos libres se vean sin tener que contarlos.
class TimelineRail extends StatefulWidget {
  const TimelineRail({
    required this.day,
    required this.entries,
    required this.onEntryTap,
    this.onEmptyTap,
    super.key,
  });

  final DateTime day;
  final List<AgendaEntry> entries;
  final void Function(AgendaEntry entry) onEntryTap;

  /// Se llama al tocar un hueco libre, con la hora tocada ya redondeada.
  /// Crear algo donde uno esta mirando es mas natural que ir al boton.
  final void Function(DateTime at)? onEmptyTap;

  @override
  State<TimelineRail> createState() => _TimelineRailState();
}

class _TimelineRailState extends State<TimelineRail> {
  late final ScrollController _controller =
      ScrollController(initialScrollOffset: _initialOffset());

  static const int _startHour = AppConstants.dayStartHour;
  static const int _endHour = AppConstants.dayEndHour;
  static const double _hourHeight = AppConstants.hourHeight;

  double get _totalHeight => (_endHour - _startHour + 1) * _hourHeight;

  /// Abre el dia cerca de la hora actual en vez de a las 6 de la manana.
  double _initialOffset() {
    final now = DateTime.now();
    final isToday = _isSameDay(now, widget.day);
    final hour = isToday ? now.hour : 8;
    final offset = (hour - _startHour - 1) * _hourHeight;
    return offset.clamp(0, double.maxFinite).toDouble();
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _topFor(DateTime time) {
    final minutes = (time.hour * 60 + time.minute) - _startHour * 60;
    return (minutes / 60) * _hourHeight;
  }

  void _handleTapUp(TapUpDetails details) {
    final onEmptyTap = widget.onEmptyTap;
    if (onEmptyTap == null) return;

    final minutesFromStart = (details.localPosition.dy / _hourHeight) * 60;
    final totalMinutes = _startHour * 60 + minutesFromStart;
    // Se redondea a media hora: nadie planifica a las 9:07.
    final rounded = (totalMinutes / 30).round() * 30;

    onEmptyTap(
      DateTime(
        widget.day.year,
        widget.day.month,
        widget.day.day,
        (rounded ~/ 60).clamp(0, 23),
        rounded % 60,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final railWidth =
            constraints.maxWidth - AppConstants.hourGutter - AppConstants.spaceMd;
        final placements = _layout(widget.entries);

        return SingleChildScrollView(
          controller: _controller,
          padding: const EdgeInsets.only(bottom: 120),
          child: SizedBox(
            height: _totalHeight,
            child: Stack(
              children: <Widget>[
                // Fondo: lineas de hora y captura de toques en huecos.
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: _handleTapUp,
                    child: const _HourGrid(
                      startHour: _startHour,
                      endHour: _endHour,
                    ),
                  ),
                ),

                if (_isSameDay(DateTime.now(), widget.day))
                  Positioned(
                    top: _topFor(DateTime.now()),
                    left: AppConstants.hourGutter - 10,
                    right: 0,
                    child: const _NowIndicator(),
                  ),

                for (final placement in placements)
                  Positioned(
                    top: placement.top,
                    height: placement.height,
                    left: AppConstants.hourGutter +
                        placement.lane * (railWidth / placement.laneCount),
                    width: (railWidth / placement.laneCount) - 6,
                    child: _EntryView(
                      placement: placement,
                      onTap: () => widget.onEntryTap(placement.entry),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Calcula posicion, alto y carril de cada elemento.
  ///
  /// Los que se solapan en el tiempo se reparten el ancho en carriles, para
  /// que ninguno quede escondido detras de otro.
  List<_Placement> _layout(List<AgendaEntry> entries) {
    if (entries.isEmpty) return const <_Placement>[];

    final sorted = <AgendaEntry>[...entries]
      ..sort((a, b) => a.start.compareTo(b.start));

    final rects = <_Rect>[];
    for (final entry in sorted) {
      final top = _topFor(entry.start).clamp(0.0, _totalHeight).toDouble();
      final double height;

      if (entry is TimeBlock) {
        final natural = (entry.duration.inMinutes / 60) * _hourHeight;
        height = natural
            .clamp(AppConstants.minBlockHeight, _totalHeight)
            .toDouble();
      } else {
        height = 52;
      }

      rects.add(_Rect(entry: entry, top: top, height: height));
    }

    final placements = <_Placement>[];
    var index = 0;

    while (index < rects.length) {
      // Un grupo son los elementos encadenados por solapamiento.
      final group = <_Rect>[rects[index]];
      var groupEnd = rects[index].bottom;
      var next = index + 1;

      while (next < rects.length && rects[next].top < groupEnd) {
        group.add(rects[next]);
        if (rects[next].bottom > groupEnd) groupEnd = rects[next].bottom;
        next++;
      }

      // Dentro del grupo, cada uno toma el primer carril que este libre.
      final laneEnds = <double>[];
      final lanes = <int>[];

      for (final rect in group) {
        var lane = laneEnds.indexWhere((end) => end <= rect.top);
        if (lane == -1) {
          laneEnds.add(rect.bottom);
          lane = laneEnds.length - 1;
        } else {
          laneEnds[lane] = rect.bottom;
        }
        lanes.add(lane);
      }

      for (var i = 0; i < group.length; i++) {
        placements.add(
          _Placement(
            entry: group[i].entry,
            top: group[i].top,
            height: group[i].height,
            lane: lanes[i],
            laneCount: laneEnds.length,
          ),
        );
      }

      index = next;
    }

    return placements;
  }
}

class _Rect {
  const _Rect({
    required this.entry,
    required this.top,
    required this.height,
  });

  final AgendaEntry entry;
  final double top;
  final double height;

  double get bottom => top + height;
}

class _Placement {
  const _Placement({
    required this.entry,
    required this.top,
    required this.height,
    required this.lane,
    required this.laneCount,
  });

  final AgendaEntry entry;
  final double top;
  final double height;
  final int lane;
  final int laneCount;
}

class _EntryView extends StatelessWidget {
  const _EntryView({required this.placement, required this.onTap});

  final _Placement placement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final entry = placement.entry;

    return switch (entry) {
      TimeBlock() => TimeBlockCard(
          block: entry,
          height: placement.height,
          onTap: onTap,
          // Con poco alto los pasos no caben y solo estorban.
          showSubtasks: placement.height > 92,
        ),
      QuickTask() => QuickTaskTile(task: entry, onTap: onTap),
    };
  }
}

/// Lineas y etiquetas de hora.
class _HourGrid extends StatelessWidget {
  const _HourGrid({required this.startHour, required this.endHour});

  final int startHour;
  final int endHour;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Column(
      children: <Widget>[
        for (var hour = startHour; hour <= endHour; hour++)
          SizedBox(
            height: AppConstants.hourHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: AppConstants.hourGutter,
                  child: Transform.translate(
                    // Sube la etiqueta para que quede alineada con su linea.
                    offset: const Offset(0, -7),
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      textAlign: TextAlign.right,
                      style: context.texts.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontSize: 11,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.spaceSm),
                Expanded(
                  child: Container(height: 1, color: scheme.outlineVariant),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Linea de la hora actual.
class _NowIndicator extends StatelessWidget {
  const _NowIndicator();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Row(
      children: <Widget>[
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: scheme.error,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: scheme.error.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        Expanded(child: Container(height: 1.4, color: scheme.error)),
      ],
    );
  }
}
