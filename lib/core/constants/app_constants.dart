/// Constantes globales.
///
/// Todo valor que se use en mas de un lugar vive aqui, nunca escrito
/// directamente dentro de un widget. Asi un cambio se hace una sola vez.
class AppConstants {
  const AppConstants._();

  static const String appName = 'Ruli OS';
  static const String appVersion = '1.4.0';

  // --- Espaciado ---
  // Escala de 4 puntos. Usar siempre estos valores en vez de numeros sueltos.
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;
  static const double spaceXxl = 48;

  // --- Radios de borde ---
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 28;
  static const double radiusFull = 999;

  // --- Duraciones de animacion ---
  static const Duration durationFast = Duration(milliseconds: 160);
  static const Duration durationNormal = Duration(milliseconds: 260);
  static const Duration durationSlow = Duration(milliseconds: 420);

  // --- Riel de horas ---
  /// Alto de una hora completa en el riel. Define la escala de todo el dia:
  /// subirlo da mas detalle, bajarlo hace que quepa mas dia en pantalla.
  static const double hourHeight = 78;

  /// Ancho de la columna con las etiquetas de hora.
  static const double hourGutter = 58;

  /// Primera y ultima hora que se dibujan. Fuera de este rango casi nunca
  /// hay nada planificado y solo obligaria a desplazarse de mas.
  static const int dayStartHour = 6;
  static const int dayEndHour = 23;

  /// Alto minimo de un bloque, para que uno de 15 minutos siga siendo
  /// legible y tocable.
  static const double minBlockHeight = 62;

  // --- Puntos de quiebre responsive ---
  static const double breakpointMobile = 600;
  static const double breakpointTablet = 900;
  static const double breakpointDesktop = 1200;

  /// Ancho maximo del contenido en pantallas grandes.
  static const double maxContentWidth = 620;
}
