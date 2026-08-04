import 'alert_mode.dart';
import 'recurrence.dart';
import 'sub_task.dart';

/// Genera identificadores unicos sin depender de paquetes externos.
///
/// El contador evita colisiones cuando se crean varios elementos dentro del
/// mismo microsegundo, cosa que pasa al generar una serie completa de golpe.
int _sequence = 0;
String newEntryId() {
  _sequence++;
  return '${DateTime.now().microsecondsSinceEpoch}-$_sequence';
}

/// Cualquier cosa que ocupa un lugar en la agenda.
///
/// Es un tipo sellado con exactamente dos formas, y esa restriccion es
/// deliberada: la aplicacion distingue entre lo que se hace de una (una tarea)
/// y lo que ocupa un rato y se descompone (un bloque). Toda la interfaz se
/// apoya en que no existe un tercer caso.
sealed class AgendaEntry {
  const AgendaEntry({
    required this.id,
    required this.title,
    required this.start,
    this.notes,
    this.alert = AlertMode.none,
    this.createdAt,
    this.seriesId,
    this.recurrence = Recurrence.never,
  });

  final String id;
  final String title;

  /// Fecha y hora en que empieza. La parte de fecha define a que dia
  /// pertenece el elemento.
  final DateTime start;

  final String? notes;
  final AlertMode alert;
  final DateTime? createdAt;

  /// Identifica todas las ocurrencias de una misma repeticion.
  ///
  /// Es `null` en lo que se creo una sola vez. Permite borrar o extender la
  /// serie completa sin tener que adivinar cuales elementos van juntos.
  final String? seriesId;

  final Recurrence recurrence;

  bool get isRecurring => seriesId != null && recurrence.isActive;

  /// Cuando termina. Una tarea rapida no dura, asi que termina donde empieza.
  DateTime get end;

  Duration get duration => end.difference(start);

  /// Si ya no queda nada pendiente en este elemento.
  bool get isComplete;

  /// Avance entre 0 y 1, para dibujar anillos y barras de progreso.
  double get progress;

  bool get hasReminder => alert != AlertMode.none;

  /// Dia al que pertenece, sin hora. Es la clave con la que se agrupa
  /// la agenda.
  DateTime get day => DateTime(start.year, start.month, start.day);

  /// Copia limpia de este elemento en otra fecha, para generar la serie.
  ///
  /// Los pasos se copian sin marcar: haber ordenado la cocina ayer no dice
  /// nada sobre la cocina de manana.
  AgendaEntry occurrenceAt(
    DateTime newStart, {
    required String newId,
    required String series,
  });

  Map<String, dynamic> toMap();

  /// Reconstruye el tipo correcto desde el almacenamiento.
  ///
  /// Si el campo `type` falta o no se reconoce se asume tarea rapida, para
  /// que un dato viejo o corrupto no haga desaparecer el elemento de la
  /// agenda sin explicacion.
  static AgendaEntry fromMap(Map<dynamic, dynamic> map) {
    return switch (map['type']) {
      'block' => TimeBlock.fromMap(map),
      _ => QuickTask.fromMap(map),
    };
  }

  /// Lectura comun de los campos compartidos, para no repetirla en cada tipo.
  static Recurrence _recurrenceFrom(Map<dynamic, dynamic> map) {
    final raw = map['recurrence'];
    return raw is Map ? Recurrence.fromMap(raw) : Recurrence.never;
  }

  static DateTime? _dateFrom(Object? value) =>
      value is int ? DateTime.fromMillisecondsSinceEpoch(value) : null;
}

/// Algo que se hace de una y se marca con un check.
///
/// Ejemplo: tomar una pastilla, llamar al dentista.
final class QuickTask extends AgendaEntry {
  const QuickTask({
    required super.id,
    required super.title,
    required super.start,
    super.notes,
    super.alert,
    super.createdAt,
    super.seriesId,
    super.recurrence,
    this.done = false,
  });

  final bool done;

  /// Ocurre en un instante: no bloquea tiempo en el riel.
  @override
  DateTime get end => start;

  @override
  bool get isComplete => done;

  @override
  double get progress => done ? 1 : 0;

  @override
  QuickTask occurrenceAt(
    DateTime newStart, {
    required String newId,
    required String series,
  }) {
    return QuickTask(
      id: newId,
      title: title,
      start: newStart,
      notes: notes,
      alert: alert,
      createdAt: createdAt,
      seriesId: series,
      recurrence: recurrence,
    );
  }

