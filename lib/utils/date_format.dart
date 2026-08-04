import 'calendar.dart';

/// Nombres de fechas en espanol.
///
/// Se escriben a mano en vez de usar `intl` para no arrastrar la dependencia
/// ni obligar a inicializar locales: la aplicacion es de un solo idioma y esto
/// cabe en un archivo.
class DateNames {
  const DateNames._();

  static const List<String> weekdaysShort = <String>[
    'LUN', 'MAR', 'MIE', 'JUE', 'VIE', 'SAB', 'DOM',
  ];

  static const List<String> weekdaysLong = <String>[
    'lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo',
  ];

  static const List<String> months = <String>[
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  /// `DateTime.weekday` va de 1 (lunes) a 7 (domingo).
  static String weekdayShort(DateTime date) => weekdaysShort[date.weekday - 1];

  static String weekdayLong(DateTime date) => weekdaysLong[date.weekday - 1];

  static String month(DateTime date) => months[date.month - 1];

  /// "lunes 3 de agosto"
  static String longDate(DateTime date) =>
      '${weekdayLong(date)} ${date.day} de ${month(date)}';

  /// "3 de agosto"
  static String mediumDate(DateTime date) =>
      '${date.day} de ${month(date)}';

  /// "09:30"
  static String time(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';

  /// Titulo corto de un dia.
  ///
  /// Deliberadamente no incluye la fecha: debajo del titulo ya va la fecha
  /// completa, y repetirla ("Domingo 9 de agosto" sobre "9 de agosto") se lee
  /// como un error.
  static String dayTitle(DateTime date) {
    return switch (Calendar.daysBetween(DateTime.now(), date)) {
      0 => 'Hoy',
      1 => 'Manana',
      -1 => 'Ayer',
      _ => weekdayLong(date),
    };
  }

  /// Texto relativo cuando ayuda mas que la fecha exacta.
  static String relativeDay(DateTime date) {
    return switch (Calendar.daysBetween(DateTime.now(), date)) {
      0 => 'Hoy',
      1 => 'Manana',
      -1 => 'Ayer',
      _ => longDate(date),
    };
  }

  /// "1 h 30 min", "45 min"
  static String duration(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes % 60;
    if (hours == 0) return '$minutes min';
    if (minutes == 0) return '$hours h';
    return '$hours h $minutes min';
  }

  /// Lunes de la semana que contiene la fecha dada.
  static DateTime startOfWeek(DateTime date) => Calendar.startOfWeek(date);
}
