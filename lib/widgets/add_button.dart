import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_constants.dart';
import '../utils/extensions.dart';

/// El boton de crear, en la cabecera del area.
///
/// Estuvo flotando abajo a la derecha y no funcionaba: la barra de navegacion
/// se dibuja por encima de todo el contenido del area, asi que el boton quedaba
/// tapado por ella pasara lo que pasara. Arriba nada lo tapa, esta siempre en
/// el mismo sitio en las tres areas, y de paso queda al alcance del pulgar sin
/// competir con los botones del sistema.
class AddButton extends StatelessWidget {
  const AddButton({
    required this.onPressed,
    this.tooltip = 'Agregar',
    super.key,
  });

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final radius = BorderRadius.circular(AppConstants.radiusMd);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: scheme.primary.withValues(alpha: 0.16),
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          borderRadius: radius,
          child: Container(
            width: 40,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.45),
              ),
            ),
            child: Icon(Icons.add_rounded, size: 21, color: scheme.primary),
          ),
        ),
      ),
    );
  }
}
