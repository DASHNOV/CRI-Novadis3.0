import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';
import 'package:novadis_cri/features/dashboard/widgets/dashboard_common_widgets.dart';

import 'package:novadis_cri/features/dashboard/widgets/intervention_trend_chart_widget.dart';
import 'package:novadis_cri/features/dashboard/config/chart_config.dart';

/// Dashboard spécifique à un Technicien
class TechnicianDashboardPage extends ConsumerStatefulWidget {
  final String technicianId; // Using name as ID for now based on previous code

  const TechnicianDashboardPage({super.key, required this.technicianId});

  @override
  ConsumerState<TechnicianDashboardPage> createState() =>
      _TechnicianDashboardPageState();
}

class _TechnicianDashboardPageState
    extends ConsumerState<TechnicianDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTechnician();
    });
  }

  Future<void> _loadTechnician() async {
    final technicians = await ref.read(techniciansListProvider.future);
    try {
      final tech = technicians.firstWhere(
        (t) => t.id == widget.technicianId,
        orElse: () => technicians.first,
      );
      ref.read(selectedTechnicianProvider.notifier).state = tech;
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final techStatsAsync = ref.watch(technicianStatsProvider);
    final selectedTech = ref.watch(selectedTechnicianProvider);
    final selectedPeriod = ref.watch(selectedPeriodProvider);

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: const Text('Dashboard Technicien'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkBlue),
          onPressed: () => context.pop(),
        ),
      ),
      body: selectedTech == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _TechnicianHeader(technician: selectedTech),
                      const SizedBox(height: 16),

                      // Filtre de période
                      PeriodFilterWidget(
                        selectedPeriod: selectedPeriod,
                        onPeriodChanged: (period) {
                          ref
                              .read(selectedPeriodProvider.notifier)
                              .setPeriod(period);
                        },
                      ),
                      const SizedBox(height: 24),

                      techStatsAsync.when(
                        data: (stats) {
                          if (stats == null)
                            return const Center(child: Text("Pas de données"));
                          return Column(
                            children: [
                              // 1. Informations sur les sites affectés & Interventions réalisées
                              Row(
                                children: [
                                  Expanded(
                                    child: _SimpleKpiCard(
                                      title: 'Affectées',
                                      value:
                                          '${stats.kpis.assignedInterventions}',
                                      icon: Icons.assignment,
                                      color: ChartConfig
                                          .kpiColors['interventions']!,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _SimpleKpiCard(
                                      title: 'Réalisées',
                                      value:
                                          '${stats.kpis.completedInterventions}',
                                      icon: Icons.check_circle_outline,
                                      color: ChartConfig.kpiColors['sites']!,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // 2. Graphique avec le nombre d'intervention en fonction temps
                              InterventionTrendChartWidget(
                                data: stats.workloadCurve,
                                title: 'Interventions',
                                subtitle: 'Nombre d\'interventions par semaine',
                              ),
                              const SizedBox(height: 24),

                              const SizedBox(height: 24),

                              // 3. (Deleted)

                              // 4. Site fréquenté
                              const SizedBox(height: 24),

                              // 4. Site fréquenté
                              if (stats.topSites.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.03,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sites Fréquents',
                                        style: AppTheme
                                            .lightTheme
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AppTheme.darkBlue,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 12),
                                      Column(
                                        children: stats.topSites
                                            .map(
                                              (site) => InkWell(
                                                onTap: () => context.pushNamed(
                                                  'site-dashboard',
                                                  pathParameters: {
                                                    'siteId': site.siteId,
                                                  },
                                                ),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 8.0,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              8,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme
                                                              .lightGray,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: const Icon(
                                                          Icons.business,
                                                          size: 20,
                                                          color: AppTheme
                                                              .primaryBlue,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              site.siteName,
                                                              style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                            Text(
                                                              '${site.visitCount} visites',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .grey[500],
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const Icon(
                                                        Icons.chevron_right,
                                                        color: Colors.grey,
                                                        size: 20,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            ],
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, s) => Text('Erreur: $e'),
                      ),
                    ]),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
              ],
            ),
    );
  }
}

class _SimpleKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SimpleKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnicianHeader extends StatelessWidget {
  final TechnicianModel technician;
  const _TechnicianHeader({required this.technician});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.primaryBlue,
            child: Text(
              technician.name.isNotEmpty
                  ? technician.name.substring(0, 2).toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  technician.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkBlue,
                  ),
                ),
                Text(
                  technician.role ?? 'Technicien',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.lightBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      technician.email,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
