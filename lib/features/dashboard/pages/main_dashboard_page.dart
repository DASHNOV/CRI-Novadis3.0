import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/core/config/app_router.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';
import 'package:novadis_cri/features/dashboard/config/chart_config.dart';
import 'package:novadis_cri/features/dashboard/widgets/kpi_card_widget.dart';
import 'package:novadis_cri/features/dashboard/widgets/time_evolution_chart_widget.dart';
import 'package:novadis_cri/features/dashboard/widgets/type_distribution_chart_widget.dart';
import 'package:novadis_cri/features/dashboard/widgets/top_sites_list_widget.dart';
import 'package:novadis_cri/features/dashboard/widgets/dashboard_common_widgets.dart';

/// Page principale du Dashboard avec KPIs et graphiques
class MainDashboardPage extends ConsumerStatefulWidget {
  const MainDashboardPage({super.key});

  @override
  ConsumerState<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends ConsumerState<MainDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final dashboardDataAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord'),
        actions: [
          // Bouton statistiques techniciens (admin/manager)
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => context.push(AppRouter.technicianStats),
            tooltip: 'Statistiques Techniciens',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go(AppRouter.login),
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.refreshDashboard();
          // Attendre que les nouvelles données soient chargées
          await ref.read(dashboardDataProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec période
              dashboardDataAsync.when(
                data: (data) => DashboardHeaderWidget(
                  title: 'Vue d\'ensemble',
                  subtitle: 'Activité des interventions techniques',
                  lastUpdated: data.lastUpdated,
                  onRefresh: () => ref.refreshDashboard(),
                ),
                loading: () => const DashboardHeaderWidget(
                  title: 'Vue d\'ensemble',
                  subtitle: 'Chargement...',
                ),
                error: (error, stack) => const DashboardHeaderWidget(
                  title: 'Vue d\'ensemble',
                  subtitle: 'Erreur de chargement',
                ),
              ),

              const SizedBox(height: 16),

              // Filtre de période
              PeriodFilterWidget(
                selectedPeriod: selectedPeriod,
                onPeriodChanged: (period) {
                  ref.read(selectedPeriodProvider.notifier).setPeriod(period);
                },
              ),

              const SizedBox(height: 24),

              // KPI Cards
              _buildKpiSection(dashboardDataAsync),

              const SizedBox(height: 24),

              // Graphique d'évolution temporelle
              dashboardDataAsync.when(
                data: (data) => TimeEvolutionChartWidget(
                  data: data.timeEvolution,
                  title: 'Évolution des 6 derniers mois',
                  subtitle: 'Nombre d\'interventions par mois',
                ),
                loading: () => _buildChartSkeleton('Évolution temporelle'),
                error: (error, _) =>
                    _buildErrorCard('Graphique d\'évolution', error),
              ),

              const SizedBox(height: 16),

              // Graphique de distribution par type
              dashboardDataAsync.when(
                data: (data) => TypeDistributionChartWidget(
                  data: data.typeDistribution,
                  title: 'Distribution par Type (Top 5)',
                  subtitle: 'Types d\'interventions les plus fréquents',
                ),
                loading: () => _buildChartSkeleton('Distribution par type'),
                error: (error, _) =>
                    _buildErrorCard('Graphique de distribution', error),
              ),

              const SizedBox(height: 16),

              // Top 5 Sites
              dashboardDataAsync.when(
                data: (data) => TopSitesListWidget(
                  sites: data.topSites,
                  title: 'Top 5 Sites',
                  subtitle: 'Sites les plus visités sur la période',
                  onSiteTap: (site) {
                    context.push('${AppRouter.siteDetails}/${site.siteId}');
                  },
                ),
                loading: () =>
                    const TopSitesListWidget(sites: [], isLoading: true),
                error: (error, _) => _buildErrorCard('Top Sites', error),
              ),

              const SizedBox(height: 24),

              // Actions rapides
              _buildQuickActions(context),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiSection(AsyncValue<DashboardData> dataAsync) {
    return dataAsync.when(
      data: (data) => KpiGrid(
        cards: [
          KpiCard(
            title: 'Interventions',
            value: '🔧 ${data.kpis.totalInterventions}',
            subtitle: 'Total sur la période',
            icon: Icons.engineering,
            iconColor: ChartConfig.kpiColors['interventions']!,
          ),
          KpiCard(
            title: 'Sites Actifs',
            value: '🏢 ${data.kpis.activeSites}',
            subtitle: 'Sites distincts visités',
            icon: Icons.business,
            iconColor: ChartConfig.kpiColors['sites']!,
          ),
          KpiCard(
            title: 'Durée Moyenne',
            value: '🕒 ${data.kpis.formattedAverageDuration}',
            subtitle: 'Par intervention',
            icon: Icons.access_time,
            iconColor: ChartConfig.kpiColors['duration']!,
          ),
          KpiCard(
            title: 'Taux Complétion',
            value: '✅ ${data.kpis.completionRate.toStringAsFixed(1)}%',
            subtitle: 'Interventions terminées',
            icon: Icons.check_circle,
            iconColor: ChartConfig.kpiColors['completion']!,
            trendValue: data.kpis.completionRateTrend,
            trendPositive: data.kpis.completionRateTrend != null
                ? data.kpis.completionRateTrend! > 0
                : null,
          ),
        ],
      ),
      loading: () => KpiGrid(
        cards: List.generate(
          4,
          (_) => const KpiCard(
            title: '',
            value: '',
            icon: Icons.hourglass_empty,
            iconColor: Colors.grey,
            isLoading: true,
          ),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text('Erreur: $error'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.refreshDashboard(),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartSkeleton(String title) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 150,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String title, Object error) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 40),
            const SizedBox(height: 8),
            Text(
              'Erreur: $title',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              error.toString(),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.refreshDashboard(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions Rapides',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.add_circle_outline,
                    label: 'Nouveau CRI',
                    color: Colors.green,
                    onTap: () => context.push(AppRouter.criForm),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.history,
                    label: 'Historique',
                    color: Colors.blue,
                    onTap: () => context.push(AppRouter.history),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.analytics_outlined,
                    label: 'Stats Tech.',
                    color: Colors.purple,
                    onTap: () => context.push(AppRouter.technicianStats),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
