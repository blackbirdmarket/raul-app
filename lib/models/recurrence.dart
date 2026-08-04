import '../utils/calendar.dart';

/// Cada cuanto se repite algo.
enum RecurrenceType { none, daily, weekdays, weekly, everyNDays }

/// Regla de repeticion de un elemento de la agenda.
///
/// La aplicacion materializa las repeticiones: al crear una serie se generan
/// ocurrencias reales hasta un horizonte, cada una con su propia vida. Es mas
/// simple y mas honesto que calcularlas al vuelo, porque marcar la pastilla
/// del martes no deberia tener nada que ver con la del miercoles.
class Recurrence {
  const Recurrence({
    this.type = RecurrenceType.none,
    this.interval = 2,
  });

  static const Recurrence never = Recurrence();

  final RecurrenceType type;

  /// Solo se usa con `everyNDays`. Minimo 1.
  final int interval;

  bool get isActive => type != RecurrenceType.none;

  String get label => switch (type) {
        RecurrenceType.none => 'No se repite',
        RecurrenceType.daily => 'Todos los dias',
        RecurrenceType.weekdays => 'De lunes a viernes',
        RecurrenceType.weekly => 'Cada semana',
        RecurrenceType.everyNDays => 'Cada $interval dias',
      };

  String get shortLabel => switch (type) {
        RecurrenceType.none => 'Una vez',
        RecurrenceType.daily => 'Diaria',
        RecurrenceType.weekdays => 'Lun a vie',
        RecurrenceType.weekly => 'Semanal',
        RecurrenceType.everyNDays => 'Cada $interval d',
      };

  /// Siguiente fecha despues de `from`, conservando la hora del reloj.
  ///
  /// Usa `Calendar.addDays` y no `add(Duration(days: n))` a proposito: sumar
  /// duraciones corre la hora en los cambios de horario de Chile, y una
  /// pastilla de las 09:00 no puede pasar a las 08:00 sola.
  ///
  /// Devuelve `null` cuando no hay repeticion, para que quien genera la serie
  /// tenga una condicion de parada clara en vez de un bucle infinito.
  DateTime? nextAfter(DateTime from) {
    switch (type) {
      case RecurrenceType.none:
        return null;

      case RecurrenceType.daily:
        return Calendar.addDays(from, 1);

      case RecurrenceType.weekly:
        return Calendar.addDays(from, 7);

      case RecurrenceType.everyNDays:
        return Calendar.addDays(from, interval < 1 ? 1 : interval);

      case RecurrenceType.weekdays:
        // Salta sabados y domingos: viernes cae en lunes.
        var next = Calendar.addDays(from, 1);
        while (next.weekday == DateTime.saturday ||
            next.weekday == DateTime.sunday) {
          next = Calendar.addDays(next, 1);
        }
        return next;
    }
  }

  Recurrence copyWith({RecurrenceType? type, int? interval}) => Recurrence(
        type: type ?? this.type,
        interval: interval ?? this.interval,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'type': type.name,
        'interval': interval,
      };

  factory Recurrence.fromMap(Map<dynamic, dynamic> map) {
    return Recurrence(
      type: switch (map['type']) {
        'daily' => RecurrenceType.daily,
        'weekdays' => RecurrenceType.weekdays,
        'weekly' => RecurrenceType.weekly,
        'everyNDays' => RecurrenceType.everyNDays,
        _ => RecurrenceType.none,
      },
      interval: map['interval'] as int? ?? 2,
    );
  }
}
