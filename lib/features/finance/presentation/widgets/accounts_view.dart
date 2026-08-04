import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/account.dart';
import '../../../../models/agenda_entry.dart' show newEntryId;
import '../../../../models/money.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/category_icons.dart';
import '../../../../utils/extensions.dart';
import '../../../../widgets/fade_in.dart';
import '../providers/finance_providers.dart';

/// Cuentas y el total que suman.
class AccountsView extends ConsumerWidget {
  const AccountsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final total = ref.watch(totalBalanceProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceMd,
        AppConstants.spaceXs,
        AppConstants.spaceMd,
        AppConstants.spaceXxl * 2,
      ),
      children: <Widget>[
        FadeIn(child: _TotalCard(total: total, count: accounts.length)),
        const SizedBox(height: AppConstants.spaceLg),
        if (accounts.isEmpty)
          const _EmptyAccounts()
        else
          for (var i = 0; i < accounts.length; i++)
            FadeIn(
              delay: Duration(milliseconds: 50 * i.clamp(0, 6)),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.spaceSm),
                child: _AccountTile(account: accounts[i]),
              ),
            ),
        const SizedBox(height: AppConstants.spaceSm),
        OutlinedButton.icon(
          onPressed: () => showAccountEditor(context),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Agregar cuenta'),
        ),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.total, required this.count});

  final int total;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceLg,
        vertical: AppConstants.spaceLg,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.primary.withValues(alpha: 0.16),
            scheme.primary.withValues(alpha: 0.04),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'TOTAL EN CUENTAS',
            style: context.texts.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppConstants.spaceSm),
          Text(
            Money.format(total),
            style: context.texts.displaySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: total < 0 ? scheme.error : scheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            count == 1 ? '1 cuenta' : '$count cuentas',
            style: context.texts.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final color = AppColors.blockAccent(account.colorIndex);

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppConstants.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showAccountEditor(context, existing: account),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.spaceMd),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSm),
                ),
                child: Icon(
                  CategoryIcons.resolve(account.kind.iconName),
                  size: 20,
                  color: color,
                ),
              ),
              const SizedBox(width: AppConstants.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(account.name, style: context.texts.titleMedium),
                    Text(
                      account.includeInTotal
                          ? account.kind.label
                          : '${account.kind.label} · fuera del total',
                      style: context.texts.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                Money.format(account.balance),
                style: context.texts.titleMedium?.copyWith(
                  color: account.balance < 0
                      ? scheme.error
                      : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyAccounts extends StatelessWidget {
  const _EmptyAccounts();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceXl),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 44,
            color: scheme.outline,
          ),
          const SizedBox(height: AppConstants.spaceMd),
          Text('Sin cuentas todavia', style: context.texts.titleMedium),
          const SizedBox(height: AppConstants.spaceXs),
          Text(
            'Agrega tus cuentas con el saldo que tienen hoy.\n'
            'Los movimientos que registres las van ajustando solas.',
            textAlign: TextAlign.center,
            style: context.texts.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Editor de una cuenta.
Future<void> showAccountEditor(BuildContext context, {Account? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // Sobre el navegador raiz: si se abre en el del area, la barra flotante
    // de abajo queda dibujada encima y tapa el boton de guardar.
    useRootNavigator: true,
    builder: (_) => _AccountEditorSheet(existing: existing),
  );
}

class _AccountEditorSheet extends ConsumerStatefulWidget {
  const _AccountEditorSheet({this.existing});

  final Account? existing;

  @override
  ConsumerState<_AccountEditorSheet> createState() =>
      _AccountEditorSheetState();
}

class _AccountEditorSheetState extends ConsumerState<_AccountEditorSheet> {
  late TextEditingController _name;
  late TextEditingController _balance;
  late AccountKind _kind;
  late int _colorIndex;
  late bool _includeInTotal;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _name = TextEditingController(text: existing?.name ?? '');
    _balance = TextEditingController(
      text: existing == null ? '' : Money.format(existing.balance),
    );
    _kind = existing?.kind ?? AccountKind.bank;
    _colorIndex = existing?.colorIndex ?? 0;
    _includeInTotal = existing?.includeInTotal ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  void _onBalanceChanged(String raw) {
    final value = Money.parse(raw);
    final formatted = value == null ? '' : Money.format(value);
    if (formatted == _balance.text) return;

    _balance.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      context.showError('Ponle un nombre a la cuenta.');
      return;
    }

    final existing = widget.existing;
    final account = Account(
      id: existing?.id ?? newEntryId(),
      name: name,
      balance: Money.parse(_balance.text) ?? 0,
      kind: _kind,
      colorIndex: _colorIndex,
      includeInTotal: _includeInTotal,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    await ref.read(accountsProvider.notifier).upsert(account);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;

    await ref.read(accountsProvider.notifier).remove(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
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
                      _isEditing ? 'Editar cuenta' : 'Nueva cuenta',
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
              const SizedBox(height: AppConstants.spaceLg),

              TextField(
                controller: _name,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Nombre de la cuenta',
                  prefixIcon: Icon(Icons.account_balance_rounded),
                ),
              ),
              const SizedBox(height: AppConstants.spaceMd),

              TextField(
                controller: _balance,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.-]')),
                ],
                onChanged: _onBalanceChanged,
                style: context.texts.headlineSmall,
                decoration: const InputDecoration(
                  hintText: '\$0',
                  labelText: 'Saldo actual',
                ),
              ),

              const SizedBox(height: AppConstants.spaceLg),
              Text(
                'TIPO',
                style: context.texts.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: AppConstants.spaceSm),
              Wrap(
                spacing: AppConstants.spaceSm,
                runSpacing: AppConstants.spaceSm,
                children: <Widget>[
                  for (final kind in AccountKind.values)
                    GestureDetector(
                      onTap: () => setState(() => _kind = kind),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: AppConstants.durationFast,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: kind == _kind
                              ? scheme.primary.withValues(alpha: 0.16)
                              : scheme.surfaceContainer,
                          border: Border.all(
                            color: kind == _kind
                                ? scheme.primary
                                : scheme.outlineVariant,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppConstants.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              CategoryIcons.resolve(kind.iconName),
                              size: 17,
                              color: kind == _kind
                                  ? scheme.primary
                                  : scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              kind.label,
                              style: context.texts.labelLarge?.copyWith(
                                fontSize: 13,
                                color: kind == _kind
                                    ? scheme.onSurface
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppConstants.spaceLg),
              Text(
                'COLOR',
                style: context.texts.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: AppConstants.spaceSm),
              Row(
                children: <Widget>[
                  for (var i = 0; i < AppColors.blockAccents.length; i++)
                    Padding(
                      padding:
                          const EdgeInsets.only(right: AppConstants.spaceSm),
                      child: GestureDetector(
                        onTap: () => setState(() => _colorIndex = i),
                        child: AnimatedContainer(
                          duration: AppConstants.durationFast,
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.blockAccents[i],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: i == _colorIndex
                                  ? scheme.onSurface
                                  : Colors.transparent,
                              width: 2.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppConstants.spaceMd),
              SwitchListTile(
                value: _includeInTotal,
                onChanged: (value) => setState(() => _includeInTotal = value),
                contentPadding: EdgeInsets.zero,
                title: const Text('Sumar al total'),
                subtitle: Text(
                  'Desactivalo para cuentas compartidas o de terceros.',
                  style: context.texts.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.spaceLg),
              FilledButton(
                onPressed: _save,
                child: Text(_isEditing ? 'Guardar cambios' : 'Crear cuenta'),
              ),
            ],
          );
        },
      ),
    );
  }
}
