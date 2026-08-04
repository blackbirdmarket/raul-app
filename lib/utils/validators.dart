/// Validaciones reutilizables para formularios.
///
/// Devuelven `null` cuando el valor es valido, que es lo que espera
/// `TextFormField.validator`.
class Validators {
  const Validators._();

  static final RegExp _email = RegExp(
    r'^[\w.+-]+@[\w-]+\.[\w.-]+$',
  );

  static String? required(String? value, {String field = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field es obligatorio.';
    }
    return null;
  }

  static String? email(String? value) {
    final missing = required(value, field: 'El correo');
    if (missing != null) return missing;
    if (!_email.hasMatch(value!.trim())) {
      return 'Ingresa un correo valido.';
    }
    return null;
  }

  static String? minLength(String? value, int min, {String field = 'Este campo'}) {
    final missing = required(value, field: field);
    if (missing != null) return missing;
    if (value!.trim().length < min) {
      return '$field debe tener al menos $min caracteres.';
    }
    return null;
  }

  static String? maxLength(String? value, int max, {String field = 'Este campo'}) {
    if (value != null && value.trim().length > max) {
      return '$field no puede superar $max caracteres.';
    }
    return null;
  }

  /// Combina varias validaciones y devuelve el primer error encontrado.
  static String? combine(List<String? Function()> validations) {
    for (final validate in validations) {
      final error = validate();
      if (error != null) return error;
    }
    return null;
  }
}
