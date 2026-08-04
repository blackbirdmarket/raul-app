import 'package:hive_flutter/hive_flutter.dart';

import '../services/logger_service.dart';

/// Nombres de las cajas de Hive.
///
/// Centralizados para que abrir una caja con un nombre mal escrito sea
/// imposible: una caja inexistente se crea vacia en silencio, y ese es
/// exactamente el tipo de error que cuesta horas encontrar.
class HiveBoxes {
  const HiveBoxes._();

  /// Datos generales de la aplicacion.
  static const String app = 'app_box';

  /// Tareas y bloques de la agenda, uno por clave.
  static const String agenda = 'agenda_box';

  // --- Finanzas ---
  static const String accounts = 'accounts_box';
  static const String categories = 'categories_box';
  static const String movements = 'movements_box';

  // --- Diario ---
  /// Un registro de animo por dia.
  static const String moods = 'moods_box';

  /// Los escritos del cuaderno.
  static const String journal = 'journal_box';
}

/// Inicializacion de la base de datos local.
///
/// Se guardan mapas planos en vez de objetos con TypeAdapter generado. Es una
/// decision deliberada: evita depender de generacion de codigo y hace que
/// agregar un campo a un modelo no rompa los datos ya guardados en el
/// telefono.
class HiveSetup {
  const HiveSetup._();

  static Future<void> initialize() async {
    await Hive.initFlutter();

    await _openBox(HiveBoxes.app);
    await _openBox(HiveBoxes.agenda);
    await _openBox(HiveBoxes.accounts);
    await _openBox(HiveBoxes.categories);
    await _openBox(HiveBoxes.movements);
    await _openBox(HiveBoxes.moods);
    await _openBox(HiveBoxes.journal);

    LoggerService.info('Base de datos local lista.', tag: 'HIVE');
  }

  static Future<void> _openBox(String name) async {
    if (Hive.isBoxOpen(name)) return;
    await Hive.openBox<dynamic>(name);
  }

  static Future<void> dispose() => Hive.close();
}
