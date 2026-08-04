/// Como avisa un elemento de la agenda cuando llega su hora.
///
/// Se decide por elemento y no globalmente: tomar una pastilla merece una
/// alarma que insista, revisar el correo no.
enum AlertMode {
  /// Sin aviso. El elemento existe en la agenda pero no interrumpe.
  none,

  /// Notificacion discreta en la barra superior.
  notification,

  /// Alarma sonora que sigue hasta que se apaga.
  alarm;

  String get label => switch (this) {
        AlertMode.none => 'Sin aviso',
        AlertMode.notification => 'Aviso normal',
        AlertMode.alarm => 'Alarma',
      };

  String get description => switch (this) {
        AlertMode.none => 'No interrumpe.',
        AlertMode.notification => 'Aparece arriba, sin insistir.',
        AlertMode.alarm => 'Suena hasta que la apagas.',
      };

  bool get isSilent => this == AlertMode.none;

  static AlertMode decode(Object? value) => switch (value) {
        'notification' => AlertMode.notification,
        'alarm' => AlertMode.alarm,
        _ => AlertMode.none,
      };

  String encode() => name;
}
