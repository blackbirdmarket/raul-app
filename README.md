# Ruli OS

Planificacion personal para Android. El dia se ve en un riel de horas; la agenda
mira hacia adelante, semanas o meses.

## Que hay dentro

Dos tipos de elemento, y esa distincion es la idea central de la aplicacion:

- **Tarea rapida**: se hace de una y se marca con un check. "Tomar pastilla".
- **Bloque de tiempo**: ocupa un tramo y se descompone en pasos. "Ordenar casa"
  con cocina, bano y dormitorio dentro. El bloque no se marca a mano: se
  completa solo cuando sus pasos estan listos.

Cada elemento, y cada paso dentro de un bloque, elige como avisa: sin aviso,
notificacion normal o alarma.

## Pantallas

- **Hoy**: riel de horas con los bloques dimensionados segun cuanto duran, las
  tareas como pildoras, la hora actual marcada y los solapamientos repartidos
  en carriles. Tocar un hueco crea algo a esa hora.
- **Agenda**: todo lo que viene, agrupado por dia, para planificar con
  anticipacion.
- **Ajustes**: tema, datos y restablecer.

## Estructura

```
lib/
  core/        configuracion, constantes, errores, resultado, router
  features/
    planning/  agenda: datos, providers, pantallas y widgets
    settings/  ajustes
  widgets/     componentes reutilizables (checks, anillos, tarjetas)
  services/    preferencias, almacenamiento, logging
  models/      tarea, bloque, subtarea, modo de aviso
  database/    inicializacion y cajas de Hive
  theme/       colores, tipografia, temas, modo oscuro
  utils/       fechas en espanol, extensiones, validadores, responsive
  main.dart
```

## Como generar la carpeta android

El proyecto se escribio sin ejecutar `flutter create`, asi que `android/` se
genera aparte y se copia. Lo hace solo el workflow de GitHub Actions.

## Como correr y compilar

```
flutter pub get
flutter run
flutter build apk --release --split-per-abi
```

## Pendiente

Las alarmas y notificaciones del sistema. El tipo de aviso ya se elige y se
guarda por elemento; falta programarlas contra Android, lo que obliga a tocar
permisos y configuracion de Gradle.
