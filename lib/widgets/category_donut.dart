import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Una porcion de la dona.
class DonutSlice {
  const DonutSlice({required this.value, required this.color});

  /// Siempre positivo. Quien arma la lista ya decidio si mira gastos o
  /// ingresos, asi que aqui los signos solo estorbarian.
  final double value;

  final Color color;
}

/// Grafico de dona por categoria.
///
/// Se dibuja a mano en vez de sumar una libreria de graficos: lo que se
/// necesita son arcos y un hueco al medio, y una dependencia externa traeria
/// su propio estilo visual peleando con el de la aplicacion.
///
/// El centro queda libre a proposito. Ahi va el total, que es el dato que uno
/// busca primero; las porciones responden despues el "en que se fue".
class CategoryDonut extends StatelessWidget {
  const CategoryDonut({
    required this.slices,
    this.size = 200,
    this.thickness = 26,
    this.center,
    this.highlighted,
    this.emptyColor,
    super.key,
  });

  final List<DonutSlice> slices;
  final double size;
  final double thickness;

  /// Contenido del hueco central.
  final Widget? center;

  /// Porcion resaltada: crece un poco y las demas se apagan. Sirve para ligar
  /// la fila de la lista con su trozo del grafico sin necesidad de leyenda.
  final int? highlighted;

  final Color? emptyColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = slices.fold<double>(0, (sum, slice) => sum + slice.value);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          TweenAnimationBuilder<double>(
            // La clave depende del reparto: al cambiar de mes o de tipo, la
            // dona se vuelve a dibujar desde cero en vez de saltar de una
            // forma a otra.
            key: ValueKey<String>('${slices.length}:$total'),
            tween: Tween<double>(begin: 0, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, progress, _) {
              return CustomPaint(
                size: Size.square(size),
                painter: _DonutPainter(
                  slices: slices,
                  total: total,
                  thickness: thickness,
                  progress: progress,
                  highlighted: highlighted,
                  emptyColor: emptyColor ?? scheme.surfaceContainerHigh,
                ),
              );
            },
          ),
          if (center != null)
            SizedBox(
              width: size - thickness * 2 - 16,
              child: center,
            ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.total,
    required this.thickness,
    required this.progress,
    required this.highlighted,
    required this.emptyColor,
  });

  final List<DonutSlice> slices;
  final double total;
  final double thickness;
  final double progress;
  final int? highlighted;
  final Color emptyColor;

  /// Separacion entre porciones, en radianes. Un pelo de fondo entre colores
  /// hace que dos categorias vecinas se lean como dos y no como una mancha.
  static const double _gap = 0.035;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - thickness) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (slices.isEmpty || total <= 0) {
      canvas.drawArc(
        rect,
        0,
        math.pi * 2,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness
          ..color = emptyColor,
      );
      return;
    }

    // Arranca arriba, como un reloj: es de donde la vista sale sola.
    var start = -math.pi / 2;
    final single = slices.length == 1;

    for (var i = 0; i < slices.length; i++) {
      final slice = slices[i];
      final full = (slice.value / total) * math.pi * 2;
      final sweep = (full - (single ? 0 : _gap)) * progress;

      if (sweep > 0) {
        final isHighlighted = highlighted == null || highlighted == i;
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = highlighted == i ? thickness + 8 : thickness
          ..color = isHighlighted
              ? slice.color
              // Las no seleccionadas no desaparecen, solo se apagan: el
              // reparto completo sigue siendo legible de fondo.
              : slice.color.withValues(alpha: 0.22);

        canvas.drawArc(rect, start, sweep, false, paint);
      }

      start += full;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress ||
      old.highlighted != highlighted ||
      old.total != total ||
      old.slices.length != slices.length;
}
