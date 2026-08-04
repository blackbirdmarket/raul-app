import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/finance_category.dart';
import '../../../../models/money.dart';
import '../../../../models/movement.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/category_icons.dart';
import '../../../../utils/date_format.dart';
import '../../../../utils/extensions.dart';
import '../providers/finance_providers.dart';

/// Abre el editor de un movimiento.
Future<void> showMovementEditor(
  BuildContext context, {
  Movement? existing,
  DateTime? initialDate,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // Sobre el navegador raiz: si se abre en el del area, la barra flotante
    // de abajo queda dibujada encima y tapa el boton de guardar.
    useRootNavigator: true,
    builder: (_) => _MovementEditorSheet(
      existing: existing,
      initialDate: initialDate,
    ),
  );
}

class _MovementEditorSheet extends ConsumerStatefulWidget {
  const _MovementEditorSheet({this.existing, this.initialDate});

  final Movement? existing;
  final DateTime? initialDate;

  @override
  ConsumerState<_MovementEditorSheet> createState() =>
      _MovementEditorSheetState();
}

class _MovementEditorSheetState extends ConsumerState<_MovementEditorSheet> {
  late CategoryKind _kind;
  late TextEditingController _amount;
  late TextEditingController _title;
  late TextEditingController _notes;
  late DateTime _date;
  String? _categoryId;
  String? _accountId;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;
    _kind = existing == null
        ? CategoryKind.expense
        : (existing.isIncome ? CategoryKind.income : CategoryKind.expense);

