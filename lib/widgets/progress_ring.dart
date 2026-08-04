import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

/// Anillo de progreso con animacion.
///
/// Se dibuja a mano en vez de usar `CircularProgressIndicator` porque este
/// necesita extremos redondeados, grosor propio y un texto centrado — y
/// porque en el centro va la cuenta de pasos, que es la informacion que de
/// verdad se lee.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.progress,
    this.size = 34,
    this.strokeWidth = 3,
    this.color,
    this.label,
    super.key,
  });

  /// Entre 0 y 1. Se recorta por seguridad, para que un dato raro no dibuje
  /// un arco imposible.
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = color ?? scheme.primary;

    return TweenAnimationBuilder<double>(
      duration: AppConstants.durationNormal,
      curve: Curves.easeOut,
      tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
      builder: (context, value, child) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              progress: value,
              strokeWidth: strokeWidth,
              color: active,
              trackColor: scheme.outlineVariant,
            ),
            child: label == null
                ? null
                : Center(
                    child: Text(
                      label!,
                      style: TextStyle(
                        fontSize: size * 0.3,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final arc = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // arranca arriba, no a la derecha
      2 * math.pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.trackColor != trackColor;
}
