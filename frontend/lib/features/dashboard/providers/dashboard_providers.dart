import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';
import 'package:novadis_cri/features/dashboard/repositories/dashboard_repository.dart';
import 'package:novadis_cri/data/repositories/cri_remote_repository.dart';
import 'package:novadis_cri/data/local/app_database.dart';
import 'package:novadis_cri/services/stats_api_service.dart';
import 'package:novadis_cri/models/global_stats.dart';
import 'package:novadis_cri/models/site_stats.dart';
import 'package:novadis_cri/models/technician_detailed_stats.dart';
import 'package:novadis_cri/models/distribution_stats.dart';

/// Provider pour le repository dashboard
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(
    ref.read(criRemoteRepositoryProvider),
    ref.read(appDatabaseProvider),
  );
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

/// Provider pour la charge de travail des techniciens
final technicianWorkloadProvider =
    FutureProvider.autoDispose<List<TechnicianWorkloadData>>((ref) async {
      final data = await ref.watch(dashboardDataProvider.future);
      return data.technicianWorkload;
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

/// Mode de vue du dashboard
enum DashboardViewMode { general, parSite, parTechnicien }

/// Provider pour le mode de vue
final dashboardViewModeProvider = StateProvider<DashboardViewMode>(
  (ref) => DashboardViewMode.general,
);

// ──────────────────────────────────────────────────
// Providers API Admin (données serveur, pas calcul local)
// ──────────────────────────────────────────────────

/// Convertit une DashboardPeriod en nombre de jours pour l'API
int? _periodToDays(DashboardPeriod period) {
  return period.days;
}

/// Stats globales depuis l'API backend (avec filtre période)
final adminGlobalStatsProvider =
    FutureProvider.autoDispose<GlobalStats>((ref) async {
  final api = ref.watch(statsApiServiceProvider);
  final period = ref.watch(selectedPeriodProvider);
  return api.getGlobalStats(periodDays: _periodToDays(period));
});

/// Stats par site depuis l'API backend
final adminSiteStatsProvider =
    FutureProvider.autoDispose<List<SiteStats>>((ref) async {
  final api = ref.watch(statsApiServiceProvider);
  final period = ref.watch(selectedPeriodProvider);
  return api.getStatsBySite(periodDays: _periodToDays(period));
});

/// Stats par technicien depuis l'API backend
final adminTechnicianStatsProvider =
    FutureProvider.autoDispose<List<TechnicianDetailedStats>>((ref) async {
  final api = ref.watch(statsApiServiceProvider);
  final period = ref.watch(selectedPeriodProvider);
  return api.getStatsByTechnician(periodDays: _periodToDays(period));
});

/// Stats de distribution depuis l'API backend
final adminDistributionStatsProvider =
    FutureProvider.autoDispose<DistributionStats>((ref) async {
  final api = ref.watch(statsApiServiceProvider);
  final period = ref.watch(selectedPeriodProvider);
  return api.getDistributionStats(periodDays: _periodToDays(period));
});

/// Extension pour faciliter le rafraîchissement des données
extension DashboardRefX on WidgetRef {
  void refreshDashboard() {
    read(dashboardRepositoryProvider).clearCache();
    invalidate(dashboardDataProvider);
    invalidate(adminGlobalStatsProvider);
    invalidate(adminSiteStatsProvider);
    invalidate(adminTechnicianStatsProvider);
    invalidate(adminDistributionStatsProvider);
  }
}
