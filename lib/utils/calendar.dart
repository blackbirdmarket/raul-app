/// Aritmetica de calendario, no de duracion.
///
/// La diferencia importa y es la fuente de errores mas silenciosa que hay en
/// una agenda. `fecha.add(Duration(days: 1))` suma **24 horas exactas**, y en
/// los dos dias del ano en que Chile cambia de horario un dia dura 23 o 25
/// horas. El resultado es que una repeticion diaria a las 09:00 pasa a las
/// 08:00, y en el peor caso cae en el dia anterior.
///
/// Construir la fecha de nuevo con `DateTime(ano, mes, dia + n)` ignora el
/// cambio de horario y conserva el dia y la hora que uno espera ver en un
/// calendario. Dart normaliza solo los desbordes: dia 32 pasa a ser el 1 del
/// mes siguiente.
class Calendar {
  const Calendar._();

  /// Suma (o resta, con negativos) dias conservando la hora del reloj.
  static DateTime addDays(DateTime date, int days) => DateTime(
        date.year,
        date.month,
        date.day + days,
        date.hour,
        date.minute,
        date.second,
      );

  /// La fecha sin hora, que es la clave con la que se agrupa la agenda.
  static DateTime dayOf(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime today() => dayOf(DateTime.now());

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  static bool isYesterday(DateTime date) =>
      isSameDay(date, addDays(DateTime.now(), -1));

  static bool isTomorrow(DateTime date) =>
      isSameDay(date, addDays(DateTime.now(), 1));

  /// Diferencia en dias de calendario, sin que las horas la desvien.
  static int daysBetween(DateTime from, DateTime to) =>
      dayOf(to).difference(dayOf(from)).inDays;

  /// Lunes de la semana que contiene la fecha dada.
  static DateTime startOfWeek(DateTime date) =>
      addDays(dayOf(date), -(date.weekday - 1));
}
