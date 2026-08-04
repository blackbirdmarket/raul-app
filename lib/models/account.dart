/// Tipo de cuenta donde vive el dinero.
enum AccountKind {
  bank('Banco', 'bank'),
  cash('Efectivo', 'cash'),
  card('Tarjeta', 'card'),
  savings('Ahorro', 'savings');

  const AccountKind(this.label, this.iconName);

  final String label;
  final String iconName;

  static AccountKind decode(Object? value) => switch (value) {
        'cash' => AccountKind.cash,
        'card' => AccountKind.card,
        'savings' => AccountKind.savings,
        _ => AccountKind.bank,
      };

  String encode() => name;
}

/// Una cuenta con su saldo.
///
/// El saldo se guarda directo y no se calcula sumando movimientos. Es una
/// decision consciente: no vamos a registrar cada peso que se movio desde el
/// principio de los tiempos, asi que el saldo es lo que el usuario dice que
/// tiene, y los movimientos lo van corrigiendo desde ahi.
class Account {
  const Account({
    required this.id,
    required this.name,
    required this.balance,
    this.kind = AccountKind.bank,
    this.colorIndex = 0,
    this.includeInTotal = true,
    this.createdAt,
  });

  final String id;
  final String name;

  /// En pesos, sin decimales. Puede ser negativo en una tarjeta de credito.
  final int balance;

  final AccountKind kind;
  final int colorIndex;

  /// Permite tener una cuenta a la vista sin que ensucie el total, por
  /// ejemplo una compartida o una en otra moneda.
  final bool includeInTotal;

  final DateTime? createdAt;

  Account copyWith({
    String? name,
    int? balance,
    AccountKind? kind,
    int? colorIndex,
    bool? includeInTotal,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      kind: kind ?? this.kind,
      colorIndex: colorIndex ?? this.colorIndex,
      includeInTotal: includeInTotal ?? this.includeInTotal,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'name': name,
        'balance': balance,
        'kind': kind.encode(),
        'colorIndex': colorIndex,
        'includeInTotal': includeInTotal,
        'createdAt': createdAt?.millisecondsSinceEpoch,
      };

  factory Account.fromMap(Map<dynamic, dynamic> map) {
    final created = map['createdAt'];
    return Account(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Cuenta',
      balance: map['balance'] as int? ?? 0,
      kind: AccountKind.decode(map['kind']),
      colorIndex: map['colorIndex'] as int? ?? 0,
      includeInTotal: map['includeInTotal'] as bool? ?? true,
      createdAt:
          created is int ? DateTime.fromMillisecondsSinceEpoch(created) : null,
    );
  }
}
