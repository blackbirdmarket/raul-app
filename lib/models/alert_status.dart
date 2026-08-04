/// Que paso la ultima vez que se programaron los avisos.
///
/// Existe porque el servicio de avisos falla en silencio por naturaleza: si
/// Android rechaza una alarma, la aplicacion sigue funcionando igual y uno solo
/// se entera cuando la alarma no suena, horas despues y sin saber por que.
/// Devolver el resultado permite mostrarlo en Ajustes y convertir un fallo
/// invisible en una linea de texto que se puede leer.
class AlertStatus {
  const AlertStatus({
    this.scheduled = 0,
    this.next,
    this.nextTitle,
    this.exactAllowed = true,
    this.error,
  });

  /// Cuantos avisos quedaron programados en el sistema.
  final int scheduled;

  /// Cuando suena el primero que viene.
  final DateTime? next;
  final String? nextTitle;

  /// Si Android permite alarmas a la hora exacta. Cuando esta en `false` los
  /// avisos siguen programandose, pero el sistema decide cuando mostrarlos y
  /// puede retrasarlos bastante.
  final bool exactAllowed;

  /// Texto del fallo, si lo hubo.
  final String? error;

  bool get hasError => error != null;
  bool get isEmpty => scheduled == 0;
}
