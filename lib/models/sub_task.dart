import 'alert_mode.dart';

/// Un paso dentro de un bloque de tiempo.
///
/// Tiene su propio aviso porque un bloque largo suele tener un momento
/// concreto que importa: "Ordenar casa" puede durar toda la manana, pero
/// "sacar la basura" tiene que pasar antes de que pase el camion.
class SubTask {
  const SubTask({
    required this.id,
    required this.title,
    this.done = false,
    this.alert = AlertMode.none,
    this.remindAt,
  });

  final String id;
  final String title;
  final bool done;
  final AlertMode alert;

  /// Momento exacto del aviso. Si es null no hay nada que programar,
  /// aunque `alert` diga otra cosa.
  final DateTime? remindAt;

  bool get hasReminder => alert != AlertMode.none && remindAt != null;

  SubTask copyWith({
    String? id,
    String? title,
    bool? done,
    AlertMode? alert,
    DateTime? remindAt,
    bool clearRemindAt = false,
  }) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      done: done ?? this.done,
      alert: alert ?? this.alert,
      remindAt: clearRemindAt ? null : (remindAt ?? this.remindAt),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'title': title,
        'done': done,
        'alert': alert.encode(),
        'remindAt': remindAt?.millisecondsSinceEpoch,
      };

  factory SubTask.fromMap(Map<dynamic, dynamic> map) {
    final reminder = map['remindAt'];
    return SubTask(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      done: map['done'] as bool? ?? false,
      alert: AlertMode.decode(map['alert']),
      remindAt: reminder is int
          ? DateTime.fromMillisecondsSinceEpoch(reminder)
          : null,
    );
  }
}
