import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

/// Barra de progreso fina y animada.
///
/// Se dibuja con dos contenedores en vez de `LinearProgressIndicator` porque
/// este ultimo no permite extremos redondeados ni una altura tan baja, y aqui
/// la barra tiene que leerse como un detalle, no como una carga en curso.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    required this.progress,
    this.height = 4,
    this.color,
    super.key,
  });

  /// Entre 0 y 1. Se recorta por seguridad.
  final double progress;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = color ?? scheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      child: SizedBox(
        height: height,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: ColoredBox(color: scheme.surfaceContainerHighest),
            ),
            // FractionallySizedBox evita tener que medir el ancho a mano.
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                duration: AppConstants.durationNormal,
                curve: Curves.easeOut,
                tween: Tween<double>(
                  begin: 0,
                  end: progress.clamp(0.0, 1.0).toDouble(),
                ),
                builder: (context, value, child) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: value,
                  child: ColoredBox(color: active),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
