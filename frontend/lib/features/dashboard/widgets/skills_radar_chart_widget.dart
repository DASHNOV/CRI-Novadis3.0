import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';
import 'package:novadis_cri/features/dashboard/config/chart_config.dart';

/// Widget pour le radar de compétences du technicien
class SkillsRadarChartWidget extends StatefulWidget {
  final List<SkillRadarData> data;
  final String title;
  final String? subtitle;
  final String? topCategoryInsight;
  final bool animate;

  const SkillsRadarChartWidget({
    super.key,
    required this.data,
    this.title = 'Répartition par Type d\'Intervention',
    this.subtitle = 'Compétences et spécialisations',
    this.topCategoryInsight,
    this.animate = true,
  });

  @override
  State<SkillsRadarChartWidget> createState() => _SkillsRadarChartWidgetState();
}

class _SkillsRadarChartWidgetState extends State<SkillsRadarChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ChartConfig.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    if (widget.animate) {
      _animationController.forward();
    } else {
      _animationController.value = 1;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: ChartConfig.chartTitleStyle),
            if (widget.subtitle != null) ...[
              const SizedBox(height: 4),
              Text(widget.subtitle!, style: ChartConfig.chartSubtitleStyle),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: widget.data.isEmpty
                  ? _buildEmptyState()
                  : RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return _buildRadarChart();
                        },
                      ),
                    ),
            ),
            if (widget.topCategoryInsight != null) ...[
              const SizedBox(height: 16),
              _buildInsight(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radar, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Aucune donnée disponible',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarChart() {
    return RadarChart(
      RadarChartData(
        radarShape: RadarShape.polygon,
        borderData: FlBorderData(show: false),
        titlePositionPercentageOffset: 0.2,
        radarBorderData: BorderSide(color: ChartConfig.gridLineColor, width: 1),
        tickBorderData: BorderSide(color: ChartConfig.gridLineColor, width: 1),
        gridBorderData: BorderSide(color: ChartConfig.gridLineColor, width: 1),
        ticksTextStyle: TextStyle(color: Colors.grey[400], fontSize: 10),
        tickCount: 4,
        titleTextStyle: TextStyle(
          color: Colors.grey[700],
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        getTitle: (index, angle) {
          if (index < widget.data.length) {
            return RadarChartTitle(
              text: _truncateLabel(widget.data[index].category),
              angle: angle,
            );
          }
          return const RadarChartTitle(text: '');
        },
        dataSets: [
          RadarDataSet(
            fillColor: ChartConfig.radarFillColor,
            borderColor: ChartConfig.radarBorderColor,
            borderWidth: 2,
            entryRadius: 3,
            dataEntries: widget.data.map((item) {
              return RadarEntry(value: item.normalizedValue * _animation.value);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInsight() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ChartConfig.primaryLineColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ChartConfig.primaryLineColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.insights, color: ChartConfig.primaryLineColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.topCategoryInsight!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _truncateLabel(String label) {
    if (label.length > 12) {
      return '${label.substring(0, 10)}...';
    }
    return label;
  }
}
