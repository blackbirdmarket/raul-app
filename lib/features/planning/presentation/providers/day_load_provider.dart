import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/agenda_entry.dart';
import 'agenda_providers.dart';

/// Resumen de carga de un dia: cuantas entradas hay y cuantas estan
/// completadas. Lo usan la tira de semana y el header del dia para mostrar
/// el estado de un vistazo sin tener que recorrer la lista entera.
class DayLoad {
  const DayLoad({required this.total, required this.done});

  /// Dia sin nada planificado.
  const DayLoad.empty()
      : total = 0,
        done = 0;

  final int total;
  final int done;

  bool get isEmpty => total == 0;
  bool get isComplete => total > 0 && done == total;

  @override
  bool operator ==(Object other) =>
      other is DayLoad && other.total == total && other.done == done;

  @override
  int get hashCode => Object.hash(total, done);
}

/// Carga de un dia concreto, derivada de la agenda en memoria.
///
/// Es un Provider.family para que cada celda de la tira pida solo su dia
/// y Riverpod no reconstruya todas las celdas cuando cambia un dia distinto.
final dayLoadProvider =
    Provider.family<DayLoad, DateTime>((ref, day) {
  final entries = ref.watch(entriesForDayProvider(day));

  if (entries.isEmpty) return const DayLoad.empty();

  var done = 0;
  for (final entry in entries) {
    if (entry.isComplete) done++;
  }

  return DayLoad(total: entries.length, done: done);
});
