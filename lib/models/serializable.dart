/// Contrato que cumple todo modelo que se guarda o se envia.
///
/// Se define como interfaz y no como clase base para no imponer herencia:
/// un modelo puede implementar esto y aun asi extender lo que necesite.
abstract interface class Serializable {
  /// Representacion apta para guardar en Hive o enviar como JSON.
  Map<String, dynamic> toMap();
}

/// Firma de una funcion que reconstruye un modelo desde su mapa.
///
/// Permite escribir helpers genericos de lectura sin que estos tengan que
/// conocer cada tipo concreto.
typedef ModelFactory<T> = T Function(Map<String, dynamic> map);
