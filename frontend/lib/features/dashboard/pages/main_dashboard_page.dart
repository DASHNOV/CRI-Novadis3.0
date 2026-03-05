import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/core/config/app_router.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/dashboard/config/chart_config.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';
import 'package:novadis_cri/features/dashboard/widgets/dashboard_common_widgets.dart';
import 'package:novadis_cri/features/dashboard/widgets/intervention_list_item.dart';
import 'package:novadis_cri/features/dashboard/widgets/kpi_card_widget.dart';
import 'package:novadis_cri/features/dashboard/widgets/time_evolution_chart_widget.dart';

import 'package:novadis_cri/features/auth/presentation/providers/user_name_provider.dart';

/// Page principale du Dashboard avec design modernisé
class MainDashboardPage extends ConsumerStatefulWidget {
  const MainDashboardPage({super.key});

  @override
  ConsumerState<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends ConsumerState<MainDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final viewMode = ref.watch(dashboardViewModeProvider);
    final dashboardDataAsync = ref.watch(dashboardDataProvider);
    final userName = ref.watch(userNameProvider);

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // App Bar Custom
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.darkBlue),
                onPressed: () => context.go(AppRouter.home),
              ),
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryBlue,
                    radius: 18,
                    child: const Text(
                      'N',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      color: AppTheme.darkBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: AppTheme.darkBlue),
                  onPressed: () => context.go(AppRouter.login),
                  tooltip: 'Déconnexion',
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),

                  // Header Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName != null && userName.isNotEmpty ? 'Bonjour $userName,' : 'Bonjour,',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vue d\'ensemble',
                        style: TextStyle(
                          color: AppTheme.darkBlue,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Filter Pills (Period)
                      PeriodFilterWidget(
                        selectedPeriod: selectedPeriod,
                        onPeriodChanged: (period) {
                          ref
                              .read(selectedPeriodProvider.notifier)
                              .setPeriod(period);
                        },
                      ),
                      const SizedBox(height: 12),
                      // View Mode Selector
                      _ViewModeSelector(
                        currentMode: viewMode,
                        onModeChanged: (mode) {
                          ref.read(dashboardViewModeProvider.notifier).state =
                              mode;
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // KPI Grid (Common to all views possibly, or adapted)
                  if (viewMode == DashboardViewMode.general)
                    _buildKpiSection(dashboardDataAsync),

                  const SizedBox(height: 24),

                  // Content based on View Mode
                  if (viewMode == DashboardViewMode.general) ...[
                    _buildGeneralView(dashboardDataAsync),
                  ] else if (viewMode == DashboardViewMode.parSite) ...[
                    _buildSitesView(ref),
                  ] else if (viewMode == DashboardViewMode.parTechnicien) ...[
                    _buildTechniciansView(ref),
                  ],

                  const SizedBox(height: 12),
                ]),
              ),
            ),

            // Note: If lists are long, they should be their own slivers.
            // Ideally we shouldn't put flexible lists inside SliverChildListDelegate,
            // but for simplicity in this structure we might need to adapt.
            // We will put the lists in the specific view build methods if probable.
            // But actually, SliverList delegate builds items.
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
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
            value: data.kpis.totalInterventions.toString(),
            icon: Icons.assignment,
            iconColor: ChartConfig.kpiColors['interventions']!,
            subtitle: 'Total sur la période',
          ),
          KpiCard(
            title: 'Réalisées',
            value: data.kpis.realizedInterventions.toString(),
            icon: Icons.check_circle,
            iconColor: const Color(0xFF10B981),
            subtitle: '${data.kpis.completionRate.toStringAsFixed(0)}% Taux',
          ),
          KpiCard(
            title: 'En cours',
            value: data.kpis.pendingInterventions.toString(),
            icon: Icons.pending_actions,
            iconColor: AppTheme.alertRed,
            subtitle: 'Action requise',
          ),
          KpiCard(
            title: 'Prévues',
            value: data.kpis.plannedInterventions.toString(),
            icon: Icons.calendar_today,
            iconColor: AppTheme.lightBlue,
            subtitle: 'Futures',
          ),
        ],
      ),
      loading: () => KpiGrid(
        cards: List.generate(
          4,
          (index) => const KpiCard(
            title: '',
            value: '',
            icon: Icons.help,
            iconColor: Colors.grey,
            isLoading: true,
          ),
        ),
      ),
      error: (e, s) => Text('Erreur: $e'),
    );
  }

  Widget _buildGeneralView(AsyncValue<DashboardData> dataAsync) {
    return Column(
      children: [
        // Chart Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: dataAsync.when(
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activité',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.darkBlue,
                  ),
                ),
                const SizedBox(height: 24),
                TimeEvolutionChartWidget(
                  data: data.timeEvolution,
                  title: '',
                  showGrid: true,
                  animate: true,
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Erreur: $err')),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Interventions Récentes',
              style: AppTheme.lightTheme.textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => context.push(AppRouter.history),
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        dataAsync.when(
          data: (data) => Column(
            children: data.recentInterventions.map((item) {
              return MobileInterventionListItem(
                type: item.type,
                client: '${item.technicianName} - ${item.durationMinutes} min',
                date: item.date,
                status: item.status,
                onTap: () {
                  context.pushNamed(
                    'cri-view',
                    pathParameters: {'id': item.id},
                    queryParameters: {'type': item.source},
                  );
                },
              );
            }).toList(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Erreur: $e'),
        ),
      ],
    );
  }

  Widget _buildSitesView(WidgetRef ref) {
    // We reuse topSitesProvider
    final topSitesAsync = ref.watch(topSitesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sites les plus actifs',
          style: AppTheme.lightTheme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        topSitesAsync.when(
          data: (sites) => Column(
            children: sites
                .map(
                  (site) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.lightGray),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.lightGray,
                        child: Icon(
                          Icons.business,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      title: Text(
                        site.siteName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(site.clientName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${site.visitCount} interv.',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkBlue,
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => context.pushNamed(
                        'site-dashboard',
                        pathParameters: {'siteId': site.siteId},
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Erreur: $e'),
        ),
      ],
    );
  }

  Widget _buildTechniciansView(WidgetRef ref) {
    final techniciansAsync = ref.watch(techniciansListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Liste des Techniciens',
          style: AppTheme.lightTheme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        techniciansAsync.when(
          data: (techs) => Column(
            children: techs
                .map(
                  (tech) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.lightGray),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryBlue.withValues(
                          alpha: 0.1,
                        ),
                        child: Text(
                          tech.name.isNotEmpty
                              ? tech.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        tech.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(tech.email),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.pushNamed(
                        'technician-dashboard',
                        pathParameters: {'techId': tech.id},
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Erreur: $e'),
        ),
      ],
    );
  }
}

class _ViewModeSelector extends StatelessWidget {
  final DashboardViewMode currentMode;
  final Function(DashboardViewMode) onModeChanged;

  const _ViewModeSelector({
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Row(
        children: [
          _buildItem('Général', DashboardViewMode.general),
          _buildItem('Sites', DashboardViewMode.parSite),
          _buildItem('Techniciens', DashboardViewMode.parTechnicien),
        ],
      ),
    );
  }

  Widget _buildItem(String label, DashboardViewMode mode) {
    final isSelected = currentMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => onModeChanged(mode),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
