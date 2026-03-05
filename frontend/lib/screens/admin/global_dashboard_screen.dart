import 'package:flutter/material.dart';
import 'package:novadis_cri/features/dashboard/pages/main_dashboard_page.dart';

/// Dashboard global - Vue d'ensemble admin avec statistiques et graphiques
/// Redirige vers la nouvelle implémentation MainDashboardPage
class GlobalDashboardScreen extends StatelessWidget {
  const GlobalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainDashboardPage();
  }
}
