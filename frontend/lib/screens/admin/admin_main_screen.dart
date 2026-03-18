import 'package:flutter/material.dart';
import 'package:novadis_cri/core/widgets/responsive_scaffold.dart';
import 'package:novadis_cri/screens/technician/personal_home_screen.dart';
import 'package:novadis_cri/features/cri_form/cri_form_screen.dart';
import 'package:novadis_cri/screens/admin/global_dashboard_screen.dart';
import 'package:novadis_cri/screens/admin/global_history_screen.dart';
import 'package:novadis_cri/features/admin/admin_screen.dart';
import 'package:novadis_cri/features/documents/pages/documents_page.dart';

/// Écran principal pour les administrateurs
class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
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
      icon: Icon(Icons.admin_panel_settings_outlined),
      activeIcon: Icon(Icons.admin_panel_settings),
      label: 'Admin',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      currentIndex: _currentIndex,
      onIndexChanged: (index) => setState(() => _currentIndex = index),
      destinations: _destinations,
      screens: _screens,
    );
  }
}
