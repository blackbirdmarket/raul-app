import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../models/journal_entry.dart';
import '../../../../models/mood_entry.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/calendar.dart';
import '../../../../utils/date_format.dart';
import '../../../../utils/extensions.dart';
import '../../../../widgets/add_button.dart';
import '../../../../widgets/fade_in.dart';
import '../providers/mindfulness_providers.dart';
import '../widgets/journal_editor_page.dart';

/// El cuaderno.
///
/// Un solo tipo de escrito: decretos, manifestaciones, gratitud o lo que sea,
/// todo es texto. Poner categorias obligaria a decidir de que tipo es antes de
/// escribir, y esa decision es la friccion que hace que uno no escriba.
///
/// Arriba, el animo del dia. No es una funcion aparte: al releer un escrito de
/// hace tres meses, saber como estaba ese dia es la mitad del sentido.
class JournalPage extends ConsumerWidget {
  const JournalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(visibleJournalProvider);
    final query = ref.watch(journalQueryProvider);
    final summary = ref.watch(journalSummaryProvider);
    final searching = query.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.spaceMd,
                AppConstants.spaceSm,
                AppConstants.spaceMd,
                AppConstants.spaceSm,
              ),
              child: Row(
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'DIARIO',
                        style: context.texts.labelSmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                          fontSize: 10,
                          letterSpacing: 1.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        summary.entries == 0
                            ? 'Tu cuaderno'
                            : '${summary.entries} '
                                '${summary.entries == 1 ? "escrito" : "escritos"}',
                        style: context.texts.titleLarge,
                      ),
                    ],
                  ),
                  const Spacer(),
                  AddButton(
                    onPressed: () => showJournalEditor(context),
                    tooltip: 'Escribir',
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spaceMd,
                  0,
                  AppConstants.spaceMd,
                  AppConstants.spaceXxl * 2,
                ),
                children: <Widget>[
                  const FadeIn(child: _MoodStrip()),
                  const SizedBox(height: AppConstants.spaceMd),

                  if (summary.entries > 2) ...<Widget>[
                    const _SearchField(),
                    const SizedBox(height: AppConstants.spaceMd),
                  ],

                  if (entries.isEmpty)
                    _Empty(searching: searching)
                  else
                    for (var i = 0; i < entries.length; i++)
                      FadeIn(
                        delay: Duration(milliseconds: 35 * i.clamp(0, 8)),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: AppConstants.spaceSm,
                          ),
                          child: _EntryCard(entry: entries[i]),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Como estas hoy, en un toque.
///
/// Se registra desde la propia fila y no detras de un boton: si costara dos
/// toques mas, a la semana nadie lo haria.
class _MoodStrip extends ConsumerWidget {
  const _MoodStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colors;
    final today = ref.watch(todayMoodProvider);

    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? const Color(0xFF0E0E16).withValues(alpha: 0.6)
            : scheme.surfaceContainerLowest.withValues(alpha: 0.88),
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppConstants.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                today == null ? 'Como estas hoy' : 'Hoy',
                style: context.texts.titleSmall,
              ),
              const Spacer(),
              if (today != null)
                Text(
                  today.level.label,
                  style: context.texts.labelMedium?.copyWith(
                    color: AppColors.blockAccent(today.level.colorIndex),
                    letterSpacing: 0,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppConstants.spaceSm + 2),
          Row(
            children: <Widget>[
              for (final level in MoodLevel.values)
                Expanded(
                  child: _MoodOption(
                    level: level,
                    selected: today?.level == level,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(moodsProvider.notifier).record(
                            MoodEntry(day: Calendar.today(), level: level),
                          );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodOption extends StatelessWidget {
  const _MoodOption({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final MoodLevel level;
  final bool selected;
  final VoidCallback onTap;

  /// La cara se dibuja con iconos del sistema y no con emojis: los emojis
  /// cambian de estilo en cada telefono y romperian la coherencia visual.
  IconData get _icon => switch (level) {
        MoodLevel.awful => Icons.sentiment_very_dissatisfied_rounded,
        MoodLevel.bad => Icons.sentiment_dissatisfied_rounded,
        MoodLevel.ok => Icons.sentiment_neutral_rounded,
        MoodLevel.good => Icons.sentiment_satisfied_rounded,
        MoodLevel.great => Icons.sentiment_very_satisfied_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final color = AppColors.blockAccent(level.colorIndex);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: AnimatedContainer(
          duration: AppConstants.durationFast,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.2)
                : scheme.surfaceContainer.withValues(alpha: 0.5),
            border: Border.all(
              color: selected ? color : scheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          child: Icon(
            _icon,
            size: 24,
            color: selected ? color : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(journalQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final query = ref.watch(journalQueryProvider);

    return TextField(
      controller: _controller,
      onChanged: ref.read(journalQueryProvider.notifier).set,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar en tus escritos',
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: scheme.onSurfaceVariant,
        ),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _controller.clear();
                  ref.read(journalQueryProvider.notifier).clear();
                },
                icon: const Icon(Icons.close_rounded, size: 18),
                color: scheme.onSurfaceVariant,
              ),
        isDense: true,
      ),
    );
  }
}

/// Un escrito en la lista.
class _EntryCard extends ConsumerWidget {
  const _EntryCard({required this.entry});

  final JournalEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.colors;
    final radius = BorderRadius.circular(AppConstants.radiusLg);
    final preview = entry.preview;

    return Material(
      color: context.isDarkMode
          ? const Color(0xFF0E0E16).withValues(alpha: 0.6)
          : scheme.surfaceContainerLowest.withValues(alpha: 0.88),
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showJournalEditor(context, existing: entry),
        onLongPress: () {
          HapticFeedback.mediumImpact();
          ref.read(journalProvider.notifier).togglePinned(entry.id);
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: entry.pinned
                  ? scheme.primary.withValues(alpha: 0.4)
                  : scheme.outlineVariant,
            ),
          ),
          padding: const EdgeInsets.all(AppConstants.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      entry.heading,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.titleSmall,
                    ),
                  ),
                  if (entry.pinned) ...<Widget>[
                    const SizedBox(width: AppConstants.spaceSm),
                    Icon(
                      Icons.push_pin_rounded,
                      size: 15,
                      color: scheme.primary,
                    ),
                  ],
                ],
              ),
              if (preview.isNotEmpty) ...<Widget>[
                const SizedBox(height: 5),
                Text(
                  preview,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: AppConstants.spaceSm + 2),
              Row(
                children: <Widget>[
                  Text(
                    DateNames.relativeDay(entry.createdAt).capitalized,
                    style: context.texts.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${entry.wordCount} '
                    '${entry.wordCount == 1 ? "palabra" : "palabras"}',
                    style: context.texts.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceXxl),
      child: Column(
        children: <Widget>[
          Icon(
            searching
                ? Icons.search_off_rounded
                : Icons.auto_stories_outlined,
            size: 40,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppConstants.spaceMd),
          Text(
            searching ? 'Sin resultados' : 'El cuaderno esta vacio',
            style: context.texts.titleMedium,
          ),
          const SizedBox(height: AppConstants.spaceXs),
          Text(
            searching
                ? 'Prueba con otra palabra.'
                : 'Decretos, manifestaciones, lo que agradeces, lo que te '
                    'pesa. Todo va aqui, sin formato.',
            textAlign: TextAlign.center,
            style: context.texts.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
