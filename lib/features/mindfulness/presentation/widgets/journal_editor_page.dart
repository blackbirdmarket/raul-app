import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/journal_entry.dart';
import '../../../../utils/date_format.dart';
import '../../../../utils/extensions.dart';
import '../providers/mindfulness_providers.dart';

/// Abre la hoja para escribir.
Future<void> showJournalEditor(
  BuildContext context, {
  JournalEntry? existing,
}) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: existing == null,
      builder: (_) => _JournalEditorPage(existing: existing),
    ),
  );
}

/// La hoja en blanco.
///
/// Es una pantalla completa y no una ventanita: escribir un decreto o una
/// manifestacion no es rellenar un formulario, y una caja de tres lineas con
/// botones alrededor pide brevedad sin decirlo. Aqui hay una hoja, el teclado
/// y nada mas.
///
/// Guarda solo al salir. Un cuaderno que interrumpe con "guardado" cada pocos
/// segundos rompe justo lo que uno viene a buscar.
class _JournalEditorPage extends ConsumerStatefulWidget {
  const _JournalEditorPage({this.existing});

  final JournalEntry? existing;

  @override
  ConsumerState<_JournalEditorPage> createState() => _JournalEditorPageState();
}

class _JournalEditorPageState extends ConsumerState<_JournalEditorPage> {
  late final TextEditingController _title;
  late final TextEditingController _text;
  late final FocusNode _textFocus;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _text = TextEditingController(text: widget.existing?.text ?? '');
    _textFocus = FocusNode();

    // En un escrito nuevo el cursor va directo al cuerpo, no al titulo: el
    // titulo es opcional y pedirlo primero es la forma mas rapida de que
    // alguien cierre la hoja sin escribir nada.
    if (!_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _textFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  Future<void> _saveAndLeave() async {
    final controller = ref.read(journalProvider.notifier);
    final now = DateTime.now();
    final title = _title.text.trim();

    final entry = widget.existing == null
        ? JournalEntry(
            id: controller.newId(),
            text: _text.text,
            title: title.isEmpty ? null : title,
            createdAt: now,
          )
        : widget.existing!.copyWith(
            text: _text.text,
            title: title.isEmpty ? null : title,
            clearTitle: title.isEmpty,
            updatedAt: now,
          );

    await controller.save(entry);

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) {
      Navigator.of(context).pop();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Borrar el escrito'),
        content: const Text('No se puede recuperar.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await ref.read(journalProvider.notifier).remove(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final existing = widget.existing;
    final date = existing?.createdAt ?? DateTime.now();

    return PopScope(
      // Salir por el gesto de atras tambien guarda: no hay ningun caso en que
      // alguien escriba media pagina y quiera perderla por retroceder.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _saveAndLeave();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spaceSm,
                  AppConstants.spaceSm,
                  AppConstants.spaceSm,
                  0,
                ),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: _saveAndLeave,
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Guardar y salir',
                    ),
                    Expanded(
                      child: Text(
                        DateNames.relativeDay(date).capitalized,
                        style: context.texts.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    if (existing != null)
                      IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          ref
                              .read(journalProvider.notifier)
                              .togglePinned(existing.id);
                          setState(() {});
                        },
                        icon: Icon(
                          (ref.read(journalProvider.notifier).byId(existing.id)
                                      ?.pinned ??
                                  false)
                              ? Icons.push_pin_rounded
                              : Icons.push_pin_outlined,
                        ),
                        color: (ref
                                    .read(journalProvider.notifier)
                                    .byId(existing.id)
                                    ?.pinned ??
                                false)
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        tooltip: 'Fijar arriba',
                      ),
                    IconButton(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: scheme.error,
                      tooltip: 'Borrar',
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spaceMd + 4,
                ),
                child: TextField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  style: context.texts.headlineSmall,
                  decoration: InputDecoration(
                    hintText: 'Titulo (opcional)',
                    hintStyle: context.texts.headlineSmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppConstants.spaceMd + 4,
                    AppConstants.spaceSm,
                    AppConstants.spaceMd + 4,
                    AppConstants.spaceMd,
                  ),
                  child: TextField(
                    controller: _text,
                    focusNode: _textFocus,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    style: context.texts.bodyLarge?.copyWith(height: 1.65),
                    decoration: InputDecoration(
                      hintText: 'Escribe aqui.',
                      hintStyle: context.texts.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                        height: 1.65,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
