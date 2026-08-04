/// Montos en pesos chilenos.
///
/// Se guardan como enteros, no como decimales. El peso no tiene centavos, y
/// usar `double` para dinero arrastra errores de redondeo que aparecen recien
/// cuando los totales no cuadran por uno.
class Money {
  const Money._();

  /// "$12.500" o "-$3.400". Con `sign` los positivos llevan "+".
  static String format(int amount, {bool sign = false}) {
    final prefix = amount < 0
        ? '-'
        : sign
            ? '+'
            : '';
    return '$prefix\$${_thousands(amount.abs())}';
  }

  /// Version corta para espacios apretados: 12,5k / 1,2M.
  static String compact(int amount) {
    final abs = amount.abs();
    final prefix = amount < 0 ? '-' : '';

    if (abs >= 1000000) {
      return '$prefix\$${(abs / 1000000).toStringAsFixed(1).replaceAll('.', ',')}M';
    }
    if (abs >= 10000) {
      return '$prefix\$${(abs / 1000).round()}k';
    }
    return format(amount);
  }

  /// Separador de miles con punto, como se escribe en Chile.
  static String _thousands(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      // El punto va cada tres digitos contando desde la derecha.
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }

    return buffer.toString();
  }

  /// Lee lo que el usuario escribio, ignorando puntos, espacios y el signo
  /// de pesos. Devuelve `null` si no queda nada aprovechable.
  static int? parse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9-]'), '');
    if (cleaned.isEmpty || cleaned == '-') return null;
    return int.tryParse(cleaned);
  }
}
