import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/app_config.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'database/hive_setup.dart';
import 'services/logger_service.dart';
import 'services/notification_service.dart';
import 'services/preferences_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // El orden importa: la configuracion debe existir antes que cualquier cosa
  // que pueda escribir un log.
  AppConfig.initialize(
    environment: kReleaseMode ? Environment.production : Environment.development,
  );

  _setUpErrorHandling();

  await HiveSetup.initialize();
  final prefs = await SharedPreferences.getInstance();

  // Prepara los canales de aviso antes de que se pinte nada. En la web es una
  // operacion vacia, asi que no estorba al desarrollo en el navegador.
  await NotificationService.instance.initialize();

  runApp(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const App(),
    ),
  );
}

/// Captura los errores que Flutter no maneja, para que queden registrados en
/// vez de perderse en la consola.
void _setUpErrorHandling() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    LoggerService.error(
      details.exceptionAsString(),
      tag: 'FLUTTER',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    LoggerService.error(
      'Error no capturado.',
      tag: 'PLATFORM',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      // En el navegador la app se enmarca como un telefono. Es solo para
      // revisar diseno: estirada a todo el ancho de un monitor no se pareceria
      // en nada a como se ve de verdad.
      builder: kIsWeb ? _phoneFrame : null,
    );
  }
}

Widget _phoneFrame(BuildContext context, Widget? child) {
  return ColoredBox(
    color: const Color(0xFF15151A),
    child: Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // En una pantalla chica ocupa lo que haya; en un monitor se queda
          // en tamano telefono.
          final width = constraints.maxWidth.clamp(0.0, 412.0);
          final height = constraints.maxHeight.clamp(0.0, 880.0);
          final rounded = width >= 412 && height >= 880;

          return Container(
            width: width,
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(rounded ? AppConstants.radiusXl : 0),
              border: rounded
                  ? Border.all(color: const Color(0xFF2A2A32), width: 2)
                  : null,
            ),
            child: child,
          );
        },
      ),
    ),
  );
}
