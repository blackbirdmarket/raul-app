// Punto de entrada unico al servicio de avisos.
//
// La libreria de notificaciones no existe en la web: si se importara sin mas,
// el proyecto dejaria de compilar en el navegador, que es justamente donde se
// revisa el diseno todos los dias. La importacion condicional resuelve eso:
// en el telefono entra la implementacion real y en el navegador una version
// vacia con la misma forma.
//
// El resto de la aplicacion importa solo este archivo y no se entera de nada.
export 'notification_service_stub.dart'
    if (dart.library.io) 'notification_service_native.dart';
