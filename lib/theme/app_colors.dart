import 'package:flutter/material.dart';

/// Paleta de la aplicacion.
///
/// Los esquemas se derivan de Material 3 pero con las superficies fijadas a
/// mano. La razon: `fromSeed` tine los grises con el color de acento, y un
/// ambar tiñendo los fondos los vuelve amarillentos. Los fondos quedan
/// neutros y el color se reserva para lo que de verdad importa.
class AppColors {
  const AppColors._();

  /// Ambar. Calido y de alto contraste sobre negro.
  static const Color accent = Color(0xFFE8A33D);
  static const Color accentSoft = Color(0xFFF2BE6B);

  /// Texto y iconos sobre el acento. Casi negro, porque el ambar es claro:
  /// texto blanco encima seria ilegible.
  static const Color onAccent = Color(0xFF241701);

  // --- Colores semanticos ---
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);

  /// Acentos para distinguir bloques de un vistazo.
  ///
  /// Elegidos con luminosidad pareja para que ninguno domine sobre los demas
  /// dentro del riel, y sin rosados ni violetas.
  static const List<Color> blockAccents = <Color>[
    Color(0xFFE8A33D), // ambar
    Color(0xFF56A8F5), // cielo
    Color(0xFF34D399), // esmeralda
    Color(0xFFE4735A), // terracota
    Color(0xFF22C7B4), // turquesa
    Color(0xFF8FA3BF), // acero
  ];

  static Color blockAccent(int index) =>
      blockAccents[index.abs() % blockAccents.length];

  /// Acentos para las categorias de finanzas.
  ///
  /// Son doce y no seis porque la dona del analisis dibuja todas las
  /// categorias juntas: con seis colores repetidos, dos porciones vecinas
  /// podrian salir identicas y el grafico dejaria de informar. Los primeros
  /// seis coinciden con los de los bloques, asi que nada de lo ya guardado
  /// cambia de color. Sin rosados ni violetas.
  static const List<Color> categoryAccents = <Color>[
    Color(0xFFE8A33D), // ambar
    Color(0xFF56A8F5), // cielo
    Color(0xFF34D399), // esmeralda
    Color(0xFFE4735A), // terracota
    Color(0xFF22C7B4), // turquesa
    Color(0xFF8FA3BF), // acero
    Color(0xFFD9C24A), // oro viejo
    Color(0xFFF0906B), // coral
    Color(0xFF9BCF52), // lima
    Color(0xFF4F7FE0), // cobalto
    Color(0xFFC9A87C), // arena
    Color(0xFF6E8899), // pizarra
  ];

  static Color categoryAccent(int index) =>
      categoryAccents[index.abs() % categoryAccents.length];

  /// Un tono muy oscuro del mismo color, para escribir encima cuando una
  /// pieza va pintada a color completo.
  ///
  /// Se deriva en vez de fijarse a mano porque los acentos son doce y van a
  /// crecer: negro puro encima de un turquesa se ve sucio, mientras que el
  /// mismo turquesa casi apagado se lee como parte de la pieza.
  static Color onColor(Color color) =>
      HSLColor.fromColor(color).withLightness(0.10).withSaturation(0.55)
          .toColor();

  static ColorScheme darkScheme() =>
      ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark)
          .copyWith(
        primary: accent,
        onPrimary: onAccent,
        primaryContainer: const Color(0xFF3D2A08),
        onPrimaryContainer: accentSoft,
        secondary: accentSoft,
        onSecondary: onAccent,
        surface: const Color(0xFF08080A),
        onSurface: const Color(0xFFF3F3F4),
        onSurfaceVariant: const Color(0xFF97979E),
        surfaceContainerLowest: const Color(0xFF060608),
        surfaceContainerLow: const Color(0xFF101014),
        surfaceContainer: const Color(0xFF141419),
        surfaceContainerHigh: const Color(0xFF1A1A20),
        surfaceContainerHighest: const Color(0xFF23232A),
        outline: const Color(0xFF3B3B44),
        outlineVariant: const Color(0xFF26262D),
        error: danger,
      );

  static ColorScheme lightScheme() =>
      ColorScheme.fromSeed(seedColor: accent).copyWith(
        primary: const Color(0xFF9A6B12),
        onPrimary: Colors.white,
        surface: const Color(0xFFFCFBF9),
        onSurface: const Color(0xFF17171A),
        onSurfaceVariant: const Color(0xFF6A6A73),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFF6F5F3),
        surfaceContainer: const Color(0xFFF1F0ED),
        surfaceContainerHigh: const Color(0xFFEBEAE6),
        surfaceContainerHighest: const Color(0xFFE4E3DE),
        outline: const Color(0xFFB6B6BC),
        outlineVariant: const Color(0xFFE0DFDB),
        error: const Color(0xFFDC2626),
      );
}
