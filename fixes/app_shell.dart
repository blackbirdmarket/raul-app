import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/planning/presentation/providers/agenda_providers.dart';
import '../features/planning/presentation/widgets/entry_editor_sheet.dart';

/// Estructura persistente que envuelve las areas del sistema.
///
/// El FAB de agregar vive aqui para flotar sobre la barra Aurora, justo en
/// la zona de alcance natural del pulgar derecho. Solo aparece en Planning.
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const List<NavigationDestination> _destinations =
      <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.calendar_today_outlined),
      selectedIcon: Icon(Icons.calendar_today_rounded),
      label: 'Planning',
    ),
    NavigationDestination(
      icon: Icon(Icons.account_balance_wallet_outlined),
      selectedIcon: Icon(Icons.account_balance_wallet_rounded),
      label: 'Finanzas',
    ),
    NavigationDestination(
      icon: Icon(Icons.tune_outlined),
      selectedIcon: Icon(Icons.tune_rounded),
      label: 'Ajustes',
    ),
  ];

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlanning = navigationShell.currentIndex == 0;
    final day = isPlanning ? ref.watch(selectedDayProvider) : null;

    return Scaffold(
      body: navigationShell,
      floatingActionButton: isPlanning
          ? FloatingActionButton(
              onPressed: () => showEntryEditor(context, day: day!),
              tooltip: 'Agregar',
              child: const Icon(Icons.add_rounded),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: _destinations,
      ),
    );
  }
}
