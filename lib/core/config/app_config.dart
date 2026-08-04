/// Entorno de ejecucion de la aplicacion.
enum Environment { development, staging, production }

/// Configuracion que cambia segun el entorno.
///
/// Se inicializa una sola vez al arrancar, en `main.dart`. El resto de la
/// aplicacion solo lee. Esto evita que existan banderas de configuracion
/// desperdigadas por el codigo.
class AppConfig {
  const AppConfig._({
    required this.environment,
    required this.enableLogging,
  });

  final Environment environment;
  final bool enableLogging;

  static AppConfig? _instance;

  /// Configuracion activa. Lanza si se lee antes de inicializar, lo cual
  /// es intencional: un error silencioso aqui seria mucho peor.
  static AppConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError(
        'AppConfig no fue inicializado. Llama a AppConfig.initialize() '
        'antes de usar la aplicacion.',
      );
    }
    return config;
  }

  static void initialize({Environment environment = Environment.development}) {
    _instance = AppConfig._(
      environment: environment,
      enableLogging: environment != Environment.production,
    );
  }

  bool get isProduction => environment == Environment.production;
  bool get isDevelopment => environment == Environment.development;
}
