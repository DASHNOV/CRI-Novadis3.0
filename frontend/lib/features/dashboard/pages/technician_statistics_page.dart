import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';
import 'package:novadis_cri/features/dashboard/providers/dashboard_providers.dart';
import 'package:novadis_cri/features/dashboard/widgets/dashboard_common_widgets.dart';
import 'package:novadis_cri/features/dashboard/widgets/technician_kpi_cards_widget.dart';
import 'package:novadis_cri/features/dashboard/widgets/skills_radar_chart_widget.dart';
import 'package:novadis_cri/features/dashboard/widgets/workload_curve_chart_widget.dart';

/// Page des statistiques par technicien
/// Accessible uniquement aux rôles admin et manager
class TechnicianStatisticsPage extends ConsumerWidget {
  const TechnicianStatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final techniciansAsync = ref.watch(techniciansListProvider);
    final selectedTechnician = ref.watch(selectedTechnicianProvider);
    final techStatsAsync = ref.watch(technicianStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques Techniciens'),
        actions: const [
          ConnectionStatusBadge(isOnline: true),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            const DashboardHeaderWidget(
              title: 'Analyse de Performance',
              subtitle: 'Statistiques individuelles des techniciens',
            ),

            const SizedBox(height: 20),

            // Sélecteur de technicien
            techniciansAsync.when(
              data: (technicians) => TechnicianSelectorWidget(
                technicians: technicians,
                selectedTechnician: selectedTechnician,
                onTechnicianChanged: (tech) {
                  ref.read(selectedTechnicianProvider.notifier).state = tech;
                },
              ),
              loading: () => const TechnicianSelectorWidget(
                technicians: [],
                isLoading: true,
                onTechnicianChanged: null,
              ),
              error: (error, _) => _buildErrorWidget(
                'Erreur de chargement des techniciens',
                error,
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

            // Contenu conditionnel selon la sélection
            if (selectedTechnician == null)
              _buildNoSelectionState()
            else
              _buildTechnicianStats(
                context,
                ref,
                techStatsAsync,
                selectedTechnician,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSelectionState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Sélectionnez un technicien',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pour afficher ses statistiques de performance',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechnicianStats(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<TechnicianStatsData?> statsAsync,
    TechnicianModel technician,
  ) {
    return statsAsync.when(
      data: (stats) {
        if (stats == null) {
          return _buildNoSelectionState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte profil technicien
            _TechnicianProfileCard(technician: technician),

            const SizedBox(height: 20),

            // KPIs individuels
            TechnicianKpiCardsWidget(kpis: stats.kpis),

            const SizedBox(height: 24),

            // Radar de compétences
            SkillsRadarChartWidget(
              data: stats.skillsRadar,
              title: 'Répartition par Type d\'Intervention',
              subtitle: 'Compétences et spécialisations',
              topCategoryInsight: stats.topCategory != null
                  ? 'Expert en ${stats.topCategory}'
                  : null,
            ),

            const SizedBox(height: 16),

            // Courbe de charge
            WorkloadCurveChartWidget(
              data: stats.workloadCurve,
              title: 'Charge de Travail Hebdomadaire',
              subtitle: 'Heures travaillées par semaine (8 dernières semaines)',
              thresholdHours: 40,
            ),

            const SizedBox(height: 24),

            // Résumé des performances
            _buildPerformanceSummary(stats),

            const SizedBox(height: 16),
          ],
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, _) =>
          _buildErrorWidget('Erreur de chargement des statistiques', error),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement des statistiques...'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String title, Object error) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSummary(TechnicianStatsData stats) {
    // Calcul d'un score global de performance
    double score = 0;
    int factors = 0;

    // Taux de complétion
    if (stats.kpis.assignedInterventions > 0) {
      score +=
          (stats.kpis.completedInterventions /
              stats.kpis.assignedInterventions) *
          25;
      factors++;
    }

    // First time fix
    score += (stats.kpis.firstTimeFixRate / 100) * 25;
    factors++;

    // Ponctualité
    score += (stats.kpis.punctualityRate / 100) * 33.3;
    factors++;

    final finalScore = factors > 0
        ? (score * 1.33)
        : 0; // Ajuster le score sur 100

    Color scoreColor;
    String scoreLabel;
    IconData scoreIcon;

    if (finalScore >= 80) {
      scoreColor = Colors.green;
      scoreLabel = 'Excellent';
      scoreIcon = Icons.emoji_events;
    } else if (finalScore >= 60) {
      scoreColor = Colors.blue;
      scoreLabel = 'Bon';
      scoreIcon = Icons.thumb_up;
    } else if (finalScore >= 40) {
      scoreColor = Colors.orange;
      scoreLabel = 'Moyen';
      scoreIcon = Icons.trending_flat;
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'À améliorer';
      scoreIcon = Icons.trending_down;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: scoreColor, width: 3),
              ),
              child: Center(
                child: Text(
                  '${finalScore.toInt()}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(scoreIcon, color: scoreColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Score Global: $scoreLabel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Basé sur: complétion, résolution premier passage et ponctualité',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte du profil technicien
class _TechnicianProfileCard extends StatelessWidget {
  final TechnicianModel technician;

  const _TechnicianProfileCard({required this.technician});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                technician.name.isNotEmpty
                    ? technician.name.split(' ').map((n) => n[0]).take(2).join()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    technician.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        technician.email,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (technician.role != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        technician.role!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
