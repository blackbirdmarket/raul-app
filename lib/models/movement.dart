import '../utils/calendar.dart';

/// Un gasto o un ingreso.
///
/// El signo vive en el monto y no en un campo aparte: un gasto es negativo y
/// un ingreso positivo. Asi sumar una lista de movimientos da directamente el
/// balance, sin tener que recordar invertir nada por el camino.
class Movement {
  const Movement({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryId,
    this.accountId,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String title;

  /// Negativo para gastos, positivo para ingresos. En pesos, sin decimales.
  final int amount;

  final DateTime date;
  final String categoryId;

  /// De que cuenta salio o a cual entro. Puede faltar: registrar el gasto
  /// importa mas que recordar con que tarjeta se pago.
  final String? accountId;

  final String? notes;
  final DateTime? createdAt;

  bool get isExpense => amount < 0;
  bool get isIncome => amount > 0;

  /// Monto sin signo, para mostrarlo cuando el contexto ya dice si entra o sale.
  int get magnitude => amount.abs();

  /// Dia al que pertenece, sin hora. Clave para agrupar.
  DateTime get day => Calendar.dayOf(date);

  /// Primer dia del mes, para agrupar y filtrar por mes.
  DateTime get month => DateTime(date.year, date.month);

  Movement copyWith({
    String? title,
    int? amount,
    DateTime? date,
    String? categoryId,
    String? accountId,
    String? notes,
    bool clearAccount = false,
  }) {
    return Movement(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      accountId: clearAccount ? null : (accountId ?? this.accountId),
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'title': title,
        'amount': amount,
        'date': date.millisecondsSinceEpoch,
        'categoryId': categoryId,
        'accountId': accountId,
        'notes': notes,
        'createdAt': createdAt?.millisecondsSinceEpoch,
      };

  factory Movement.fromMap(Map<dynamic, dynamic> map) {
    final created = map['createdAt'];
    return Movement(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      amount: map['amount'] as int? ?? 0,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      categoryId: map['categoryId'] as String? ?? 'otros',
      accountId: map['accountId'] as String?,
      notes: map['notes'] as String?,
      createdAt:
          created is int ? DateTime.fromMillisecondsSinceEpoch(created) : null,
    );
  }
}
