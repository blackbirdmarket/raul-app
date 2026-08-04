import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hora actual actualizada cada 30 segundos.
///
/// Los bloques de tiempo la usan para saber si estan "en curso" en este
/// momento. Actualizar cada 30 s es suficiente para que el bloque activo
/// cambie de apariencia sin machacar la CPU con un Timer de un segundo.
final nowProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();

  yield* Stream.periodic(
    const Duration(seconds: 30),
    (_) => DateTime.now(),
  );
});
