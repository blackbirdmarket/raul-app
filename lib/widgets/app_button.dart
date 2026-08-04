import 'package:flutter/material.dart';

/// Jerarquia visual del boton.
enum AppButtonVariant { primary, secondary, text }

/// Boton unico de la aplicacion.
///
/// Existe para que "un boton" signifique lo mismo en todas las pantallas y
/// para resolver en un solo lugar el caso que siempre se olvida: mientras
/// esta cargando debe quedar deshabilitado, o el usuario dispara la accion
/// dos veces.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expanded = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  /// Si ocupa todo el ancho disponible.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final child = _buildChild(context);

    final button = switch (variant) {
      AppButtonVariant.primary =>
        FilledButton(onPressed: effectiveOnPressed, child: child),
      AppButtonVariant.secondary =>
        OutlinedButton(onPressed: effectiveOnPressed, child: child),
      AppButtonVariant.text =>
        TextButton(onPressed: effectiveOnPressed, child: child),
    };

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (icon == null) return Text(label);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
