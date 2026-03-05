import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';
import 'package:novadis_cri/features/dashboard/widgets/intervention_trend_chart_widget.dart';

/// Dashboard spécifique à un Site
class SiteDashboardPage extends ConsumerWidget {
  final String siteId;

  const SiteDashboardPage({super.key, required this.siteId});

  List<WorkloadData> _getTrendData(List<SiteInterventionItem> history) {
    if (history.isEmpty) return [];

    final sorted = List<SiteInterventionItem>.from(history)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Determine range
    final minDate = sorted.first.date;
    final maxDate = DateTime.now();

    // Normalize to start of week (Monday)
    var current = minDate.subtract(Duration(days: minDate.weekday - 1));
    // Ensure we strip time component for accurate comparison
    current = DateTime(current.year, current.month, current.day);

    final endRaw = maxDate.subtract(Duration(days: maxDate.weekday - 1));
    final end = DateTime(endRaw.year, endRaw.month, endRaw.day);

    final Map<String, WorkloadData> weeklyData = {};

    // Populate existing data
    for (var item in sorted) {
      final date = item.date;
      final startOfWeekRaw = date.subtract(Duration(days: date.weekday - 1));
      final startOfWeek = DateTime(
        startOfWeekRaw.year,
        startOfWeekRaw.month,
        startOfWeekRaw.day,
      );
      final key = DateFormat('yyyy-MM-dd').format(startOfWeek);

      if (!weeklyData.containsKey(key)) {
        weeklyData[key] = WorkloadData(
          weekStart: startOfWeek,
          totalHours: 0,
          interventionCount: 0,
          weekLabel: DateFormat('dd MMM', 'fr_FR').format(startOfWeek),
        );
      }

      final currentData = weeklyData[key]!;
      weeklyData[key] = WorkloadData(
        weekStart: currentData.weekStart,
        totalHours: currentData.totalHours + (item.durationMinutes / 60),
        interventionCount: currentData.interventionCount + 1,
        weekLabel: currentData.weekLabel,
      );
    }

    // Build continuous timeline
    final List<WorkloadData> result = [];
    while (!current.isAfter(end)) {
      final key = DateFormat('yyyy-MM-dd').format(current);
      if (weeklyData.containsKey(key)) {
        result.add(weeklyData[key]!);
      } else {
        result.add(
          WorkloadData(
            weekStart: current,
            totalHours: 0,
            interventionCount: 0,
            weekLabel: DateFormat('dd MMM', 'fr_FR').format(current),
          ),
        );
      }
      current = current.add(const Duration(days: 7));
    }

    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteDetailsAsync = ref.watch(siteDetailsProvider(siteId));

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        title: const Text('Dashboard Site'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkBlue),
          onPressed: () => context.pop(),
        ),
      ),
      body: siteDetailsAsync.when(
        data: (siteDetails) => _buildContent(context, siteDetails),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, SiteDetailsData details) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Header avec Gradient
              _SiteHeaderCard(details: details),
              const SizedBox(height: 16),

              // Statistiques Globales du Site
              const Text(
                'Performance du Site',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkBlue,
                ),
              ),
              const SizedBox(height: 12),
              _SiteStatsRow(details: details),
              const SizedBox(height: 24),

              // Graphique nombre d'interventions
              InterventionTrendChartWidget(
                data: _getTrendData(details.interventionHistory),
                title: 'Interventions',
                subtitle: 'Nombre d\'interventions au fil du temps',
              ),
              const SizedBox(height: 24),

              // Liste des techniciens (Simulée pour l'instant car absente du modèle SiteDetailsData actuel, mais demandée)
              // On va extraire les techniciens de l'historique des interventions pour l'instant
              _TechniciansList(history: details.interventionHistory),

              const SizedBox(height: 24),

              // Historique Interactif
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Historique Interventions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkBlue,
                    ),
                  ),
                  Text(
                    '${details.interventionHistory.length} totales',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final intervention = details.interventionHistory[index];
              final isLast = index == details.interventionHistory.length - 1;
              return _TimelineItem(
                intervention: intervention,
                isLast: isLast,
                onTap: () {
                  // Navigation vers Détail CRI
                  // Note: logic to determine type (projet/service) should be robust,
                  // here we assume ID format or just try service.
                  // As default, use criView route
                  context.pushNamed(
                    'cri-view',
                    pathParameters: {'id': intervention.id},
                    queryParameters: {'type': intervention.source},
                  );
                },
              );
            }, childCount: details.interventionHistory.length),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }
}

class _SiteHeaderCard extends StatelessWidget {
  final SiteDetailsData details;

  const _SiteHeaderCard({required this.details});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.darkBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      details.siteName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      details.clientName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (details.address != null) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: Colors.white.withOpacity(0.7),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    details.address!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SiteStatsRow extends StatelessWidget {
  final SiteDetailsData details;

  const _SiteStatsRow({required this.details});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total Interv.',
            value: details.totalInterventions.toString(),
            icon: Icons.assignment,
            color: AppTheme.lightBlue,
          ),
        ),

        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Temps Moy.',
            value: details.averageResolutionTime != null
                ? '${details.averageResolutionTime!.round()}m'
                : '-',
            icon: Icons.timer,
            color: const Color(0xFF10B981), // Emerald
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkBlue,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TechniciansList extends StatelessWidget {
  final List<SiteInterventionItem> history;

  const _TechniciansList({required this.history});

  @override
  Widget build(BuildContext context) {
    // Extract unique technicians
    final techs = history.map((e) => e.technicianName).toSet().toList();

    if (techs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Techniciens Intervenants',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkBlue,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: techs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final techName = techs[index];
              return GestureDetector(
                onTap: () {
                  final techId = techName.replaceAll(' ', '_').toLowerCase();
                  context.pushNamed(
                    'technician-dashboard',
                    pathParameters: {'techId': techId},
                  );
                },
                child: Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.lightGray),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppTheme.lightBlue.withValues(
                          alpha: 0.2,
                        ),
                        child: Text(
                          techName.isNotEmpty ? techName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        techName.split(' ').first,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final SiteInterventionItem intervention;
  final bool isLast;
  final VoidCallback onTap;

  const _TimelineItem({
    required this.intervention,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');
    Color statusColor;

    // Mapping status couleur
    switch (intervention.status.toLowerCase()) {
      case 'résolu':
      case 'terminé':
        statusColor = const Color(0xFF10B981); // Emerald
        break;
      case 'en cours':
        statusColor = AppTheme.lightBlue;
        break;
      default:
        statusColor = AppTheme.alertRed;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne temporelle
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 3),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppTheme.lightGray),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Carte
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.lightGray),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateFormat.format(intervention.date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              intervention.status,
                              style: TextStyle(
                                fontSize: 10,
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        intervention.type,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkBlue,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tech: ${intervention.technicianName}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

