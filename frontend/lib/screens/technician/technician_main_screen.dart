import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:novadis_cri/core/providers/main_nav_provider.dart';
import 'package:novadis_cri/core/widgets/responsive_scaffold.dart';
import 'package:novadis_cri/screens/technician/personal_home_screen.dart';
import 'package:novadis_cri/features/cri_form/cri_form_screen.dart';
import 'package:novadis_cri/screens/technician/personal_history_screen.dart';
import 'package:novadis_cri/screens/technician/profile_screen.dart';
import 'package:novadis_cri/features/documents/pages/documents_page.dart';

/// Écran principal pour les techniciens
class TechnicianMainScreen extends ConsumerStatefulWidget {
  const TechnicianMainScreen({super.key});

  @override
  ConsumerState<TechnicianMainScreen> createState() =>
      _TechnicianMainScreenState();
}

class _TechnicianMainScreenState extends ConsumerState<TechnicianMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PersonalHomeScreen(),
    CriFormScreen(),
    PersonalHistoryScreen(),
    DocumentsPage(),
    ProfileScreen(),
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
      icon: Icon(Icons.history_outlined),
      activeIcon: Icon(Icons.history),
      label: 'Mes CRI',
    ),
    NavDestination(
      icon: Icon(Icons.folder_outlined),
      activeIcon: Icon(Icons.folder),
      label: 'Documents',
    ),
    NavDestination(
      icon: Icon(Icons.person_outline),
      activeIcon: Icon(Icons.person),
      label: 'Profil',
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
