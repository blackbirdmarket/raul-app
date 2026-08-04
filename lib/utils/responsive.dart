import 'package:flutter/widgets.dart';

import '../core/constants/app_constants.dart';

/// Tamano de pantalla, clasificado.
enum ScreenSize { mobile, tablet, desktop }

/// Helpers para diseno responsive.
///
/// La clasificacion se hace en un solo lugar para que "que es una tablet" sea
/// una respuesta unica en toda la aplicacion, y no un `if (width > 700)`
/// distinto en cada pantalla.
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  ScreenSize get screenSize {
    final width = screenWidth;
    if (width < AppConstants.breakpointMobile) return ScreenSize.mobile;
    if (width < AppConstants.breakpointTablet) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  bool get isMobile => screenSize == ScreenSize.mobile;
  bool get isTablet => screenSize == ScreenSize.tablet;
  bool get isDesktop => screenSize == ScreenSize.desktop;

  /// Elige un valor segun el tamano de pantalla, cayendo al valor de movil
  /// cuando no se especifico uno mayor.
  T responsive<T>({required T mobile, T? tablet, T? desktop}) =>
      switch (screenSize) {
        ScreenSize.mobile => mobile,
        ScreenSize.tablet => tablet ?? mobile,
        ScreenSize.desktop => desktop ?? tablet ?? mobile,
      };
}

/// Centra y limita el ancho del contenido en pantallas grandes.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    required this.child,
    this.maxWidth = AppConstants.maxContentWidth,
    this.padding = const EdgeInsets.all(AppConstants.spaceMd),
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
