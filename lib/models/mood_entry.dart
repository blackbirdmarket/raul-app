import '../utils/calendar.dart';

/// Como estuvo el dia, en cinco escalones.
///
/// Cinco y no diez: pedirle a alguien que distinga un 6 de un 7 sobre su
/// propio animo lo obliga a pensar en vez de responder, y a la semana deja de
/// registrar. Cinco se contesta sin pensar y sigue siendo suficiente para ver
/// una tendencia.
enum MoodLevel {
  awful(1, 'Muy mal', 3),
  bad(2, 'Mal', 3),
  ok(3, 'Normal', 5),
  good(4, 'Bien', 2),
  great(5, 'Muy bien', 2);

  const MoodLevel(this.value, this.label, this.colorIndex);

  final int value;
  final String label;

  /// Indice dentro de los acentos de la aplicacion. Los dos extremos bajos
  /// comparten terracota y los altos esmeralda: la escala se lee sin leyenda.
  final int colorIndex;

  static MoodLevel decode(Object? raw) {
    final value = raw is int ? raw : 3;
    for (final level in MoodLevel.values) {
      if (level.value == value) return level;
    }
    return MoodLevel.ok;
  }
}

/// Un registro de animo de un dia.
///
/// Se guarda uno por dia y la clave es el propio dia: volver a registrar
/// reemplaza en vez de acumular, que es lo que uno espera al corregirse.
class MoodEntry {
  const MoodEntry({
    required this.day,
    required this.level,
    this.note,
    this.energy,
  });

  final DateTime day;
  final MoodLevel level;

  /// Una linea opcional. Es lo que, meses despues, explica por que ese dia
  /// estuvo como estuvo.
  final String? note;

  /// Energia del dia, de 1 a 5. Se pregunta aparte del animo porque no son lo
  /// mismo: se puede estar contento y agotado.
  final int? energy;

  /// Clave de almacenamiento: un dia, un registro.
  String get key => '${day.year}-${day.month}-${day.day}';

  MoodEntry copyWith({MoodLevel? level, String? note, int? energy}) {
    return MoodEntry(
      day: day,
      level: level ?? this.level,
      note: note ?? this.note,
      energy: energy ?? this.energy,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'day': day.millisecondsSinceEpoch,
        'level': level.value,
        'note': note,
        'energy': energy,
      };

  factory MoodEntry.fromMap(Map<dynamic, dynamic> map) {
    return MoodEntry(
      day: Calendar.dayOf(
        DateTime.fromMillisecondsSinceEpoch(map['day'] as int),
      ),
      level: MoodLevel.decode(map['level']),
      note: map['note'] as String?,
      energy: map['energy'] as int?,
    );
  }
}
