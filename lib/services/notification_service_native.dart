import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/agenda_entry.dart';
import '../models/alert_mode.dart';
import '../models/alert_status.dart';
import 'logger_service.dart';

/// Programa los avisos y las alarmas del sistema.
///
/// Este archivo solo se compila en el telefono. En la web entra en su lugar
/// `notification_service_stub.dart`, que no hace nada. Por eso aqui no hay
/// ninguna comprobacion de plataforma.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;

  /// Resultado de la ultima programacion, para poder mostrarlo en Ajustes sin
  /// tener que volver a programar todo solo para saber como quedo.
  AlertStatus _last = const AlertStatus();

  /// Zona horaria fija.
  ///
  /// Se deja escrita en vez de detectarla para no sumar otra dependencia: la
  /// aplicacion es de una persona que vive en Chile. Si alguna vez importa
  /// viajar, aqui es donde se cambia.
  static const String _timeZone = 'America/Santiago';

  static const String _channelNotice = 'ruli_avisos';
  static const String _channelAlarm = 'ruli_alarmas';

  /// Cuantos avisos futuros se programan como maximo.
  ///
  /// Android limita las alarmas pendientes por aplicacion. Con noventa dias de
  /// repeticiones por delante conviene cortar: lo que esta a tres meses vista
  /// se reprograma solo la proxima vez que se abra la app.
  static const int _maxScheduled = 60;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<void> initialize() async {
    if (_ready) return;

    try {
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(_timeZone));

      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );

      // Los canales se crean una vez y el usuario puede ajustarlos despues
      // desde los ajustes de Android, que es donde espera encontrarlos.
      await _android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelNotice,
          'Avisos',
          description: 'Recordatorios discretos de tareas y bloques.',
          importance: Importance.high,
        ),
      );
      await _android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelAlarm,
          'Alarmas',
          description: 'Avisos que suenan hasta que los apagas.',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

      _ready = true;
      LoggerService.info('Servicio de avisos listo.', tag: 'AVISOS');
    } catch (error, stackTrace) {
      _last = AlertStatus(error: 'No se pudo iniciar: $error');
      LoggerService.error(
        'No se pudo iniciar el servicio de avisos.',
        tag: 'AVISOS',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Pide los permisos que Android exige desde la version 13.
  Future<bool> requestPermissions() async {
    await initialize();

    final android = _android;
    if (android == null) return false;

    final notifications = await android.requestNotificationsPermission();
    // El permiso de hora exacta es aparte y en algunos telefonos abre una
    // pantalla del sistema en vez de un dialogo.
    await android.requestExactAlarmsPermission();

    return notifications ?? false;
  }

  Future<bool> hasPermission() async {
    await initialize();
    return await _android?.areNotificationsEnabled() ?? false;
  }

  /// Si Android deja poner alarmas a la hora exacta.
  ///
  /// Sin este permiso el sistema agrupa los avisos para ahorrar bateria y
  /// puede retrasarlos bastante; una alarma que llega media hora tarde no
  /// sirve de nada. Se comprueba aparte del permiso de notificaciones porque
  /// son dos cosas distintas y se conceden por separado.
  Future<bool> canScheduleExact() async {
    await initialize();
    try {
      return await _android?.canScheduleExactNotifications() ?? false;
    } catch (_) {
      // En Android anterior al 12 el metodo no existe y no hace falta.
      return true;
    }
  }

  Future<void> openExactAlarmSettings() async {
    await initialize();
    await _android?.requestExactAlarmsPermission();
  }

  /// Reprograma todo desde cero a partir de la agenda actual.
  ///
  /// Se borra y se vuelve a programar en vez de intentar llevar la cuenta de
  /// que cambio. Es mas simple y no deja alarmas huerfanas de elementos que
  /// ya se borraron, que es el error clasico de este tipo de sincronizacion.
  Future<AlertStatus> syncAll(List<AgendaEntry> entries) async {
    await initialize();
    if (!_ready) return _last;

    final exact = await canScheduleExact();

    try {
      await _plugin.cancelAll();

      final now = DateTime.now();
      final pending = <_PendingAlert>[];

      for (final entry in entries) {
        if (entry.hasReminder && entry.start.isAfter(now)) {
          pending.add(
            _PendingAlert(
              id: _idFor(entry.id),
              title: entry.title,
              body: entry is TimeBlock
                  ? 'Empieza tu bloque'
                  : 'Tienes esto pendiente',
              when: entry.start,
              alert: entry.alert,
            ),
          );
        }

        // Los pasos de un bloque tienen su propio aviso y su propia hora.
        if (entry is TimeBlock) {
          for (final subtask in entry.subtasks) {
            final remindAt = subtask.remindAt;
            if (!subtask.hasReminder || subtask.done) continue;
            if (remindAt == null || !remindAt.isAfter(now)) continue;

            pending.add(
              _PendingAlert(
                id: _idFor('${entry.id}:${subtask.id}'),
                title: subtask.title,
                body: entry.title,
                when: remindAt,
                alert: subtask.alert,
              ),
            );
          }
        }
      }

      pending.sort((a, b) => a.when.compareTo(b.when));
      final take = pending.take(_maxScheduled).toList();

      for (final alert in take) {
        await _schedule(alert, exact: exact);
      }

      // Se cuenta lo que quedo de verdad en el sistema, no lo que se intento:
      // si Android rechazo alguna, la diferencia se ve.
      final actual = await _plugin.pendingNotificationRequests();

      _last = AlertStatus(
        scheduled: actual.length,
        next: take.isEmpty ? null : take.first.when,
        nextTitle: take.isEmpty ? null : take.first.title,
        exactAllowed: exact,
      );

      LoggerService.info(
        'Programados ${actual.length} avisos (exacto: $exact).',
        tag: 'AVISOS',
      );
      return _last;
    } catch (error, stackTrace) {
      _last = AlertStatus(
        exactAllowed: exact,
        error: error.toString(),
      );
      LoggerService.error(
        'Fallo al programar los avisos.',
        tag: 'AVISOS',
        error: error,
        stackTrace: stackTrace,
      );
      return _last;
    }
  }

  /// Estado actual, leido del sistema y no de memoria.
  Future<AlertStatus> status() async {
    await initialize();
    if (!_ready) return _last;

    try {
      final actual = await _plugin.pendingNotificationRequests();
      return AlertStatus(
        scheduled: actual.length,
        next: _last.next,
        nextTitle: _last.nextTitle,
        exactAllowed: await canScheduleExact(),
        error: _last.error,
      );
    } catch (error) {
      return AlertStatus(error: error.toString());
    }
  }

  Future<void> _schedule(_PendingAlert alert, {required bool exact}) async {
    final isAlarm = alert.alert == AlertMode.alarm;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        isAlarm ? _channelAlarm : _channelNotice,
        isAlarm ? 'Alarmas' : 'Avisos',
        importance: isAlarm ? Importance.max : Importance.high,
        priority: isAlarm ? Priority.high : Priority.defaultPriority,
        // La pantalla completa es lo que hace que una alarma se sienta alarma
        // y no una notificacion mas entre veinte.
        fullScreenIntent: isAlarm,
        category: isAlarm ? AndroidNotificationCategory.alarm : null,
        audioAttributesUsage: isAlarm
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(alert.body),
      ),
    );

    // Todo va a hora exacta cuando Android lo permite, tambien los avisos
    // normales: un recordatorio que llega cuando al sistema le viene bien no
    // es un recordatorio. Si el permiso no esta, se degrada en vez de fallar.
    await _plugin.zonedSchedule(
      alert.id,
      alert.title,
      alert.body,
      tz.TZDateTime.from(alert.when, tz.local),
      details,
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      // La hora guardada es la hora del reloj de pared, no un instante
      // absoluto en otra zona. Este parametro solo lo mira iOS, pero la
      // libreria lo exige igual y sin el no compila.
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Muestra un aviso ahora mismo, para poder comprobar que todo funciona sin
  /// tener que esperar a que llegue la hora de algo.
  Future<void> showTest({bool asAlarm = false}) async {
    await initialize();
    if (!_ready) return;

    await _plugin.show(
      99999,
      asAlarm ? 'Alarma de prueba' : 'Aviso de prueba',
      asAlarm
          ? 'Asi va a sonar cuando pongas una alarma.'
          : 'Asi se va a ver un aviso normal.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          asAlarm ? _channelAlarm : _channelNotice,
          asAlarm ? 'Alarmas' : 'Avisos',
          importance: asAlarm ? Importance.max : Importance.high,
          priority: asAlarm ? Priority.high : Priority.defaultPriority,
          audioAttributesUsage: asAlarm
              ? AudioAttributesUsage.alarm
              : AudioAttributesUsage.notification,
        ),
      ),
    );
  }

  /// Convierte un identificador de texto en el entero que exige Android.
  ///
  /// Se recorta el signo porque los negativos no valen como identificador.
  int _idFor(String value) => value.hashCode & 0x7fffffff;
}

class _PendingAlert {
  const _PendingAlert({
    required this.id,
    required this.title,
    required this.body,
    required this.when,
    required this.alert,
  });

  final int id;
  final String title;
  final String body;
  final DateTime when;
  final AlertMode alert;
}
