import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:novadis_cri/core/providers/main_nav_provider.dart';
import 'package:novadis_cri/core/widgets/responsive_scaffold.dart';
import 'package:novadis_cri/screens/technician/personal_home_screen.dart';
import 'package:novadis_cri/features/cri_form/cri_form_screen.dart';
import 'package:novadis_cri/screens/admin/global_dashboard_screen.dart';
import 'package:novadis_cri/screens/admin/global_history_screen.dart';
import 'package:novadis_cri/features/admin/admin_screen.dart';
import 'package:novadis_cri/features/documents/pages/documents_page.dart';

/// Écran principal pour les administrateurs
class AdminMainScreen extends ConsumerStatefulWidget {
  const AdminMainScreen({super.key});

  @override
  ConsumerState<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends ConsumerState<AdminMainScreen> {
  int _currentIndex = 2; // Vue Globale par défaut pour l'admin

  final List<Widget> _screens = const [
    PersonalHomeScreen(),
    CriFormScreen(),
    GlobalDashboardScreen(),
    GlobalHistoryScreen(),
    DocumentsPage(),
    AdminScreen(),
  ];

  static const List<NavDestination> _destinations = [
    NavDestination(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Accueil',
    ),
    NavDestination(
      icon: Icon(Icons.add_circle_outline),
      activeIcon: Icon(Icons.add_circle),
      label: 'Nouveau CRI',
    ),
    NavDestination(
      icon: Icon(Icons.dashboard_outlined),
      activeIcon: Icon(Icons.dashboard),
      label: 'Vue Globale',
    ),
    NavDestination(
      icon: Icon(Icons.list_alt_outlined),
      activeIcon: Icon(Icons.list_alt),
      label: 'Tous les CRI',
    ),
    NavDestination(
      icon: Icon(Icons.folder_outlined),
      activeIcon: Icon(Icons.folder),
      label: 'Documents',
    ),
    NavDestination(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings),
      label: 'Paramètres',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(requestedMainTabProvider, (previous, next) {
      if (next == null) return;
      final index = _destinations.indexWhere((d) => d.label == next);
      if (index != -1 && index != _currentIndex) {
        setState(() => _currentIndex = index);
      }
      ref.read(requestedMainTabProvider.notifier).state = null;
    });

    return ResponsiveScaffold(
      currentIndex: _currentIndex,
      onIndexChanged: (index) => setState(() => _currentIndex = index),
      destinations: _destinations,
      screens: _screens,
    );
  }
}
