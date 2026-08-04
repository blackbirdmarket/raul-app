import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/result/result.dart';
import '../../../../features/finance/data/finance_repository.dart';
import '../../../../features/planning/data/agenda_repository.dart';
import '../../../../services/logger_service.dart';
import '../../../../services/preferences_service.dart';
import '../../../finance/presentation/providers/finance_providers.dart';
import '../../../planning/presentation/providers/agenda_providers.dart';

final settingsControllerProvider =
    Provider<SettingsController>(SettingsController.new);

/// Acciones de la pantalla de ajustes que tocan datos.
///
/// Viven fuera del widget para que la pantalla se ocupe solo de mostrar, y
/// para poder probarlas sin construir interfaz.
class SettingsController {
  const SettingsController(this._ref);

  final Ref _ref;

  /// Borra la agenda completa y la configuracion.
  ///
  /// Devuelve un `Result` porque es destructivo: la pantalla tiene que poder
  /// avisar si algo no se borro en vez de asumir que salio bien.
  Future<Result<void>> resetAllData() async {
    try {
      await _ref.read(agendaRepositoryProvider).clear();
      await _ref.read(financeRepositoryProvider).clearAll();
      await _ref.read(preferencesServiceProvider).clear();

      // Fuerza a que todo lo que vive en memoria se reconstruya desde cero.
      _ref.invalidate(agendaProvider);
      _ref.invalidate(accountsProvider);
      _ref.invalidate(categoriesProvider);
      _ref.invalidate(movementsProvider);

      LoggerService.info('Datos locales restablecidos.', tag: 'SETTINGS');
      return const Result<void>.success(null);
    } catch (error, stackTrace) {
      LoggerService.error(
        'Fallo al restablecer los datos.',
        tag: 'SETTINGS',
        error: error,
        stackTrace: stackTrace,
      );
      return const Result<void>.failure(
        StorageFailure('No se pudieron borrar todos los datos.'),
      );
    }
  }
}
