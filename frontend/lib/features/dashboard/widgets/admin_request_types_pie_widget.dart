import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/dashboard/config/chart_config.dart';

/// Pie chart — répartition des types de demandes (catégories).
/// Alimenté par `DistributionStats.repartitionParCategorie`
/// (endpoint /global/stats/distribution).
class AdminRequestTypesPieWidget extends StatefulWidget {
  final Map<String, int> distribution;
  final int topN;
  final String title;
  final String? subtitle;

  const AdminRequestTypesPieWidget({
    super.key,
    required this.distribution,
    this.topN = 6,
    this.title = 'Types de demandes',
    this.subtitle,
  });

  @override
  State<AdminRequestTypesPieWidget> createState() =>
      _AdminRequestTypesPieWidgetState();
}

class _AdminRequestTypesPieWidgetState
    extends State<AdminRequestTypesPieWidget> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final entries = widget.distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Group tail into "Autres"
    final visible = entries.take(widget.topN).toList();
    final tail = entries.skip(widget.topN);
    int tailSum = 0;
    for (final e in tail) {
      tailSum += e.value;
    }
    final display = [
      ...visible,
      if (tailSum > 0) MapEntry<String, int>('Autres', tailSum),
    ];
    final total = display.fold<int>(0, (s, e) => s + e.value);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: ChartConfig.chartTitleStyle),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(widget.subtitle!, style: ChartConfig.chartSubtitleStyle),
          ],
          const SizedBox(height: 20),
          if (total == 0)
            SizedBox(
              height: 180,
              child: Center(
                child: Text('Aucune donnée',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 420;
                final pie = _buildPieChart(display, total);
                final legend = _buildLegend(display, total);
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 200, child: pie),
                      const SizedBox(height: 16),
                      legend,
                    ],
                  );
                }
                return SizedBox(
                  height: 220,
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: pie),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(child: legend),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<MapEntry<String, int>> display, int total) {
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                _touchedIndex = -1;
                return;
              }
              _touchedIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: List.generate(display.length, (i) {
          final isTouched = i == _touchedIndex;
          final e = display[i];
          final pct = (e.value / total) * 100;
          return PieChartSectionData(
            color: ChartConfig.getBarColor(i),
            value: e.value.toDouble(),
            title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
            radius: isTouched ? 70 : 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLegend(List<MapEntry<String, int>> display, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(display.length, (i) {
        final e = display[i];
        final pct = (e.value / total) * 100;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: ChartConfig.getBarColor(i),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  e.key,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                    fontWeight: i == _touchedIndex
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${e.value} (${pct.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
