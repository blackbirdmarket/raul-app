import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/account.dart';
import '../../../../models/agenda_entry.dart' show newEntryId;
import '../../../../models/finance_category.dart';
import '../../../../models/movement.dart';
import '../../data/finance_repository.dart';

/// Las lecturas del area de finanzas.
///
/// Tres formas de mirar el mismo mes: lo que paso (movimientos), con que se
/// pago (cuentas) y en que se fue (analisis).
enum FinanceView {
  movements('Movimientos'),
  accounts('Cuentas'),
  analysis('Analisis');

  const FinanceView(this.label);

  final String label;
}

final financeViewProvider =
    NotifierProvider<FinanceViewController, FinanceView>(
  FinanceViewController.new,
);

class FinanceViewController extends Notifier<FinanceView> {
  @override
  FinanceView build() => FinanceView.movements;

  void select(FinanceView view) => state = view;
}

/// Mes que se esta mirando, normalizado al dia 1.
final selectedMonthProvider =
    NotifierProvider<SelectedMonthController, DateTime>(
  SelectedMonthController.new,
);

class SelectedMonthController extends Notifier<DateTime> {
  @override
  DateTime build() => currentMonth();

  static DateTime currentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  /// Avanza o retrocede meses. `DateTime` normaliza el desborde solo: mes 13
  /// pasa a ser enero del ano siguiente.
  void shift(int months) {
    state = DateTime(state.year, state.month + months);
  }

  void goToCurrent() => state = currentMonth();

  bool get isCurrentMonth => state == currentMonth();
}

// --- Cuentas ---

final accountsProvider =
    NotifierProvider<AccountsController, List<Account>>(AccountsController.new);

class AccountsController extends Notifier<List<Account>> {
  @override
  List<Account> build() => ref.watch(financeRepositoryProvider).loadAccounts();

  FinanceRepository get _repository => ref.read(financeRepositoryProvider);

  Future<void> upsert(Account account) async {
    state = <Account>[
      ...state.where((a) => a.id != account.id),
      account,
    ]..sort((a, b) => b.balance.compareTo(a.balance));

    await _repository.saveAccount(account);
  }

  Future<void> remove(String id) async {
    state = state.where((a) => a.id != id).toList();
    await _repository.removeAccount(id);
  }

  /// Ajusta el saldo de una cuenta por el efecto de un movimiento.
  ///
  /// Se hace aqui y no en el editor para que el saldo y el movimiento nunca
  /// se puedan desincronizar por olvido en algun camino nuevo.
  Future<void> applyDelta(String accountId, int delta) async {
    if (delta == 0) return;

    for (final account in state) {
      if (account.id != accountId) continue;
      await upsert(account.copyWith(balance: account.balance + delta));
      return;
    }
  }
}

/// Suma de las cuentas marcadas para el total.
final totalBalanceProvider = Provider<int>((ref) {
  return ref
      .watch(accountsProvider)
      .where((a) => a.includeInTotal)
      .fold<int>(0, (sum, a) => sum + a.balance);
});

// --- Categorias ---

final categoriesProvider =
    NotifierProvider<CategoriesController, List<FinanceCategory>>(
  CategoriesController.new,
);

class CategoriesController extends Notifier<List<FinanceCategory>> {
  @override
  List<FinanceCategory> build() =>
      ref.watch(financeRepositoryProvider).loadCategories();

  FinanceRepository get _repository => ref.read(financeRepositoryProvider);

  Future<void> upsert(FinanceCategory category) async {
    state = <FinanceCategory>[
      ...state.where((c) => c.id != category.id),
      category,
    ]..sort((a, b) => a.name.compareTo(b.name));

    await _repository.saveCategory(category);
  }

  Future<void> remove(String id) async {
    // Las de fabrica no se borran: siempre tiene que quedar donde clasificar.
    final target = byId(id);
    if (target == null || target.isBuiltIn) return;

    state = state.where((c) => c.id != id).toList();
    await _repository.removeCategory(id);
  }

  FinanceCategory? byId(String id) {
    for (final category in state) {
      if (category.id == id) return category;
    }
    return null;
  }
}

/// Busca una categoria sin obligar a cada widget a recorrer la lista.
final categoryByIdProvider =
    Provider.family<FinanceCategory?, String>((ref, id) {
  for (final category in ref.watch(categoriesProvider)) {
    if (category.id == id) return category;
  }
  return null;
});

final categoriesOfKindProvider =
    Provider.family<List<FinanceCategory>, CategoryKind>((ref, kind) {
  return ref.watch(categoriesProvider).where((c) => c.kind == kind).toList();
});

// --- Movimientos ---

final movementsProvider =
    NotifierProvider<MovementsController, List<Movement>>(
  MovementsController.new,
);

class MovementsController extends Notifier<List<Movement>> {
  @override
  List<Movement> build() =>
      ref.watch(financeRepositoryProvider).loadMovements();

  FinanceRepository get _repository => ref.read(financeRepositoryProvider);

  Movement? _find(String id) {
    for (final movement in state) {
      if (movement.id == id) return movement;
    }
    return null;
  }

