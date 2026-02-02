import 'package:flutter/material.dart';
import 'package:novadis_cri/features/dashboard/config/chart_config.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';

/// Widget pour afficher les KPIs du technicien
class TechnicianKpiCardsWidget extends StatelessWidget {
  final TechnicianKpis kpis;
  final bool isLoading;

  const TechnicianKpiCardsWidget({
    super.key,
    required this.kpis,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('📊 Volume d\'intervention'),
        const SizedBox(height: 12),
        _buildVolumeKpis(),

        const SizedBox(height: 24),
        _buildSectionTitle('⏱️ Performance Temporelle'),
        const SizedBox(height: 12),
        _buildTimeKpis(),

        const SizedBox(height: 24),
        _buildSectionTitle('⭐ Qualité et Satisfaction'),
        const SizedBox(height: 12),
        _buildQualityKpis(),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildVolumeKpis() {
    return Row(
      children: [
        Expanded(
          child: _TechnicianKpiCard(
            title: 'Affectées',
            value: '${kpis.assignedInterventions}',
            icon: Icons.assignment,
            color: ChartConfig.kpiColors['interventions']!,
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TechnicianKpiCard(
            title: 'Réalisées',
            value: '${kpis.completedInterventions}',
            icon: Icons.check_circle_outline,
            color: ChartConfig.kpiColors['sites']!,
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TechnicianKpiCard(
            title: 'vs Équipe',
            value: '${kpis.teamComparison.toStringAsFixed(0)}%',
            icon: Icons.people,
            color: Colors.purple,
            trend: kpis.teamComparison > 100
                ? 'up'
                : (kpis.teamComparison < 100 ? 'down' : null),
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeKpis() {
    final standardDevSign = kpis.standardDeviation >= 0 ? '+' : '';
    final standardDevColor = kpis.standardDeviation < 0
        ? ChartConfig.trendUpColor
        : (kpis.standardDeviation > 0
              ? ChartConfig.trendDownColor
              : Colors.grey);

    return Row(
      children: [
        Expanded(
          child: _TechnicianKpiCard(
            title: 'Durée Moy.',
            value: kpis.formattedAverageDuration,
            icon: Icons.timer,
            color: ChartConfig.kpiColors['duration']!,
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TechnicianKpiCard(
            title: 'Écart Std',
            value:
                '$standardDevSign${kpis.standardDeviation.toStringAsFixed(0)}min',
            icon: Icons.trending_flat,
            color: standardDevColor,
            subtitle: kpis.standardDeviation < 0 ? 'Plus rapide' : 'Plus lent',
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TechnicianKpiCard(
            title: 'Ponctualité',
            value: '${kpis.punctualityRate.toStringAsFixed(0)}%',
            icon: Icons.access_time_filled,
            color: ChartConfig.kpiColors['punctuality']!,
            subtitle: '±15min',
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }

  Widget _buildQualityKpis() {
    return Row(
      children: [
        Expanded(
          child: _SatisfactionKpiCard(
            title: 'Satisfaction',
            value: kpis.averageSatisfaction,
            icon: Icons.star,
            color: ChartConfig.kpiColors['satisfaction']!,
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TechnicianKpiCard(
            title: '1er Passage',
            value: '${kpis.firstTimeFixRate.toStringAsFixed(0)}%',
            icon: Icons.done_all,
            color: ChartConfig.kpiColors['firstFix']!,
            subtitle: 'Sans retour',
            isLoading: isLoading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TechnicianKpiCard(
            title: 'Escalades',
            value: '${kpis.escalationRate.toStringAsFixed(0)}%',
            icon: Icons.arrow_upward,
            color: ChartConfig.kpiColors['escalation']!,
            subtitle: 'Niveau 2',
            isLoading: isLoading,
          ),
        ),
      ],
    );
  }
}

/// Carte KPI individuelle pour technicien
class _TechnicianKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final String? trend;
  final bool isLoading;

  const _TechnicianKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.trend,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isLoading ? _buildSkeleton() : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            if (trend != null) ...[
              const Spacer(),
              Icon(
                trend == 'up' ? Icons.arrow_upward : Icons.arrow_downward,
                color: trend == 'up'
                    ? ChartConfig.trendUpColor
                    : ChartConfig.trendDownColor,
                size: 14,
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        if (subtitle != null) ...[
          Text(
            subtitle!,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 50,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

/// Carte spéciale pour la satisfaction avec étoiles
class _SatisfactionKpiCard extends StatelessWidget {
  final String title;
  final double? value;
  final IconData icon;
  final Color color;
  final bool isLoading;

  const _SatisfactionKpiCard({
    required this.title,
    this.value,
    required this.icon,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isLoading ? _buildSkeleton() : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(height: 10),
        if (value != null) ...[
          Row(
            children: [
              Text(
                value!.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              _buildStars(value!),
            ],
          ),
        ] else ...[
          Text(
            'N/A',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
        ],
        const SizedBox(height: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, size: 12, color: color);
        } else if (index < rating) {
          return Icon(Icons.star_half, size: 12, color: color);
        } else {
          return Icon(
            Icons.star_border,
            size: 12,
            color: color.withValues(alpha: 0.3),
          );
        }
      }),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 50,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
