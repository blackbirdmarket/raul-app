import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result/result.dart';
import '../../../database/hive_setup.dart';
import '../../../models/account.dart';
import '../../../models/finance_category.dart';
import '../../../models/movement.dart';
import '../../../services/logger_service.dart';
import '../../../services/storage_service.dart';

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepository(ref.watch(storageServiceProvider));
});

/// Acceso a cuentas, categorias y movimientos.
///
/// Cada elemento se guarda bajo su propio id, igual que en la agenda: editar
/// uno reescribe solo esa clave, y un dato corrupto no se lleva por delante
/// el resto.
class FinanceRepository {
  const FinanceRepository(this._storage);

  final StorageService _storage;

  // --- Cuentas ---

  List<Account> loadAccounts() {
    final accounts = _read<Account>(
      HiveBoxes.accounts,
      Account.fromMap,
      'cuenta',
    );
    accounts.sort((a, b) => b.balance.compareTo(a.balance));
    return accounts;
  }

  Future<Result<void>> saveAccount(Account account) =>
      _storage.write(account.id, account.toMap(), box: HiveBoxes.accounts);

  Future<void> removeAccount(String id) =>
      _storage.delete(id, box: HiveBoxes.accounts);

  // --- Categorias ---

  /// Carga las categorias, sembrando las de fabrica la primera vez.
  ///
  /// Sin esto la aplicacion abriria sin ninguna categoria y no se podria
  /// registrar nada hasta crear una a mano, que es una pesima bienvenida.
  List<FinanceCategory> loadCategories() {
    final stored = _read<FinanceCategory>(
      HiveBoxes.categories,
      FinanceCategory.fromMap,
      'categoria',
    );

    if (stored.isEmpty) {
      final defaults = FinanceCategory.defaults();
      Future<void>.microtask(() async {
        for (final category in defaults) {
          await saveCategory(category);
        }
      });
      return defaults;
    }

    return stored;
  }

  Future<Result<void>> saveCategory(FinanceCategory category) =>
      _storage.write(category.id, category.toMap(), box: HiveBoxes.categories);

  Future<void> removeCategory(String id) =>
      _storage.delete(id, box: HiveBoxes.categories);

  // --- Movimientos ---

  List<Movement> loadMovements() {
    final movements = _read<Movement>(
      HiveBoxes.movements,
      Movement.fromMap,
      'movimiento',
    );
    // Del mas nuevo al mas viejo: es el orden en que uno los busca.
    movements.sort((a, b) => b.date.compareTo(a.date));
    return movements;
  }

  Future<Result<void>> saveMovement(Movement movement) =>
      _storage.write(movement.id, movement.toMap(), box: HiveBoxes.movements);

  Future<void> removeMovement(String id) =>
      _storage.delete(id, box: HiveBoxes.movements);

  Future<void> clearAll() async {
    await _storage.clear(box: HiveBoxes.accounts);
    await _storage.clear(box: HiveBoxes.categories);
    await _storage.clear(box: HiveBoxes.movements);
  }

  /// Lectura generica: descarta lo ilegible con un aviso en vez de romper la
  /// carga completa. Es preferible perder un dato a que la app no abra.
  List<T> _read<T>(
    String box,
    T Function(Map<dynamic, dynamic>) fromMap,
    String label,
  ) {
    final items = <T>[];

    for (final raw in _storage.values(box: box)) {
      if (raw is! Map) continue;
      try {
        items.add(fromMap(raw));
      } catch (error) {
        LoggerService.warning(
          'Se descarto una $label ilegible: $error',
          tag: 'FINANZAS',
        );
      }
    }

    return items;
  }
}
