import '../utils/calendar.dart';

/// Un escrito del cuaderno.
///
/// No tiene tipo ni categoria a proposito. Un decreto, una manifestacion, una
/// gratitud y una reflexion son todos texto: obligar a elegir de que tipo es
/// antes de escribir mete una decision entre la persona y la hoja, y esa
/// friccion es justo la que hace que uno no escriba.
///
/// Lo unico que se distingue es lo que se fija, porque hay escritos que se
/// releen todos los dias y otros que se escriben una vez y se dejan ir.
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.text,
    required this.createdAt,
    this.title,
    this.updatedAt,
    this.pinned = false,
  });

  final String id;

  /// El escrito completo. Es lo unico obligatorio.
  final String text;

  final DateTime createdAt;

  /// Titulo opcional. Sin el, la lista muestra la primera linea del texto.
  final String? title;

  final DateTime? updatedAt;

  /// Fijado arriba. Para lo que se relee, no para lo que se archiva.
  final bool pinned;

  DateTime get day => Calendar.dayOf(createdAt);

  /// Que mostrar como encabezado en la lista.
  ///
  /// Si no hay titulo se usa la primera linea con contenido: casi siempre es
  /// justamente lo que uno pondria de titulo si se lo preguntaran.
  String get heading {
    final own = title?.trim();
    if (own != null && own.isNotEmpty) return own;

    for (final line in text.split('\n')) {
      final clean = line.trim();
      if (clean.isNotEmpty) {
        return clean.length <= 60 ? clean : '${clean.substring(0, 57)}...';
      }
    }
    return 'Sin titulo';
  }

  /// Las lineas siguientes, para la vista previa de la lista.
  String get preview {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty);
    final own = title?.trim();
    // Si el encabezado sale del texto, no se repite en la vista previa.
    final rest = (own != null && own.isNotEmpty) ? lines : lines.skip(1);
    return rest.join(' ');
  }

  int get wordCount =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  JournalEntry copyWith({
    String? text,
    String? title,
    bool? pinned,
    DateTime? updatedAt,
    bool clearTitle = false,
  }) {
    return JournalEntry(
      id: id,
      text: text ?? this.text,
      createdAt: createdAt,
      title: clearTitle ? null : (title ?? this.title),
      updatedAt: updatedAt ?? this.updatedAt,
      pinned: pinned ?? this.pinned,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'text': text,
        'title': title,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt?.millisecondsSinceEpoch,
        'pinned': pinned,
      };

  factory JournalEntry.fromMap(Map<dynamic, dynamic> map) {
    final updated = map['updatedAt'];
    return JournalEntry(
      id: map['id'] as String,
      text: map['text'] as String? ?? '',
      title: map['title'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      updatedAt:
          updated is int ? DateTime.fromMillisecondsSinceEpoch(updated) : null,
      pinned: map['pinned'] as bool? ?? false,
    );
  }
}
