import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// El fondo de toda la aplicacion.
///
/// Tres luces de color muy suaves sobre un fondo casi negro: ambar arriba,
/// turquesa a la izquierda y terracota a la derecha. Ninguna pasa del treinta
/// por ciento, asi que el fondo sigue siendo oscuro y el texto legible; lo que
/// aportan es que la pantalla deje de ser un rectangulo gris plano.
///
/// Se pinta una sola vez, envolviendo a todas las areas, y no dentro de cada
/// pantalla. Asi al cambiar de area el fondo no parpadea ni se redibuja: da la
/// sensacion de que uno se mueve dentro de una misma cosa.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    // En claro las mismas luces resultarian sucias sobre blanco, asi que se
    // bajan mucho: se nota el matiz, no la mancha.
    final strength = dark ? 1.0 : 0.35;
    final base = Theme.of(context).colorScheme.surface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: base,
        backgroundBlendMode: BlendMode.srcOver,
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -1.15),
                  radius: 1.05,
                  colors: <Color>[
                    AppColors.accent.withValues(alpha: 0.30 * strength),
                    AppColors.accent.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-1.1, -0.25),
                  radius: 0.85,
                  colors: <Color>[
                    AppColors.blockAccents[4]
                        .withValues(alpha: 0.17 * strength),
                    AppColors.blockAccents[4].withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.1, 0.35),
                  radius: 0.85,
                  colors: <Color>[
                    AppColors.blockAccents[3]
                        .withValues(alpha: 0.15 * strength),
                    AppColors.blockAccents[3].withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Superficie de vidrio: translucida, con borde tenue y desenfoque implicito.
///
/// Es la pieza que reemplaza a la tarjeta gris de siempre. Al dejar pasar el
/// fondo, cada tarjeta toma un matiz distinto segun donde este en la pantalla,
/// y eso es lo que hace que la interfaz se sienta con profundidad en vez de
/// pegada.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 17,
    this.accent,
    this.glow = false,
    this.onTap,
    this.onLongPress,
    this.opacity = 0.62,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Color de la pieza. Tine el borde y, si `glow` esta activo, el halo.
  final Color? accent;

  final bool glow;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Cuanto tapa el fondo. Mas bajo deja ver mas luz detras.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final border = BorderRadius.circular(radius);
    final tint = accent;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: border,
        boxShadow: <BoxShadow>[
          if (glow && tint != null)
            BoxShadow(
              color: tint.withValues(alpha: 0.16),
              blurRadius: 26,
              spreadRadius: -4,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.34 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: (dark
                ? const Color(0xFF0E0E16)
                : scheme.surfaceContainerLowest)
            .withValues(alpha: dark ? opacity : 0.86),
        borderRadius: border,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: border,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: border,
              border: Border.all(
                color: tint == null
                    ? scheme.outlineVariant
                    : tint.withValues(alpha: dark ? 0.42 : 0.55),
                width: tint == null ? 1 : 1.2,
              ),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