    _amount = TextEditingController(
      text: existing == null ? '' : Money.format(existing.magnitude),
    );
    _title = TextEditingController(text: existing?.title ?? '');
    _notes = TextEditingController(text: existing?.notes ?? '');
    _date = existing?.date ?? widget.initialDate ?? DateTime.now();
    _categoryId = existing?.categoryId;
    _accountId = existing?.accountId;
  }

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// Reformatea el monto mientras se escribe, para que se lea "12.500" y no
  /// una hilera de digitos que hay que contar con el dedo.
  void _onAmountChanged(String raw) {
    final value = Money.parse(raw);
    final formatted = value == null ? '' : Money.format(value);
    if (formatted == _amount.text) return;

    _amount.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
  }

  Future<void> _save() async {
    final value = Money.parse(_amount.text);
    if (value == null || value == 0) {
      context.showError('Escribe un monto.');
      return;
    }

    final categoryId = _categoryId;
    if (categoryId == null) {
      context.showError('Elige una categoria.');
      return;
    }

    final title = _title.text.trim();
    final notes = _notes.text.trim();
    final existing = widget.existing;

    // El signo lo pone el tipo elegido, no el usuario: escribir "-5000" en un
    // ingreso seria una trampa facil de caer.
    final signed = _kind == CategoryKind.expense ? -value.abs() : value.abs();

    final movement = Movement(
      id: existing?.id ?? ref.read(movementsProvider.notifier).newId(),
      title: title.isEmpty
          ? (ref.read(categoryByIdProvider(categoryId))?.name ?? 'Movimiento')
          : title,
      amount: signed,
      date: _date,
      categoryId: categoryId,
      accountId: _accountId,
      notes: notes.isEmpty ? null : notes,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    await ref.read(movementsProvider.notifier).upsert(movement);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;

    await ref.read(movementsProvider.notifier).remove(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final categories = ref.watch(categoriesOfKindProvider(_kind));
    final accounts = ref.watch(accountsProvider);
    final isExpense = _kind == CategoryKind.expense;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.82,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
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
                      _isEditing ? 'Editar' : 'Nuevo movimiento',
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
              const SizedBox(height: AppConstants.spaceMd),

              _KindSelector(
                value: _kind,
                onChanged: (value) => setState(() {
                  _kind = value;
                  // La categoria elegida ya no aplica al otro tipo.
                  _categoryId = null;
                }),
              ),
              const SizedBox(height: AppConstants.spaceLg),

              // El monto es lo primero que uno quiere escribir, asi que va
              // grande y con el foco puesto.
              TextField(
                controller: _amount,
                autofocus: !_isEditing,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: _onAmountChanged,
                textAlign: TextAlign.center,
                style: context.texts.displaySmall?.copyWith(
                  color: isExpense ? scheme.error : AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: '\$0',
                  hintStyle: context.texts.displaySmall?.copyWith(
                    color: scheme.outline,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),

              const SizedBox(height: AppConstants.spaceMd),
              TextField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'En que fue (opcional)',
                  prefixIcon: Icon(Icons.edit_note_rounded),
                ),
              ),

              const SizedBox(height: AppConstants.spaceLg),
              const _Label('Categoria'),
              const SizedBox(height: AppConstants.spaceSm),
              _CategoryGrid(
                categories: categories,
                selectedId: _categoryId,
                onSelected: (id) {
                  HapticFeedback.selectionClick();
                  setState(() => _categoryId = id);
                },
              ),

              const SizedBox(height: AppConstants.spaceLg),
              const _Label('Cuenta'),
              const SizedBox(height: AppConstants.spaceSm),
              if (accounts.isEmpty)
                Text(
                  'Todavia no tienes cuentas. Puedes registrar el movimiento '
                  'igual y asignarlo despues.',
                  style: context.texts.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: AppConstants.spaceSm,
                  runSpacing: AppConstants.spaceSm,
                  children: <Widget>[
                    _Pill(
                      label: 'Ninguna',
                      selected: _accountId == null,
                      onTap: () => setState(() => _accountId = null),
                    ),
                    for (final account in accounts)
                      _Pill(
                        label: account.name,
                        selected: _accountId == account.id,
                        onTap: () => setState(() => _accountId = account.id),
                      ),
                  ],
                ),

              const SizedBox(height: AppConstants.spaceLg),
              const _Label('Fecha'),
              const SizedBox(height: AppConstants.spaceSm),
              GestureDetector(
                onTap: _pickDate,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.spaceMd,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    border: Border.all(color: scheme.outlineVariant),
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusMd),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppConstants.spaceSm),
                      Text(
                        DateNames.relativeDay(_date).capitalized,
                        style: context.texts.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.spaceMd),
              TextField(
                controller: _notes,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Notas (opcional)',
                ),
              ),

              const SizedBox(height: AppConstants.spaceXl),
              FilledButton(
                onPressed: _save,
                child: Text(_isEditing ? 'Guardar cambios' : 'Registrar'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KindSelector extends StatelessWidget {
  const _KindSelector({required this.value, required this.onChanged});

  final CategoryKind value;
  final ValueChanged<CategoryKind> onChanged;

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
          for (final kind in CategoryKind.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(kind),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: AppConstants.durationFast,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: kind == value
                        ? (kind == CategoryKind.expense
                            ? scheme.error.withValues(alpha: 0.18)
                            : AppColors.success.withValues(alpha: 0.18))
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(AppConstants.radiusFull),
                  ),
                  child: Text(
                    kind == CategoryKind.expense ? 'Gasto' : 'Ingreso',
                    textAlign: TextAlign.center,
                    style: context.texts.labelLarge?.copyWith(
                      color: kind != value
                          ? scheme.onSurfaceVariant
                          : kind == CategoryKind.expense
                              ? scheme.error
                              : AppColors.success,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Cuadricula de categorias con su icono y su color.
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<FinanceCategory> categories;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppConstants.spaceSm,
      runSpacing: AppConstants.spaceSm,
      children: <Widget>[
        for (final category in categories)
          _CategoryChip(
            category: category,
            selected: category.id == selectedId,
            onTap: () => onSelected(category.id),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final FinanceCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final color = AppColors.categoryAccent(category.colorIndex);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppConstants.durationFast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : scheme.surfaceContainer,
          border: Border.all(
            color: selected ? color : scheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              CategoryIcons.resolve(category.iconName),
              size: 17,
              color: selected ? color : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 7),
            Text(
              category.name,
              style: context.texts.labelLarge?.copyWith(
                fontSize: 13,
                color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
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

class _Label extends StatelessWidget {
  const _Label(this.text);

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
