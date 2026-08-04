import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Instancia de SharedPreferences.
///
/// Se sobreescribe en `main.dart` con la instancia ya inicializada. Se declara
/// asi, y no como FutureProvider, para que el resto de la aplicacion pueda
/// leer preferencias de forma sincronica sin manejar estados de carga.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider debe sobreescribirse en el ProviderScope raiz.',
  );
});

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService(ref.watch(sharedPreferencesProvider));
});

/// Acceso tipado a la configuracion de la aplicacion.
///
/// Las claves son privadas a proposito: nadie fuera de esta clase deberia
/// escribir una clave a mano y arriesgarse a un error de tipeo silencioso.
class PreferencesService {
  const PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  static const String _keyThemeMode = 'theme_mode';
  static const String _keyOnboardingDone = 'onboarding_done';
  static const String _keyLanguage = 'language_code';

  /// Modo de tema guardado: 'light', 'dark' o 'system'.
  ///
  /// Arranca en oscuro y no en 'system' porque la interfaz esta disenada
  /// sobre fondo oscuro: es donde se ve como corresponde. Se puede cambiar
  /// desde Ajustes.
  String get themeMode => _prefs.getString(_keyThemeMode) ?? 'dark';

  Future<void> setThemeMode(String value) => _prefs.setString(_keyThemeMode, value);

  bool get onboardingDone => _prefs.getBool(_keyOnboardingDone) ?? false;

  Future<void> setOnboardingDone(bool value) =>
      _prefs.setBool(_keyOnboardingDone, value);

  String get languageCode => _prefs.getString(_keyLanguage) ?? 'es';

  Future<void> setLanguageCode(String value) =>
      _prefs.setString(_keyLanguage, value);

  /// Borra toda la configuracion. Usado al cerrar sesion o restablecer.
  Future<void> clear() => _prefs.clear();
}
