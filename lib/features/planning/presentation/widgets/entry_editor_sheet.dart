import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/agenda_entry.dart';
import '../../../../models/alert_mode.dart';
import '../../../../models/recurrence.dart';
import '../../../../models/sub_task.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/date_format.dart';
import '../../../../utils/extensions.dart';
import '../providers/agenda_providers.dart';

/// Abre el editor de la agenda.
///
/// Sirve para crear y para editar: si llega `existing` el formulario aparece
/// lleno. Se hace en una hoja y no en una pantalla completa porque crear algo
/// tiene que sentirse liviano, sin perder de vista el dia que hay detras.
Future<void> showEntryEditor(
  BuildContext context, {
  required DateTime day,
  AgendaEntry? existing,
  DateTime? initialAt,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // Sobre el navegador raiz: si se abre en el del area, la barra flotante
    // de abajo queda dibujada encima y tapa el boton de guardar.
    useRootNavigator: true,
    builder: (_) => _EntryEditorSheet(
      day: day,
      existing: existing,
      initialAt: initialAt,
    ),
  );
}

class _EntryEditorSheet extends ConsumerStatefulWidget {
  const _EntryEditorSheet({
    required this.day,
    this.existing,
    this.initialAt,
  });

  final DateTime day;
  final AgendaEntry? existing;
  final DateTime? initialAt;

  @override
  ConsumerState<_EntryEditorSheet> createState() => _EntryEditorSheetState();
}

class _EntryEditorSheetState extends ConsumerState<_EntryEditorSheet> {
  late bool _isBlock;
  late TextEditingController _title;
  late TextEditingController _notes;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late AlertMode _alert;
  late Recurrence _recurrence;
  late int _colorIndex;
  final List<_EditableSubTask> _subtasks = <_EditableSubTask>[];
  final TextEditingController _newSubtask = TextEditingController();

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;
    final seed = widget.initialAt ?? _defaultStart();

    _isBlock = existing is TimeBlock;
    _title = TextEditingController(text: existing?.title ?? '');
    _notes = TextEditingController(text: existing?.notes ?? '');
    _alert = existing?.alert ?? AlertMode.notification;
    _recurrence = existing?.recurrence ?? Recurrence.never;
    _colorIndex = existing is TimeBlock ? existing.colorIndex : 0;

    _start = TimeOfDay.fromDateTime(existing?.start ?? seed);
    _end = TimeOfDay.fromDateTime(
      existing is TimeBlock
          ? existing.end
          : (existing?.start ?? seed).add(const Duration(hours: 1)),
    );

