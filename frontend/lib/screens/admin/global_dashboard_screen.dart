import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:novadis_cri/features/dashboard/pages/main_dashboard_page.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';

/// Dashboard global - Vue d'ensemble admin avec statistiques et graphiques
/// Redirige vers la nouvelle implémentation MainDashboardPage
class GlobalDashboardScreen extends ConsumerStatefulWidget {
  const GlobalDashboardScreen({super.key});

  @override
  ConsumerState<GlobalDashboardScreen> createState() => _GlobalDashboardScreenState();
}

class _GlobalDashboardScreenState extends ConsumerState<GlobalDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Forcer un rafraîchissement des données au chargement de l'onglet
    Future.microtask(() => ref.refreshDashboard());
  }

  @override
  Widget build(BuildContext context) {
    return const MainDashboardPage();
  }
}
