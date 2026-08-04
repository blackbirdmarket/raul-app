import 'package:flutter/material.dart';

/// Traduce el nombre guardado de un icono al icono real.
///
/// Los modelos guardan texto porque un `IconData` no se puede serializar, y
/// porque atarlos a la capa visual haria imposible cambiar el set de iconos
/// sin migrar los datos del telefono.
class CategoryIcons {
  const CategoryIcons._();

  static const Map<String, IconData> catalog = <String, IconData>{
    'restaurant': Icons.restaurant_rounded,
    'cart': Icons.shopping_cart_rounded,
    'car': Icons.directions_car_rounded,
    'home': Icons.home_rounded,
    'bolt': Icons.bolt_rounded,
    'health': Icons.favorite_rounded,
    'school': Icons.school_rounded,
    'shirt': Icons.checkroom_rounded,
    'movie': Icons.movie_rounded,
    'sports': Icons.sports_soccer_rounded,
    'pets': Icons.pets_rounded,
    'label': Icons.label_rounded,
    'wallet': Icons.account_balance_wallet_rounded,
    'trending': Icons.trending_up_rounded,
    'gift': Icons.card_giftcard_rounded,
    'coffee': Icons.local_cafe_rounded,
    'phone': Icons.smartphone_rounded,
    'flight': Icons.flight_rounded,
    'tools': Icons.build_rounded,
    'baby': Icons.child_care_rounded,
    'book': Icons.menu_book_rounded,
    'gas': Icons.local_gas_station_rounded,
    'gym': Icons.fitness_center_rounded,
    'bank': Icons.account_balance_rounded,
    'cash': Icons.payments_rounded,
    'card': Icons.credit_card_rounded,
    'savings': Icons.savings_rounded,
  };

  /// Nombres ofrecidos al elegir icono para una categoria propia.
  static List<String> get selectable => catalog.keys
      .where((key) => !<String>['bank', 'cash', 'card', 'savings'].contains(key))
      .toList();

  /// Nunca falla: un nombre desconocido cae en una etiqueta generica en vez de
  /// dejar un hueco en la interfaz.
  static IconData resolve(String name) =>
      catalog[name] ?? Icons.label_rounded;
}