  QuickTask copyWith({
    String? title,
    DateTime? start,
    String? notes,
    AlertMode? alert,
    bool? done,
    Recurrence? recurrence,
  }) {
    return QuickTask(
      id: id,
      title: title ?? this.title,
      start: start ?? this.start,
      notes: notes ?? this.notes,
      alert: alert ?? this.alert,
      createdAt: createdAt,
      seriesId: seriesId,
      recurrence: recurrence ?? this.recurrence,
      done: done ?? this.done,
    );
  }

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
        'type': 'task',
        'id': id,
        'title': title,
        'start': start.millisecondsSinceEpoch,
        'notes': notes,
        'alert': alert.encode(),
        'createdAt': createdAt?.millisecondsSinceEpoch,
        'seriesId': seriesId,
        'recurrence': recurrence.toMap(),
        'done': done,
      };

  factory QuickTask.fromMap(Map<dynamic, dynamic> map) {
    return QuickTask(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      start: DateTime.fromMillisecondsSinceEpoch(map['start'] as int),
      notes: map['notes'] as String?,
      alert: AlertMode.decode(map['alert']),
      createdAt: AgendaEntry._dateFrom(map['createdAt']),
      seriesId: map['seriesId'] as String?,
      recurrence: AgendaEntry._recurrenceFrom(map),
      done: map['done'] as bool? ?? false,
    );
  }
}

/// Un tramo de tiempo con pasos dentro.
///
/// Ejemplo: "Ordenar casa" de 9 a 11, con cocina, bano y dormitorio adentro.
/// El bloque no se marca a mano: se completa solo cuando sus pasos estan
/// listos, porque marcarlo antes seria mentirse.
final class TimeBlock extends AgendaEntry {
  const TimeBlock({
    required super.id,
    required super.title,
    required super.start,
    required DateTime end,
    super.notes,
    super.alert,
    super.createdAt,
    super.seriesId,
    super.recurrence,
    this.subtasks = const <SubTask>[],
    this.colorIndex = 0,
  }) : _end = end;

  final DateTime _end;
  final List<SubTask> subtasks;

  /// Indice dentro de la paleta de acentos, para distinguir bloques de un
  /// vistazo sin tener que leerlos.
  final int colorIndex;

  @override
  DateTime get end => _end;

  int get doneCount => subtasks.where((s) => s.done).length;

  @override
  bool get isComplete => subtasks.isNotEmpty && doneCount == subtasks.length;

  @override
  double get progress => subtasks.isEmpty ? 0 : doneCount / subtasks.length;

  @override
  TimeBlock occurrenceAt(
    DateTime newStart, {
    required String newId,
    required String series,
  }) {
    return TimeBlock(
      id: newId,
      title: title,
      start: newStart,
      end: newStart.add(duration),
      notes: notes,
      alert: alert,
      createdAt: createdAt,
      seriesId: series,
      recurrence: recurrence,
      colorIndex: colorIndex,
      subtasks: subtasks
          .map((s) => s.copyWith(id: newEntryId(), done: false))
          .toList(),
    );
  }

  TimeBlock copyWith({
    String? title,
    DateTime? start,
    DateTime? end,
    String? notes,
    AlertMode? alert,
    List<SubTask>? subtasks,
    int? colorIndex,
    Recurrence? recurrence,
  }) {
    return TimeBlock(
      id: id,
      title: title ?? this.title,
      start: start ?? this.start,
      end: end ?? _end,
      notes: notes ?? this.notes,
      alert: alert ?? this.alert,
      createdAt: createdAt,
      seriesId: seriesId,
      recurrence: recurrence ?? this.recurrence,
      subtasks: subtasks ?? this.subtasks,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  @override
  Map<String, dynamic> toMap() => <String, dynamic>{
        'type': 'block',
        'id': id,
        'title': title,
        'start': start.millisecondsSinceEpoch,
        'end': _end.millisecondsSinceEpoch,
        'notes': notes,
        'alert': alert.encode(),
        'createdAt': createdAt?.millisecondsSinceEpoch,
        'seriesId': seriesId,
        'recurrence': recurrence.toMap(),
        'colorIndex': colorIndex,
        'subtasks': subtasks.map((s) => s.toMap()).toList(),
      };

  factory TimeBlock.fromMap(Map<dynamic, dynamic> map) {
    final rawSubtasks = map['subtasks'];

    return TimeBlock(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      start: DateTime.fromMillisecondsSinceEpoch(map['start'] as int),
      end: DateTime.fromMillisecondsSinceEpoch(
        map['end'] as int? ?? map['start'] as int,
      ),
      notes: map['notes'] as String?,
      alert: AlertMode.decode(map['alert']),
      createdAt: AgendaEntry._dateFrom(map['createdAt']),
      seriesId: map['seriesId'] as String?,
      recurrence: AgendaEntry._recurrenceFrom(map),
      colorIndex: map['colorIndex'] as int? ?? 0,
      subtasks: rawSubtasks is List
          ? rawSubtasks
              .whereType<Map<dynamic, dynamic>>()
              .map(SubTask.fromMap)
              .toList()
          : const <SubTask>[],
    );
  }
}
