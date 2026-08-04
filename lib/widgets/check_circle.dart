import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

/// Casilla circular con animacion al marcar.
///
/// Es el gesto que mas se repite en toda la aplicacion, asi que vale la pena
/// que se sienta bien: el relleno crece desde el centro y el tick aparece
/// escalando, en vez del salto seco de un Checkbox normal.
class CheckCircle extends StatelessWidget {
  const CheckCircle({
    required this.checked,
    this.onTap,
    this.size = 26,
    this.color,
    super.key,
  });

  final bool checked;
  final VoidCallback? onTap;
  final double size;

  /// Color del relleno al estar marcada. Por defecto el primario del tema.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = color ?? scheme.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // Area tocable comoda sin agrandar el circulo visible.
        padding: const EdgeInsets.all(6),
        child: AnimatedContainer(
          duration: AppConstants.durationFast,
          curve: Curves.easeOut,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: checked ? active : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: checked ? active : scheme.outline,
              width: 1.8,
            ),
          ),
          child: AnimatedScale(
            duration: AppConstants.durationFast,
            curve: Curves.easeOutBack,
            scale: checked ? 1 : 0,
            child: Icon(
              Icons.check_rounded,
              size: size * 0.66,
              color: scheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
