/// Rutas de la aplicacion.
///
/// Cada ruta de primer nivel es un area del sistema. Las que vengan se suman
/// aqui y en la barra inferior, sin tocar nada de lo que ya funciona.
class AppRoutes {
  const AppRoutes._();

  /// Area de planificacion: el dia, la agenda y el mes.
  static const String planning = '/';

  /// Area de finanzas: movimientos, cuentas y analisis.
  static const String finance = '/finanzas';

  /// Area de diario: los escritos y el animo del dia.
  static const String mindfulness = '/diario';

  static const String settings = '/ajustes';

  static const String planningName = 'planning';
  static const String financeName = 'finance';
  static const String mindfulnessName = 'mindfulness';
  static const String settingsName = 'settings';
}
