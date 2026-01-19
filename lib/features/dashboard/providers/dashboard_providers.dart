import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';
import 'package:novadis_cri/features/dashboard/repositories/dashboard_repository.dart';

/// Provider pour le repository dashboard
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

/// Provider pour la période sélectionnée
final selectedPeriodProvider =
    StateNotifierProvider<SelectedPeriodNotifier, DashboardPeriod>((ref) {
      return SelectedPeriodNotifier();
    });

/// Notifier pour la période sélectionnée avec persistence
class SelectedPeriodNotifier extends StateNotifier<DashboardPeriod> {
  SelectedPeriodNotifier() : super(DashboardPeriod.month) {
    _loadSavedPeriod();
  }

  Future<void> _loadSavedPeriod() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPeriod = prefs.getString('dashboard_period');
      if (savedPeriod != null) {
        state = DashboardPeriod.values.firstWhere(
          (p) => p.name == savedPeriod,
          orElse: () => DashboardPeriod.month,
        );
      }
    } catch (e) {
      // Ignore si erreur de chargement
    }
  }

  Future<void> setPeriod(DashboardPeriod period) async {
    state = period;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dashboard_period', period.name);
    } catch (e) {
      // Ignore si erreur de sauvegarde
    }
  }
}

/// Provider pour les données du dashboard
final dashboardDataProvider = FutureProvider.autoDispose<DashboardData>((
  ref,
) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  final period = ref.watch(selectedPeriodProvider);

  return repository.getDashboardData(period);
});

/// Provider pour les KPIs uniquement
final dashboardKpisProvider = FutureProvider.autoDispose<DashboardKpis>((
  ref,
) async {
  final data = await ref.watch(dashboardDataProvider.future);
  return data.kpis;
});

/// Provider pour l'évolution temporelle
final timeEvolutionProvider =
    FutureProvider.autoDispose<List<TimeEvolutionData>>((ref) async {
      final data = await ref.watch(dashboardDataProvider.future);
      return data.timeEvolution;
    });

/// Provider pour la distribution par type
final typeDistributionProvider =
    FutureProvider.autoDispose<List<TypeDistributionData>>((ref) async {
      final data = await ref.watch(dashboardDataProvider.future);
      return data.typeDistribution;
    });

/// Provider pour le top sites
final topSitesProvider = FutureProvider.autoDispose<List<TopSiteData>>((
  ref,
) async {
  final data = await ref.watch(dashboardDataProvider.future);
  return data.topSites;
});

/// Provider pour la liste des techniciens
final techniciansListProvider =
    FutureProvider.autoDispose<List<TechnicianModel>>((ref) async {
      final repository = ref.watch(dashboardRepositoryProvider);
      return repository.getTechnicians();
    });

/// Provider pour le technicien sélectionné
final selectedTechnicianProvider = StateProvider<TechnicianModel?>(
  (ref) => null,
);

/// Provider pour les statistiques du technicien sélectionné
final technicianStatsProvider =
    FutureProvider.autoDispose<TechnicianStatsData?>((ref) async {
      final repository = ref.watch(dashboardRepositoryProvider);
      final technician = ref.watch(selectedTechnicianProvider);
      final period = ref.watch(selectedPeriodProvider);

      if (technician == null) return null;

      return repository.getTechnicianStats(technician.name, period);
    });

/// Provider pour les détails d'un site
final siteDetailsProvider = FutureProvider.autoDispose
    .family<SiteDetailsData, String>((ref, siteId) async {
      final repository = ref.watch(dashboardRepositoryProvider);
      return repository.getSiteDetails(siteId);
    });

/// Provider pour forcer le rafraîchissement
final dashboardRefreshProvider = StateProvider<int>((ref) => 0);

/// Extension pour rafraîchir les données
extension DashboardRefresh on WidgetRef {
  void refreshDashboard() {
    final repository = read(dashboardRepositoryProvider);
    repository.clearCache();
    invalidate(dashboardDataProvider);
    read(dashboardRefreshProvider.notifier).state++;
  }
}
