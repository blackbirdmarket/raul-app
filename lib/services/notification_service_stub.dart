import '../models/agenda_entry.dart';
import '../models/alert_status.dart';

/// Version vacia del servicio de avisos, para la web.
///
/// Tiene exactamente la misma forma que la real y no hace nada. Asi el codigo
/// que la usa no necesita preguntar en que plataforma esta corriendo.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  Future<void> initialize() async {}

  Future<bool> requestPermissions() async => false;

  Future<bool> hasPermission() async => false;

  Future<bool> canScheduleExact() async => false;

  Future<void> openExactAlarmSettings() async {}

  Future<AlertStatus> syncAll(List<AgendaEntry> entries) async =>
      const AlertStatus(
        error: 'Los avisos solo funcionan en el telefono.',
      );

  Future<AlertStatus> status() async => const AlertStatus();

  Future<void> showTest({bool asAlarm = false}) async {}
}
