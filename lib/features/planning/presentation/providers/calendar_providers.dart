import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../utils/calendar.dart';

/// Mes que se esta mirando en el calendario, normalizado al dia 1.
final calendarMonthProvider =
    NotifierProvider<CalendarMonthController, DateTime>(
  CalendarMonthController.new,
);

class CalendarMonthController extends Notifier<DateTime> {
  @override
  DateTime build() {
    final today = Calendar.today();
    return DateTime(today.year, today.month);
  }

  /// Avanza o retrocede meses. `DateTime` normaliza el desborde solo: mes 13
  /// pasa a ser enero del ano siguiente.
  void shift(int months) => state = DateTime(state.year, state.month + months);

  void goTo(DateTime month) => state = DateTime(month.year, month.month);
}

/// Dia elegido en el calendario.
///
/// Vive fuera de la pantalla porque el boton de crear ya no esta dentro del
/// area: lo dibuja el andamio, por encima de la barra, y necesita saber sobre
/// que dia crear sin poder preguntarselo a una pantalla que no conoce.
final calendarDayProvider = NotifierProvider<CalendarDayController, DateTime>(
  CalendarDayController.new,
);

class CalendarDayController extends Notifier<DateTime> {
  @override
  DateTime build() => Calendar.today();

  void select(DateTime day) {
    final normalized = Calendar.dayOf(day);
    state = normalized;
    // Elegir un dia del mes vecino arrastra el mes, para no dejar la seleccion
    // fuera de lo que se esta mirando.
    ref.read(calendarMonthProvider.notifier).goTo(normalized);
  }

  void goToToday() => select(Calendar.today());
}