    if (existing is TimeBlock) {
      for (final subtask in existing.subtasks) {
        _subtasks.add(_EditableSubTask.from(subtask));
      }
    }
  }

  /// Por defecto la proxima media hora en punto, no "ahora mismo".
  DateTime _defaultStart() {
    final now = DateTime.now();
    final minute = now.minute < 30 ? 30 : 0;
    final hour = now.minute < 30 ? now.hour : now.hour + 1;
    return DateTime(
      widget.day.year,
      widget.day.month,
      widget.day.day,
      hour.clamp(0, 23),
      minute,
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _newSubtask.dispose();
    for (final subtask in _subtasks) {
      subtask.dispose();
    }
    super.dispose();
  }

  DateTime _combine(TimeOfDay time) => DateTime(
        widget.day.year,
        widget.day.month,
        widget.day.day,
        time.hour,
        time.minute,
      );

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
      // Teclado y no reloj: en el reloj de 24 horas los numeros interiores
      // quedan tapados por el circulo de seleccion, y ademas escribir la hora
      // es mas rapido que arrastrar una aguja.
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        // Al mover el inicio, el fin lo sigue para no dejar duraciones
        // negativas sin que el usuario entienda por que.
        final duration = _durationMinutes();
        _start = picked;
        final endMinutes = picked.hour * 60 + picked.minute + duration;
        _end = TimeOfDay(
          hour: (endMinutes ~/ 60).clamp(0, 23),
          minute: endMinutes % 60,
        );
      } else {
        _end = picked;
      }
    });
  }

  int _durationMinutes() {
    final start = _start.hour * 60 + _start.minute;
    final end = _end.hour * 60 + _end.minute;
    final diff = end - start;
    return diff > 0 ? diff : 60;
  }

  void _addSubtask() {
    final text = _newSubtask.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks.add(_EditableSubTask.blank(text));
      _newSubtask.clear();
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      context.showError('Ponle un nombre antes de guardar.');
      return;
    }

    final notes = _notes.text.trim();
    final existing = widget.existing;
    final id = existing?.id ?? newEntryId();
    final start = _combine(_start);

    final AgendaEntry entry;
    if (_isBlock) {
      var end = _combine(_end);
      // Un bloque que termina antes de empezar no tiene sentido: se le da
      // una hora en vez de rechazar el guardado.
      if (!end.isAfter(start)) end = start.add(const Duration(hours: 1));

      entry = TimeBlock(
        id: id,
        title: title,
        start: start,
        end: end,
        notes: notes.isEmpty ? null : notes,
        alert: _alert,
        createdAt: existing?.createdAt ?? DateTime.now(),
        seriesId: existing?.seriesId,
        recurrence: _recurrence,
        colorIndex: _colorIndex,
        subtasks: _subtasks
            .where((s) => s.controller.text.trim().isNotEmpty)
            .map((s) => s.toSubTask(widget.day))
            .toList(),
      );
    } else {
      entry = QuickTask(
        id: id,
        title: title,
        start: start,
        notes: notes.isEmpty ? null : notes,
        alert: _alert,
        createdAt: existing?.createdAt ?? DateTime.now(),
        seriesId: existing?.seriesId,
        recurrence: _recurrence,
        done: existing is QuickTask ? existing.done : false,
      );
    }

    final agenda = ref.read(agendaProvider.notifier);

    // Al crear se genera la serie completa; al editar se toca solo esta
    // ocurrencia, porque cambiar el pasado de una repeticion sorprende mas
    // de lo que ayuda.
    if (!_isEditing && _recurrence.isActive) {
      await agenda.createSeries(entry);
    } else {
      await agenda.upsert(entry);
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;

    final agenda = ref.read(agendaProvider.notifier);
    final series = existing.seriesId;

    // Borrar una ocurrencia de una repeticion sin preguntar seria destructivo
    // en cualquiera de los dos sentidos posibles.
    if (series != null) {
      final all = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Esto se repite'),
          content: const Text(
            'Puedes borrar solo esta vez, o toda la repeticion.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Solo esta vez'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Toda la repeticion'),
            ),
          ],
        ),
      );

      if (all == null) return;
      if (all) {
        await agenda.removeSeries(series);
      } else {
        await agenda.remove(existing.id);
      }
    } else {
      await agenda.remove(existing.id);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            // El ultimo boton tiene que quedar por encima de los botones
            // del telefono, que en cada modelo ocupan un alto distinto.
            padding: EdgeInsets.fromLTRB(
              AppConstants.spaceMd,
              AppConstants.spaceSm,
              AppConstants.spaceMd,
              AppConstants.spaceXl +
                  MediaQuery.viewPaddingOf(context).bottom,
            ),
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _isEditing ? 'Editar' : 'Nuevo',
                      style: context.texts.headlineSmall,
                    ),
                  ),
                  if (_isEditing)
                    IconButton(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: scheme.error,
                      tooltip: 'Borrar',
                    ),
                ],
              ),
              Text(
                DateNames.relativeDay(widget.day),
                style: context.texts.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppConstants.spaceLg),

              _TypeSelector(
                isBlock: _isBlock,
                // Cambiar de tipo con un bloque ya guardado obligaria a
                // decidir que hacer con sus pasos. Se bloquea al editar.
                enabled: !_isEditing,
                onChanged: (value) => setState(() => _isBlock = value),
              ),
              const SizedBox(height: AppConstants.spaceLg),

              TextField(
                controller: _title,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.sentences,
                style: context.texts.titleMedium,
                decoration: InputDecoration(
                  hintText:
                      _isBlock ? 'Nombre del bloque' : 'Nombre de la tarea',
                  prefixIcon: Icon(
                    _isBlock
                        ? Icons.view_agenda_outlined
                        : Icons.check_circle_outline_rounded,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.spaceMd),

              Row(
                children: <Widget>[
                  Expanded(
                    child: _TimeField(
                      label: _isBlock ? 'Empieza' : 'Hora',
                      time: _start,
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  if (_isBlock) ...<Widget>[
                    const SizedBox(width: AppConstants.spaceSm),
                    Expanded(
                      child: _TimeField(
                        label: 'Termina',
                        time: _end,
                        onTap: () => _pickTime(isStart: false),
                      ),
                    ),
                  ],
                ],
              ),

              if (_isBlock) ...<Widget>[
                const SizedBox(height: AppConstants.spaceXs),
                Text(
                  'Dura ${DateNames.duration(
                    Duration(minutes: _durationMinutes()),
                  )}',
                  style: context.texts.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],

              const SizedBox(height: AppConstants.spaceLg),
              _SectionLabel(_isBlock ? 'Aviso del bloque' : 'Aviso'),
              const SizedBox(height: AppConstants.spaceSm),
              _AlertSelector(
                value: _alert,
                onChanged: (value) => setState(() => _alert = value),
              ),

              const SizedBox(height: AppConstants.spaceLg),
              const _SectionLabel('Repetir'),
              const SizedBox(height: AppConstants.spaceSm),
              if (_isEditing)
                _RecurrenceReadOnly(recurrence: _recurrence)
              else
                _RecurrenceSelector(
                  value: _recurrence,
                  onChanged: (value) => setState(() => _recurrence = value),
                ),

              if (_isBlock) ...<Widget>[
                const SizedBox(height: AppConstants.spaceLg),
                const _SectionLabel('Color'),
                const SizedBox(height: AppConstants.spaceSm),
                _ColorSelector(
                  value: _colorIndex,
                  onChanged: (value) => setState(() => _colorIndex = value),
                ),
                const SizedBox(height: AppConstants.spaceLg),
                const _SectionLabel('Pasos'),
                const SizedBox(height: AppConstants.spaceSm),
                for (var i = 0; i < _subtasks.length; i++)
                  _SubtaskEditor(
                    key: ValueKey<String>(_subtasks[i].id),
                    editable: _subtasks[i],
                    day: widget.day,
                    onRemove: () => setState(() {
                      _subtasks.removeAt(i).dispose();
                    }),
                    onChanged: () => setState(() {}),
                  ),
                _NewSubtaskField(
                  controller: _newSubtask,
                  onSubmit: _addSubtask,
                ),
              ],

              const SizedBox(height: AppConstants.spaceLg),
              TextField(
                controller: _notes,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Notas (opcional)',
                ),
              ),

              const SizedBox(height: AppConstants.spaceXl),
              FilledButton(
                onPressed: _save,
                child: Text(_isEditing ? 'Guardar cambios' : 'Crear'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Estado editable de un paso, con su propio controlador de texto.
class _EditableSubTask {
  _EditableSubTask({
    required this.id,
    required this.controller,
    required this.done,
    required this.alert,
    required this.remindAt,
  });

  factory _EditableSubTask.blank(String title) => _EditableSubTask(
        id: newEntryId(),
        controller: TextEditingController(text: title),
        done: false,
        alert: AlertMode.none,
        remindAt: null,
      );

  /// El modelo guarda la fecha y hora completas; el editor solo maneja la
  /// hora, porque el dia ya lo define el bloque.
  factory _EditableSubTask.from(SubTask subtask) {
    final reminder = subtask.remindAt;
    return _EditableSubTask(
      id: subtask.id,
      controller: TextEditingController(text: subtask.title),
      done: subtask.done,
      alert: subtask.alert,
      remindAt: reminder == null ? null : TimeOfDay.fromDateTime(reminder),
    );
  }

  final String id;
  final TextEditingController controller;
  bool done;
  AlertMode alert;
  TimeOfDay? remindAt;

  void dispose() => controller.dispose();

  SubTask toSubTask(DateTime day) {
    final reminder = remindAt;
    return SubTask(
      id: id,
      title: controller.text.trim(),
      done: done,
      alert: alert,
      remindAt: reminder == null
          ? null
          : DateTime(
              day.year,
              day.month,
              day.day,
              reminder.hour,
              reminder.minute,
            ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.isBlock,
    required this.onChanged,
    this.enabled = true,
  });

  final bool isBlock;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: _TypeOption(
                label: 'Tarea rapida',
                caption: 'Se marca y listo',
                icon: Icons.check_circle_outline_rounded,
                selected: !isBlock,
                onTap: enabled ? () => onChanged(false) : null,
              ),
            ),
            Expanded(
              child: _TypeOption(
                label: 'Bloque',
                caption: 'Con pasos dentro',
                icon: Icons.view_agenda_outlined,
                selected: isBlock,
                onTap: enabled ? () => onChanged(true) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.label,
    required this.caption,
    required this.icon,
    required this.selected,
    this.onTap,
  });

  final String label;
  final String caption;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppConstants.durationFast,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? scheme.surfaceContainerHighest : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        ),
        child: Column(
          children: <Widget>[
            Icon(
              icon,
              size: 20,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: context.texts.labelLarge?.copyWith(
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
            Text(
              caption,
              style: context.texts.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spaceMd,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: context.texts.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:'
              '${time.minute.toString().padLeft(2, '0')}',
              style: context.texts.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertSelector extends StatelessWidget {
  const _AlertSelector({required this.value, required this.onChanged});

  final AlertMode value;
  final ValueChanged<AlertMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (final mode in AlertMode.values) ...<Widget>[
          Expanded(
            child: _AlertOption(
              mode: mode,
              selected: mode == value,
              onTap: () => onChanged(mode),
            ),
          ),
          if (mode != AlertMode.values.last)
            const SizedBox(width: AppConstants.spaceSm),
        ],
      ],
    );
  }
}

class _AlertOption extends StatelessWidget {
  const _AlertOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final AlertMode mode;
  final bool selected;
  final VoidCallback onTap;

  IconData get _icon => switch (mode) {
        AlertMode.none => Icons.notifications_off_outlined,
        AlertMode.notification => Icons.notifications_none_rounded,
        AlertMode.alarm => Icons.alarm_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppConstants.durationFast,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.16)
              : scheme.surfaceContainer,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
        child: Column(
          children: <Widget>[
            Icon(
              _icon,
              size: 19,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              mode.label,
              textAlign: TextAlign.center,
              style: context.texts.labelMedium?.copyWith(
                fontSize: 11,
                letterSpacing: 0,
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Elige cada cuanto se repite.
///
/// Solo se ofrece al crear. Cambiar la repeticion de algo que ya existe
/// obligaria a decidir que pasa con las ocurrencias ya marcadas, y esa
/// pregunta no vale lo que cuesta responderla.
class _RecurrenceSelector extends StatelessWidget {
  const _RecurrenceSelector({required this.value, required this.onChanged});

  final Recurrence value;
  final ValueChanged<Recurrence> onChanged;

  static const List<RecurrenceType> _types = <RecurrenceType>[
    RecurrenceType.none,
    RecurrenceType.daily,
    RecurrenceType.weekdays,
    RecurrenceType.weekly,
    RecurrenceType.everyNDays,
  ];

  @override
  Widget build(BuildContext context) {
    final custom = value.type == RecurrenceType.everyNDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: AppConstants.spaceSm,
          runSpacing: AppConstants.spaceSm,
          children: <Widget>[
            for (final type in _types)
              _RecurrenceChip(
                label: Recurrence(type: type, interval: value.interval)
                    .shortLabel,
                selected: type == value.type,
                onTap: () => onChanged(value.copyWith(type: type)),
              ),
          ],
        ),
        if (custom) ...<Widget>[
          const SizedBox(height: AppConstants.spaceMd),
          _IntervalStepper(
            interval: value.interval,
            onChanged: (next) => onChanged(value.copyWith(interval: next)),
          ),
        ],
        const SizedBox(height: AppConstants.spaceSm),
        Text(
          value.isActive
              ? 'Se crearan las proximas repeticiones automaticamente.'
              : 'Ocurre una sola vez.',
          style: context.texts.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _RecurrenceReadOnly extends StatelessWidget {
  const _RecurrenceReadOnly({required this.recurrence});

  final Recurrence recurrence;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Row(
      children: <Widget>[
        Icon(
          recurrence.isActive
              ? Icons.repeat_rounded
              : Icons.looks_one_outlined,
          size: 18,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppConstants.spaceSm),
        Expanded(
          child: Text(
            recurrence.label,
            style: context.texts.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecurrenceChip extends StatelessWidget {
  const _RecurrenceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppConstants.durationFast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.16)
              : scheme.surfaceContainer,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        ),
        child: Text(
          label,
          style: context.texts.labelLarge?.copyWith(
            fontSize: 13,
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _IntervalStepper extends StatelessWidget {
  const _IntervalStepper({required this.interval, required this.onChanged});

  final int interval;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Row(
      children: <Widget>[
        Text('Cada', style: context.texts.bodyMedium),
        const SizedBox(width: AppConstants.spaceMd),
        _StepButton(
          icon: Icons.remove_rounded,
          // Menos de dos dias ya lo cubre "todos los dias".
          onTap: interval > 2 ? () => onChanged(interval - 1) : null,
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$interval',
            textAlign: TextAlign.center,
            style: context.texts.titleLarge,
          ),
        ),
        _StepButton(
          icon: Icons.add_rounded,
          onTap: interval < 60 ? () => onChanged(interval + 1) : null,
        ),
        const SizedBox(width: AppConstants.spaceMd),
        Text(
          'dias',
          style: context.texts.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final enabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppConstants.radiusSm),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? scheme.onSurface : scheme.outline,
        ),
      ),
    );
  }
}

class _ColorSelector extends StatelessWidget {
  const _ColorSelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (var i = 0; i < AppColors.blockAccents.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: AppConstants.spaceSm),
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: AppConstants.durationFast,
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.blockAccents[i],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: i == value
                        ? context.colors.onSurface
                        : Colors.transparent,
                    width: 2.4,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SubtaskEditor extends StatelessWidget {
  const _SubtaskEditor({
    required this.editable,
    required this.day,
    required this.onRemove,
    required this.onChanged,
    super.key,
  });

  final _EditableSubTask editable;
  final DateTime day;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  /// Rota entre los tres modos y pide la hora al activar un aviso.
  Future<void> _cycleAlert(BuildContext context) async {
    final next = switch (editable.alert) {
      AlertMode.none => AlertMode.notification,
      AlertMode.notification => AlertMode.alarm,
      AlertMode.alarm => AlertMode.none,
    };

    editable.alert = next;

    if (next == AlertMode.none) {
      editable.remindAt = null;
      onChanged();
      return;
    }

    if (editable.remindAt == null) {
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        initialEntryMode: TimePickerEntryMode.input,
      );
      if (picked != null) {
        editable.remindAt = picked;
      } else {
        editable.alert = AlertMode.none;
      }
    }

    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final reminder = editable.remindAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spaceSm),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.drag_indicator_rounded,
            size: 18,
            color: scheme.outline,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: editable.controller,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Paso',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => _cycleAlert(context),
            tooltip: reminder == null
                ? 'Sin aviso'
                : '${editable.alert.label} a las '
                    '${reminder.hour.toString().padLeft(2, '0')}:'
                    '${reminder.minute.toString().padLeft(2, '0')}',
            icon: Icon(
              switch (editable.alert) {
                AlertMode.none => Icons.notifications_off_outlined,
                AlertMode.notification => Icons.notifications_none_rounded,
                AlertMode.alarm => Icons.alarm_rounded,
              },
              size: 20,
              color: editable.alert == AlertMode.none
                  ? scheme.outline
                  : scheme.primary,
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 20),
            color: scheme.onSurfaceVariant,
            tooltip: 'Quitar paso',
          ),
        ],
      ),
    );
  }
}

class _NewSubtaskField extends StatelessWidget {
  const _NewSubtaskField({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const SizedBox(width: 22),
        Expanded(
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.sentences,
            onSubmitted: (_) => onSubmit(),
            decoration: const InputDecoration(
              hintText: 'Agregar paso',
              isDense: true,
              prefixIcon: Icon(Icons.add_rounded, size: 20),
            ),
          ),
        ),
        IconButton(
          onPressed: onSubmit,
          icon: const Icon(Icons.arrow_upward_rounded, size: 20),
          tooltip: 'Agregar',
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: context.texts.labelSmall?.copyWith(
        color: context.colors.onSurfaceVariant,
        fontSize: 10,
      ),
    );
  }
}
