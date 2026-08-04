/// Si una categoria agrupa lo que entra o lo que sale.
enum CategoryKind {
  expense('Gasto'),
  income('Ingreso');

  const CategoryKind(this.label);

  final String label;

  static CategoryKind decode(Object? value) =>
      value == 'income' ? CategoryKind.income : CategoryKind.expense;

  String encode() => name;
}

/// Categoria de un movimiento.
///
/// El icono se guarda como texto, no como el objeto de icono: los `IconData`
/// no se pueden serializar y ademas los modelos no deben depender de la capa
/// visual. La interfaz traduce ese nombre a un icono concreto.
class FinanceCategory {
  const FinanceCategory({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorIndex,
    this.kind = CategoryKind.expense,
    this.isBuiltIn = false,
  });

  final String id;
  final String name;
  final String iconName;
  final int colorIndex;
  final CategoryKind kind;

  /// Las que vienen de fabrica no se pueden borrar, solo renombrar. Evita que
  /// alguien se quede sin ninguna categoria y no pueda registrar nada.
  final bool isBuiltIn;

  bool get isExpense => kind == CategoryKind.expense;

  FinanceCategory copyWith({
    String? name,
    String? iconName,
    int? colorIndex,
    CategoryKind? kind,
  }) {
    return FinanceCategory(
      id: id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorIndex: colorIndex ?? this.colorIndex,
      kind: kind ?? this.kind,
      isBuiltIn: isBuiltIn,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'name': name,
        'iconName': iconName,
        'colorIndex': colorIndex,
        'kind': kind.encode(),
        'isBuiltIn': isBuiltIn,
      };

  factory FinanceCategory.fromMap(Map<dynamic, dynamic> map) {
    return FinanceCategory(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Sin nombre',
      iconName: map['iconName'] as String? ?? 'label',
      colorIndex: map['colorIndex'] as int? ?? 0,
      kind: CategoryKind.decode(map['kind']),
      isBuiltIn: map['isBuiltIn'] as bool? ?? false,
    );
  }

  /// Categorias con las que arranca la aplicacion.
  ///
  /// Pensadas para Chile y para gastos de todos los dias, no para una
  /// contabilidad de empresa. Se pueden renombrar y se les pueden sumar otras.
  static List<FinanceCategory> defaults() => <FinanceCategory>[
        // --- Gastos ---
        _built('comida', 'Comida', 'restaurant', 0),
        _built('super', 'Supermercado', 'cart', 1),
        _built('transporte', 'Transporte', 'car', 2),
        _built('arriendo', 'Arriendo', 'home', 3),
        _built('cuentas', 'Cuentas y servicios', 'bolt', 4),
        _built('salud', 'Salud', 'health', 5),
        _built('educacion', 'Educacion', 'school', 6),
        _built('ropa', 'Ropa', 'shirt', 7),
        _built('entretencion', 'Entretencion', 'movie', 8),
        _built('deporte', 'Deporte', 'sports', 9),
        _built('mascotas', 'Mascotas', 'pets', 10),
        _built('otros', 'Otros', 'label', 11),

        // --- Ingresos ---
        _built('sueldo', 'Sueldo', 'wallet', 2, kind: CategoryKind.income),
        _built('extra', 'Trabajo extra', 'trending', 9, kind: CategoryKind.income),
        _built('regalo', 'Regalo', 'gift', 7, kind: CategoryKind.income),
        _built('otros_in', 'Otros ingresos', 'label', 11,
            kind: CategoryKind.income),
      ];

  static FinanceCategory _built(
    String id,
    String name,
    String icon,
    int color, {
    CategoryKind kind = CategoryKind.expense,
  }) {
    return FinanceCategory(
      id: id,
      name: name,
      iconName: icon,
      colorIndex: color,
      kind: kind,
      isBuiltIn: true,
    );
  }
}
