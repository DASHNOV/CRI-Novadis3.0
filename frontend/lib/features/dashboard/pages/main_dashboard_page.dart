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
import 'package:novadis_cri/core/widgets/content_container.dart';
import 'package:novadis_cri/core/theme/responsive.dart';
import 'package:novadis_cri/features/auth/presentation/providers/user_name_provider.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';
import 'package:novadis_cri/features/auth/presentation/providers/permissions_provider.dart';
import 'package:novadis_cri/core/constants/permissions.dart';

/// Page principale du Dashboard avec design modernisé
class MainDashboardPage extends ConsumerStatefulWidget {
  const MainDashboardPage({super.key});

  @override
  ConsumerState<MainDashboardPage> createState() => _MainDashboardPageState();
}

class _MainDashboardPageState extends ConsumerState<MainDashboardPage> {
  @override
  Widget build(BuildContext context) {
    ref.watch(themeAnimationProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final viewMode = ref.watch(dashboardViewModeProvider);
    final dashboardDataAsync = ref.watch(dashboardDataProvider);
    final userName = ref.watch(userNameProvider);
    final userRole = ref.watch(userRoleProvider);
    final isAdmin = userRole == UserRole.admin;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ContentContainer(
          maxWidth: 1400,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Modern App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: AppTheme.background,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                leading: Container(
                  margin: const EdgeInsets.only(left: AppTheme.space12),
                  child: Icon(
                    Icons.dashboard_rounded,
                    color: AppTheme.textPrimary,
                    size: 24,
                  ),
                ),
                title: Text(
                  'Dashboard Global',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    letterSpacing: -0.3,
                  ),
                ),
                actions: [
                  _buildRefreshButton(),
                  const SizedBox(width: AppTheme.space8),
                ],
              ),

              // Content
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      Responsive.responsiveHorizontalPadding(context),
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: AppTheme.space16),

