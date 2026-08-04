import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/alert_status.dart';
import '../../../../services/notification_service.dart';
import '../../../../theme/theme_controller.dart';
import '../../../../utils/date_format.dart';
import '../../../../utils/extensions.dart';
import '../../../../widgets/app_card.dart';
import '../../../../widgets/fade_in.dart';
import '../../../planning/presentation/providers/agenda_providers.dart';
import '../providers/settings_provider.dart';

/// Pantalla de ajustes.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);
    final total = ref.watch(agendaProvider).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Ajustes')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.spaceMd),
          children: <Widget>[
            const FadeIn(child: _SectionTitle('Apariencia')),
            const SizedBox(height: AppConstants.spaceSm),
            FadeIn(
              delay: const Duration(milliseconds: 60),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _AppearanceSwitch(
                      value: themeMode,
                      onChanged: (mode) => ref
                          .read(themeControllerProvider.notifier)
                          .setThemeMode(mode),
                    ),
                    const SizedBox(height: AppConstants.spaceSm),
                    Text(
                      _descriptionFor(themeMode),
                      style: context.texts.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppConstants.spaceLg),
            const FadeIn(
              delay: Duration(milliseconds: 120),
              child: _SectionTitle('Avisos'),
            ),
            const SizedBox(height: AppConstants.spaceSm),
            const FadeIn(
              delay: Duration(milliseconds: 160),
              child: _NotificationsCard(),
            ),

            const SizedBox(height: AppConstants.spaceLg),
            const FadeIn(
              delay: Duration(milliseconds: 200),
              child: _SectionTitle('Datos'),
            ),
            const SizedBox(height: AppConstants.spaceSm),
            FadeIn(
              delay: const Duration(milliseconds: 240),
              child: AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: const Text('En tu agenda'),
                      subtitle: Text(
                        total == 1
                            ? '1 elemento guardado'
                            : '$total elementos guardados',
                      ),
                    ),
                    Divider(height: 1, color: context.colors.outlineVariant),
                    ListTile(
                      leading: Icon(
                        Icons.delete_outline_rounded,
                        color: context.colors.error,
                      ),
                      title: const Text('Restablecer la aplicacion'),
                      subtitle: const Text(
                        'Borra toda tu agenda de este telefono.',
                      ),
                      onTap: () => _confirmReset(context, ref),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppConstants.spaceLg),
            const FadeIn(
              delay: Duration(milliseconds: 280),
              child: _SectionTitle('Acerca de'),
            ),
            const SizedBox(height: AppConstants.spaceSm),
            const FadeIn(
              delay: Duration(milliseconds: 320),
              child: AppCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: Icon(Icons.auto_awesome_rounded),
                  title: Text(AppConstants.appName),
                  subtitle: Text('Version ${AppConstants.appVersion}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restablecer la aplicacion'),
        content: const Text(
          'Se borrara toda tu agenda de este telefono. '
          'Esta accion no se puede deshacer.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await ref.read(settingsControllerProvider).resetAllData();

    // El usuario pudo salir de la pantalla mientras se borraban los datos.
    if (!context.mounted) return;

    result.fold(
      onSuccess: (_) => context.showMessage('Aplicacion restablecida.'),
      onFailure: (failure) => context.showError(failure.message),
    );
  }

  static String _descriptionFor(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'Sigue la configuracion del telefono.',
        ThemeMode.light => 'Siempre con fondo claro.',
        ThemeMode.dark => 'Siempre con fondo oscuro.',
      };
}

/// Estado de los avisos del sistema, con permiso y prueba.
///
/// Es una tarjeta con estado propio porque preguntarle a Android si tiene
/// permiso es una operacion asincrona: no se puede resolver mientras se pinta.
class _NotificationsCard extends ConsumerStatefulWidget {
  const _NotificationsCard();

  @override
  ConsumerState<_NotificationsCard> createState() => _NotificationsCardState();
}

class _NotificationsCardState extends ConsumerState<_NotificationsCard> {
  bool? _granted;
  AlertStatus? _status;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final granted = await NotificationService.instance.hasPermission();
    final status = await NotificationService.instance.status();
    if (mounted) {
      setState(() {
        _granted = granted;
        _status = status;
      });
    }
  }

  Future<void> _request() async {
    await NotificationService.instance.requestPermissions();
    await _refresh();

    if (!mounted) return;
    context.showMessage(
      _granted == true
          ? 'Listo, los avisos estan activados.'
          : 'Android no dio el permiso. Puedes activarlo desde los ajustes '
              'del telefono.',
    );
  }

  /// Vuelve a programar todo y cuenta que paso.
  ///
  /// Es el boton que convierte un fallo mudo en una respuesta: dice cuantos
  /// avisos quedaron puestos, cual es el proximo, y si Android rechazo algo.
  Future<void> _resync() async {
    setState(() => _working = true);

    final entries = ref.read(agendaProvider);
    final status = await NotificationService.instance.syncAll(entries);

    if (!mounted) return;
    setState(() {
      _status = status;
      _working = false;
    });

    context.showMessage(
      status.hasError
          ? 'Android rechazo la programacion: ${status.error}'
          : status.isEmpty
              ? 'No hay nada futuro con aviso. Crea algo con alarma y vuelve '
                  'a revisar.'
              : '${status.scheduled} avisos programados.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    if (kIsWeb) {
      return AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppConstants.spaceSm),
            Expanded(
              child: Text(
                'Los avisos y las alarmas solo funcionan en el telefono. '
                'Aqui en el navegador esta parte queda apagada.',
                style: context.texts.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final granted = _granted;
    final status = _status;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          ListTile(
            leading: Icon(
              granted == true
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: granted == true ? scheme.primary : scheme.error,
            ),
            title: Text(
              granted == null
                  ? 'Comprobando...'
                  : granted
                      ? 'Avisos activados'
                      : 'Avisos desactivados',
            ),
            subtitle: Text(
              granted == true
                  ? 'Tus tareas y pasos con aviso van a sonar a su hora.'
                  : 'Sin este permiso, nada de lo que programes va a avisarte.',
              style: context.texts.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            trailing: granted == true
                ? null
                : TextButton(
                    onPressed: _request,
                    child: const Text('Activar'),
                  ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),

          // El permiso de hora exacta es distinto del de notificaciones y se
          // concede por separado. Sin el, Android agrupa los avisos cuando le
          // conviene y pueden llegar con mucho retraso: es la causa mas comun
          // de "programe una alarma y nunca sono".
          if (status != null && !status.exactAllowed) ...<Widget>[
            ListTile(
              leading: Icon(Icons.timer_off_rounded, color: scheme.error),
              title: const Text('Sin permiso de hora exacta'),
              subtitle: Text(
                'Android puede retrasar tus avisos. Dale el permiso para que '
                'suenen a la hora que pusiste.',
                style: context.texts.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              trailing: TextButton(
                onPressed: () async {
                  await NotificationService.instance.openExactAlarmSettings();
                  await _refresh();
                },
                child: const Text('Permitir'),
              ),
            ),
            Divider(height: 1, color: scheme.outlineVariant),
          ],

          ListTile(
            leading: Icon(
              Icons.schedule_rounded,
              color: status != null && status.hasError
                  ? scheme.error
                  : scheme.onSurfaceVariant,
            ),
            title: Text(
              status == null
                  ? 'Comprobando avisos programados...'
                  : status.hasError
                      ? 'Los avisos no se pudieron programar'
                      : status.isEmpty
                          ? 'No hay avisos programados'
                          : '${status.scheduled} avisos programados',
            ),
            subtitle: Text(
              status == null
                  ? ''
                  : status.hasError
                      ? status.error!
                      : status.next != null
                          ? 'El proximo: ${status.nextTitle} a las '
                              '${DateNames.time(status.next!)}'
                          : 'Cuando crees algo con aviso, aparece aqui.',
              style: context.texts.bodySmall?.copyWith(
                color: status != null && status.hasError
                    ? scheme.error
                    : scheme.onSurfaceVariant,
              ),
            ),
            trailing: _working
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: _resync,
                    child: const Text('Revisar'),
                  ),
          ),

          Divider(height: 1, color: scheme.outlineVariant),
          ListTile(
            leading: const Icon(Icons.notifications_none_rounded),
            title: const Text('Probar un aviso'),
            subtitle: const Text('Aparece de inmediato, sin esperar.'),
            onTap: () => NotificationService.instance.showTest(),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          ListTile(
            leading: const Icon(Icons.alarm_rounded),
            title: const Text('Probar una alarma'),
            subtitle: const Text('Suena fuerte, como la de la pastilla.'),
            onTap: () => NotificationService.instance.showTest(asAlarm: true),
          ),
        ],
      ),
    );
  }
}

/// Oscuro / Sistema / Claro en una sola linea.
///
/// Reemplaza a las tres filas de lista que ocupaban media pantalla para algo
/// que se decide una vez y no se vuelve a tocar.
class _AppearanceSwitch extends StatelessWidget {
  const _AppearanceSwitch({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  static const List<({ThemeMode mode, String label, IconData icon})> _options =
      <({ThemeMode mode, String label, IconData icon})>[
    (mode: ThemeMode.dark, label: 'Oscuro', icon: Icons.dark_mode_rounded),
    (mode: ThemeMode.system, label: 'Sistema', icon: Icons.contrast_rounded),
    (mode: ThemeMode.light, label: 'Claro', icon: Icons.light_mode_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
      ),
      child: Row(
        children: <Widget>[
          for (final option in _options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(option.mode),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: AppConstants.durationFast,
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: option.mode == value
                        ? scheme.primary.withValues(alpha: 0.18)
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusFull),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        option.icon,
                        size: 16,
                        color: option.mode == value
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        option.label,
                        style: context.texts.labelLarge?.copyWith(
                          fontSize: 13,
                          color: option.mode == value
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppConstants.spaceXs),
      child: Text(
        title.toUpperCase(),
        style: context.texts.labelMedium?.copyWith(
          color: context.colors.primary,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
