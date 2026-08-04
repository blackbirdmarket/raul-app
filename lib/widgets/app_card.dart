import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

/// Contenedor estandar de contenido.
///
/// Cuando recibe `onTap` usa `InkWell` dentro de un `Material` recortado, de
/// modo que la onda del toque respete las esquinas redondeadas en vez de
/// desbordarse.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppConstants.spaceMd),
    this.color,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppConstants.radiusMd);

    return Material(
      color: color ?? scheme.surfaceContainerLow,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