                    // Header Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName != null && userName.isNotEmpty
                              ? 'Bonjour $userName,'
                              : 'Bonjour,',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          'Vue d\'ensemble',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space16),
                        // Filter Pills (Period)
                        PeriodFilterWidget(
                          selectedPeriod: selectedPeriod,
                          onPeriodChanged: (period) {
                            ref
                                .read(selectedPeriodProvider.notifier)
                                .setPeriod(period);
                          },
                        ),
                        const SizedBox(height: AppTheme.space12),
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

                    const SizedBox(height: AppTheme.space24),

                    const SizedBox(height: AppTheme.space24),

                    // Layout based on specific user and view mode
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 1000;
                        if (isAdmin && isDesktop && viewMode == DashboardViewMode.general) {
                          return _buildAdminDesktopView(dashboardDataAsync);
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // KPI Grid
                            _buildKpiSection(dashboardDataAsync),
                            const SizedBox(height: AppTheme.space24),
                            // Content based on View Mode
                            if (viewMode == DashboardViewMode.general)
                              _buildGeneralView(dashboardDataAsync)
                            else if (viewMode == DashboardViewMode.parSite)
                              _buildSitesView(ref)
                            else if (viewMode == DashboardViewMode.parTechnicien)
                              _buildTechniciansView(ref),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: AppTheme.space24),
                  ]),
                ),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Container(
      margin: const EdgeInsets.only(right: AppTheme.space4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      child: IconButton(
        icon: Icon(Icons.refresh_rounded, color: AppTheme.textSecondary, size: 20),
        onPressed: () => ref.refreshDashboard(),
        tooltip: 'Actualiser',
        splashRadius: 20,
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
            iconColor: AppTheme.error,
            subtitle: 'Action requise',
          ),
          KpiCard(
            title: 'Prévues',
            value: data.kpis.plannedInterventions.toString(),
            icon: Icons.calendar_today,
            iconColor: AppTheme.primaryLight,
            subtitle: 'Futures',
          ),
        ],
      ),
      loading: () => KpiGrid(
        cards: List.generate(
          4,
          (index) => KpiCard(
            title: '',
            value: '',
            icon: Icons.help,
            iconColor: AppTheme.textTertiary,
            isLoading: true,
          ),
        ),
      ),
      error: (e, s) => Text('Erreur: $e'),
    );
  }

  Widget _buildEvolutionChart(AsyncValue<DashboardData> dataAsync) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: dataAsync.when(
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Évolution de l\'activité',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 15,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: AppTheme.space24),
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
    );
  }

  Widget _buildTopSitesSummary(AsyncValue<DashboardData> dataAsync) {
    return _buildSectionCard(
      title: 'Sites les plus actifs',
      actionLabel: 'Voir tous',
      onAction: () => ref.read(dashboardViewModeProvider.notifier).state =
          DashboardViewMode.parSite,
      child: dataAsync.when(
        data: (data) {
          final top3 = data.topSites.take(3).toList();
          if (top3.isEmpty) {
            return Padding(
              padding: EdgeInsets.all(AppTheme.space16),
              child: Text('Aucune donnée de site',
                  style: TextStyle(color: AppTheme.textTertiary)),
            );
          }
          return Column(
            children:
                top3.map((site) => _buildSimpleSiteItem(site)).toList(),
          );
        },
        loading: () => Padding(
          padding: EdgeInsets.all(AppTheme.space16),
          child: LinearProgressIndicator(
            backgroundColor: AppTheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(AppTheme.primaryContent),
          ),
        ),
        error: (e, s) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildTechWorkloadSummary(AsyncValue<DashboardData> dataAsync) {
    return _buildSectionCard(
      title: 'Répartition de la charge',
      actionLabel: 'Détails',
      onAction: () => ref.read(dashboardViewModeProvider.notifier).state =
          DashboardViewMode.parTechnicien,
      child: dataAsync.when(
        data: (data) {
          final top3Tech = data.technicianWorkload.take(3).toList();
          if (top3Tech.isEmpty) {
            return Padding(
              padding: EdgeInsets.all(AppTheme.space16),
              child: Text('Aucun technicien actif',
                  style: TextStyle(color: AppTheme.textTertiary)),
            );
          }
          return Column(
            children: top3Tech
                .map((tech) => _buildSimpleTechItem(tech))
                .toList(),
          );
        },
        loading: () => Padding(
          padding: EdgeInsets.all(AppTheme.space16),
          child: LinearProgressIndicator(
            backgroundColor: AppTheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation(AppTheme.primaryContent),
          ),
        ),
        error: (e, s) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildRecentInterventionsSummary(AsyncValue<DashboardData> dataAsync) {
    return _buildSectionCard(
      title: 'Interventions Récentes',
      actionLabel: 'Historique',
      onAction: () => context.push(AppRouter.history),
      child: dataAsync.when(
        data: (data) => Column(
          children: data.recentInterventions.take(5).map((item) {
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
        loading: () => const Padding(
          padding: EdgeInsets.all(AppTheme.space24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, s) => Text('Erreur: $e'),
      ),
    );
  }

  Widget _buildGeneralView(AsyncValue<DashboardData> dataAsync) {
    final widget1 = _buildEvolutionChart(dataAsync);
    final widget2 = _buildTopSitesSummary(dataAsync);
    final widget3 = _buildTechWorkloadSummary(dataAsync);
    final widget4 = _buildRecentInterventionsSummary(dataAsync);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1000) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: widget1),
                  const SizedBox(width: AppTheme.space24),
                  Expanded(child: widget2),
                ],
              ),
              const SizedBox(height: AppTheme.space24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: widget3),
                  const SizedBox(width: AppTheme.space24),
                  Expanded(child: widget4),
                ],
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget1,
            const SizedBox(height: AppTheme.space16),
            widget2,
            const SizedBox(height: AppTheme.space16),
            widget3,
            const SizedBox(height: AppTheme.space16),
            widget4,
          ],
        );
      },
    );
  }

  Widget _buildAdminDesktopView(AsyncValue<DashboardData> dataAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildEvolutionChart(dataAsync)),
            const SizedBox(width: AppTheme.space24),
            Expanded(child: _buildAdminDesktopKpiSection(dataAsync)),
          ],
        ),
        const SizedBox(height: AppTheme.space24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildTopSitesSummary(dataAsync)),
            const SizedBox(width: AppTheme.space24),
            Expanded(child: _buildTechWorkloadSummary(dataAsync)),
          ],
        ),
        const SizedBox(height: AppTheme.space24),
        _buildRecentInterventionsSummary(dataAsync),
      ],
    );
  }

  Widget _buildAdminDesktopKpiSection(AsyncValue<DashboardData> dataAsync) {
    final aspectRatio = 1.3; // Desktop 2x2 ratio

    return dataAsync.when(
      data: (data) {
        final cards = [
          KpiCard(
            title: 'En cours',
            value: data.kpis.pendingInterventions.toString(),
            icon: Icons.pending_actions,
            iconColor: AppTheme.error,
            subtitle: 'Action requise',
          ),
          KpiCard(
            title: 'Prévues',
            value: data.kpis.plannedInterventions.toString(),
            icon: Icons.calendar_today,
            iconColor: AppTheme.primaryLight,
            subtitle: 'Futures',
          ),
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
        ];

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppTheme.space16,
            mainAxisSpacing: AppTheme.space16,
            childAspectRatio: aspectRatio,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => cards[index],
        );
      },
      loading: () => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppTheme.space16,
          mainAxisSpacing: AppTheme.space16,
          childAspectRatio: aspectRatio,
        ),
        itemCount: 4,
        itemBuilder: (context, index) => KpiCard(
          title: '',
          value: '',
          icon: Icons.help,
          iconColor: AppTheme.textTertiary,
          isLoading: true,
        ),
      ),
      error: (e, s) => Text('Erreur: $e'),
    );
  }

  /// Helper to build a consistent section card with title and action
  Widget _buildSectionCard({
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space16,
              AppTheme.space8,
              AppTheme.space8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryContent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space12,
                      vertical: AppTheme.space4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: AppTheme.border.withValues(alpha: 0.5),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildSimpleSiteItem(TopSiteData site) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.pushNamed(
          'site-dashboard',
          pathParameters: {'siteId': site.siteId},
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space16,
            vertical: AppTheme.space12,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(Icons.location_on_rounded,
                    color: AppTheme.primaryContent, size: 18),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      site.siteName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      site.clientName,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space8, vertical: AppTheme.space4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  '${site.visitCount} CRI',
                  style: TextStyle(
                    color: AppTheme.primaryContent,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space4),
              Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textTertiary, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleTechItem(TechnicianWorkloadData tech) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.pushNamed(
          'technician-dashboard',
          pathParameters: {'techId': tech.technicianId},
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space16,
            vertical: AppTheme.space12,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.accent.withValues(alpha: 0.1),
                child: Text(
                  tech.technicianName.isNotEmpty
                      ? tech.technicianName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accent,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tech.technicianName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tech.totalHours.toStringAsFixed(1)}h cumulées',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${tech.interventionCount} interventions',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSitesView(WidgetRef ref) {
    final topSitesAsync = ref.watch(topSitesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sites les plus actifs',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        topSitesAsync.when(
          data: (sites) => Column(
            children: sites
                .map(
                  (site) => Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.space8),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(
                          color: AppTheme.border.withValues(alpha: 0.5)),
                      boxShadow: AppTheme.shadowSm,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(AppTheme.space8),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: Icon(
                            Icons.business_rounded,
                            color: AppTheme.primaryContent,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          site.siteName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          site.clientName,
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${site.visitCount} interv.',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: AppTheme.space4),
                            Icon(Icons.chevron_right_rounded,
                                color: AppTheme.textTertiary, size: 20),
                          ],
                        ),
                        onTap: () => context.pushNamed(
                          'site-dashboard',
                          pathParameters: {'siteId': site.siteId},
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.space24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, s) => Text('Erreur: $e'),
        ),
      ],
    );
  }

  Widget _buildTechniciansView(WidgetRef ref) {
    final workloadAsync = ref.watch(technicianWorkloadProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activité des Techniciens',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
            Icon(Icons.info_outline_rounded,
                size: 18, color: AppTheme.textTertiary),
          ],
        ),
        const SizedBox(height: AppTheme.space12),
        workloadAsync.when(
          data: (workload) => Column(
            children: workload
                .map(
                  (tech) => Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.space8),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(
                          color: AppTheme.border.withValues(alpha: 0.5)),
                      boxShadow: AppTheme.shadowSm,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusLg),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                          child: Text(
                            tech.technicianName.isNotEmpty
                                ? tech.technicianName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: AppTheme.primaryContent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(
                          tech.technicianName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          '${tech.totalHours.toStringAsFixed(1)}h de travail',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 13,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${tech.interventionCount} CRI',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tech.completionRate > 80
                                        ? AppTheme.successLight
                                        : AppTheme.warningLight,
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusFull),
                                  ),
                                  child: Text(
                                    '${tech.completionRate.toStringAsFixed(0)}% résolu',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: tech.completionRate > 80
                                          ? AppTheme.success
                                          : AppTheme.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: AppTheme.space8),
                            Icon(Icons.chevron_right_rounded,
                                color: AppTheme.textTertiary, size: 20),
                          ],
                        ),
                        onTap: () => context.pushNamed(
                          'technician-dashboard',
                          pathParameters: {'techId': tech.technicianId},
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.space24),
              child: CircularProgressIndicator(),
            ),
          ),
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
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(3),
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
        child: AnimatedContainer(
          duration: AppTheme.animFast,
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryContent.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
