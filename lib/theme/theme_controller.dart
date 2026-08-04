import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/preferences_service.dart';

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);

/// Controla el modo claro/oscuro y lo persiste.
///
/// El valor inicial se lee de forma sincronica desde SharedPreferences, de modo
/// que la aplicacion arranca directamente en el tema correcto y el usuario no
/// ve un parpadeo de blanco a negro.
class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefs = ref.watch(preferencesServiceProvider);
    return _decode(prefs.themeMode);
  }

  /// Cambia el modo y lo guarda.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ref.read(preferencesServiceProvider).setThemeMode(_encode(mode));
  }

  /// Alterna entre claro y oscuro. Si esta en modo sistema, decide segun el
  /// brillo que el sistema esta mostrando en ese momento.
  Future<void> toggle(BuildContext context) async {
    final next = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark
            ? ThemeMode.light
            : ThemeMode.dark,
    };
    await setThemeMode(next);
  }

  static ThemeMode _decode(String value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  static String _encode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
}
