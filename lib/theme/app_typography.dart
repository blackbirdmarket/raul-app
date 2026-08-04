import 'package:flutter/material.dart';

/// Escala tipografica.
///
/// Se ajustan peso y espaciado sobre la escala de Material 3 en vez de
/// redefinir tamanos, para que el texto siga respetando la configuracion de
/// accesibilidad del telefono. Los titulos van apretados y pesados; el cuerpo,
/// aireado y legible.
///
/// La familia es Sora, empaquetada con la aplicacion. La letra por defecto de
/// Android es la misma que trae cualquier app del telefono, y eso solo basta
/// para que todo se vea generico por mucho que el resto este cuidado: la
/// tipografia es lo primero que el ojo reconoce.
class AppTypography {
  const AppTypography._();

  static const String family = 'Sora';

  static TextTheme textTheme(TextTheme base) => base.apply(
        fontFamily: family,
      ).copyWith(
        displayLarge: base.displayLarge?.copyWith(
          fontWeight: FontWeight.w300,
          letterSpacing: -2,
        ),
        displayMedium: base.displayMedium?.copyWith(
          fontWeight: FontWeight.w300,
          letterSpacing: -1.5,
        ),
        displaySmall: base.displaySmall?.copyWith(
          fontWeight: FontWeight.w400,
          letterSpacing: -1,
        ),
        headlineLarge: base.headlineLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
        ),
        headlineMedium: base.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.8,
        ),
        headlineSmall: base.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        titleLarge: base.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        titleMedium: base.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        bodyLarge: base.bodyLarge?.copyWith(height: 1.45),
        bodyMedium: base.bodyMedium?.copyWith(height: 1.45),
        bodySmall: base.bodySmall?.copyWith(height: 1.4),
        labelLarge: base.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
        labelMedium: base.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
        labelSmall: base.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      );
}
