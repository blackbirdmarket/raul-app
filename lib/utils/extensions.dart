import 'package:flutter/material.dart';

/// Accesos directos al tema, para no repetir `Theme.of(context)` en cada
/// widget.
extension ThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get texts => Theme.of(this).textTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

/// Mensajes al usuario, con estilo consistente.
extension MessageContext on BuildContext {
  void showMessage(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void showError(String message) {
    final scheme = Theme.of(this).colorScheme;
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(color: scheme.onErrorContainer),
          ),
          backgroundColor: scheme.errorContainer,
        ),
      );
  }
}

extension StringUtils on String {
  /// Primera letra en mayuscula, resto intacto.
  String get capitalized =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  bool get isBlank => trim().isEmpty;
  bool get isNotBlank => trim().isNotEmpty;

  /// Corta el texto agregando puntos suspensivos si excede el largo.
  String truncate(int max) =>
      length <= max ? this : '${substring(0, max).trimRight()}...';
}

extension DateUtilsX on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Formato dd/mm/aaaa, el que se usa en Chile.
  String get shortDate =>
      '${day.toString().padLeft(2, '0')}/'
      '${month.toString().padLeft(2, '0')}/'
      '$year';

  String get shortTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

extension IterableUtils<T> on Iterable<T> {
  /// Primer elemento que cumpla la condicion, o `null`. Evita el try/catch
  /// que exige `firstWhere` sin `orElse`.
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}