  /// Guarda un movimiento y corrige el saldo de la cuenta afectada.
  ///
  /// Al editar se revierte primero el efecto anterior y despues se aplica el
  /// nuevo. Sin eso, cambiar un gasto de 5000 a 3000 restaria de nuevo.
  Future<void> upsert(Movement movement) async {
    final previous = _find(movement.id);
    final accounts = ref.read(accountsProvider.notifier);

    if (previous != null && previous.accountId != null) {
      await accounts.applyDelta(previous.accountId!, -previous.amount);
    }
    if (movement.accountId != null) {
      await accounts.applyDelta(movement.accountId!, movement.amount);
    }

    state = <Movement>[
      ...state.where((m) => m.id != movement.id),
      movement,
    ]..sort((a, b) => b.date.compareTo(a.date));

    await _repository.saveMovement(movement);
  }

  Future<void> remove(String id) async {
    final movement = _find(id);
    if (movement == null) return;

    if (movement.accountId != null) {
      await ref
          .read(accountsProvider.notifier)
          .applyDelta(movement.accountId!, -movement.amount);
    }

    state = state.where((m) => m.id != id).toList();
    await _repository.removeMovement(id);
  }

  String newId() => newEntryId();
}

/// Movimientos de un mes, del mas nuevo al mas viejo.
final movementsForMonthProvider =
    Provider.family<List<Movement>, DateTime>((ref, month) {
  final target = DateTime(month.year, month.month);
  return ref.watch(movementsProvider).where((m) => m.month == target).toList();
});

/// Resumen de un mes: cuanto entro, cuanto salio y como queda el balance.
class MonthSummary {
  const MonthSummary({
    required this.income,
    required this.expense,
    required this.count,
  });

  final int income;
  final int expense;
  final int count;

  int get balance => income - expense;
  bool get isEmpty => count == 0;
}

final monthSummaryProvider =
    Provider.family<MonthSummary, DateTime>((ref, month) {
  final movements = ref.watch(movementsForMonthProvider(month));

  var income = 0;
  var expense = 0;

  for (final movement in movements) {
    if (movement.isIncome) {
      income += movement.amount;
    } else {
      expense += movement.magnitude;
    }
  }

  return MonthSummary(
    income: income,
    expense: expense,
    count: movements.length,
  );
});

/// Cuanto se gasto en cada categoria durante un mes, de mayor a menor.
class CategoryTotal {
  const CategoryTotal({
    required this.category,
    required this.amount,
    required this.share,
  });

  final FinanceCategory category;
  final int amount;

  /// Proporcion sobre el total del mes, entre 0 y 1.
  final double share;

  int get percent => (share * 100).round();
}

final categoryTotalsProvider =
    Provider.family<List<CategoryTotal>, ({DateTime month, CategoryKind kind})>(
        (ref, args) {
  final movements = ref.watch(movementsForMonthProvider(args.month));
  final categories = ref.watch(categoriesProvider);

  final sums = <String, int>{};
  var total = 0;

  for (final movement in movements) {
    final isExpense = movement.isExpense;
    if (args.kind == CategoryKind.expense && !isExpense) continue;
    if (args.kind == CategoryKind.income && isExpense) continue;

    sums[movement.categoryId] =
        (sums[movement.categoryId] ?? 0) + movement.magnitude;
    total += movement.magnitude;
  }

  final totals = <CategoryTotal>[];

  for (final entry in sums.entries) {
    final category = categories.where((c) => c.id == entry.key).firstOrNull();
    totals.add(
      CategoryTotal(
        category: category ??
            FinanceCategory(
              id: entry.key,
              name: 'Sin categoria',
              iconName: 'label',
              colorIndex: 11,
              kind: args.kind,
            ),
        amount: entry.value,
        share: total == 0 ? 0 : entry.value / total,
      ),
    );
  }

  totals.sort((a, b) => b.amount.compareTo(a.amount));
  return totals;
});

/// Si el analisis mira lo que sale o lo que entra.
///
/// Vive fuera de la pantalla para que volver a Analisis despues de mirar un
/// movimiento no pierda lo que se estaba revisando.
final analysisKindProvider =
    NotifierProvider<AnalysisKindController, CategoryKind>(
  AnalysisKindController.new,
);

class AnalysisKindController extends Notifier<CategoryKind> {
  @override
  CategoryKind build() => CategoryKind.expense;

  void select(CategoryKind kind) => state = kind;
}

/// Movimientos de una categoria dentro de un mes, del mas nuevo al mas viejo.
///
/// Es lo que se abre al tocar una porcion de la dona: el grafico dice cuanto,
/// y esto dice en que exactamente.
final movementsForCategoryProvider = Provider.family<List<Movement>,
    ({DateTime month, String categoryId})>((ref, args) {
  return ref
      .watch(movementsForMonthProvider(args.month))
      .where((m) => m.categoryId == args.categoryId)
      .toList();
});

/// `firstOrNull` no viene en Dart sin `package:collection`, y no vale la pena
/// sumar una dependencia por una linea.
extension _FirstOrNull<T> on Iterable<T> {
  T? firstOrNull() {
    for (final item in this) {
      return item;
    }
    return null;
  }
}
