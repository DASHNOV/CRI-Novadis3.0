import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';
import 'package:novadis_cri/features/dashboard/config/chart_config.dart';

/// Widget pour le graphique de distribution par type
class TypeDistributionChartWidget extends StatefulWidget {
  final List<TypeDistributionData> data;
  final String title;
  final String? subtitle;
  final bool horizontal;
  final bool animate;

  const TypeDistributionChartWidget({
    super.key,
    required this.data,
    this.title = 'Distribution par Type (Top 5)',
    this.subtitle,
    this.horizontal = false,
    this.animate = true,
  });

  @override
  State<TypeDistributionChartWidget> createState() =>
      _TypeDistributionChartWidgetState();
}

class _TypeDistributionChartWidgetState
    extends State<TypeDistributionChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ChartConfig.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
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
              height: widget.horizontal ? widget.data.length * 50.0 : 200,
              child: widget.data.isEmpty
                  ? _buildEmptyState()
                  : AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return widget.horizontal
                            ? _buildHorizontalChart()
                            : _buildVerticalChart();
                      },
                    ),
            ),
            if (widget.data.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildLegend(),
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
          Icon(Icons.bar_chart, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Aucune donnée disponible',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalChart() {
    final maxY = widget.data.isEmpty
        ? 10.0
        : widget.data
                  .map((e) => e.count)
                  .reduce((a, b) => a > b ? a : b)
                  .toDouble() *
              1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.grey[800]!,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final data = widget.data[groupIndex];
              return BarTooltipItem(
                '${data.type}\n${data.count} (${data.percentage.toStringAsFixed(1)}%)',
                ChartConfig.tooltipTextStyle,
              );
            },
          ),
          touchCallback: (event, response) {
            setState(() {
              if (event is FlTapUpEvent || event is FlPanUpdateEvent) {
                _touchedIndex = response?.spot?.touchedBarGroupIndex;
              } else {
                _touchedIndex = null;
              }
            });
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < widget.data.length) {
                  final label = _truncateLabel(widget.data[index].type);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label,
                      style: ChartConfig.axisLabelStyle,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  ChartConfig.formatAxisValue(value),
                  style: ChartConfig.axisLabelStyle,
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: ChartConfig.gridLineColor, strokeWidth: 1);
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(widget.data.length, (index) {
          final isSelected = index == _touchedIndex;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: widget.data[index].count * _animation.value,
                color: ChartConfig.getBarColor(index),
                width: ChartConfig.barWidth,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: ChartConfig.gridLineColor.withValues(alpha: 0.1),
                ),
              ),
            ],
            showingTooltipIndicators: isSelected ? [0] : [],
          );
        }),
      ),
    );
  }

  Widget _buildHorizontalChart() {
    final maxX = widget.data.isEmpty
        ? 10.0
        : widget.data
                  .map((e) => e.count)
                  .reduce((a, b) => a > b ? a : b)
                  .toDouble() *
              1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxX,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.grey[800]!,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final data = widget.data[groupIndex];
              return BarTooltipItem(
                '${data.type}: ${data.count}',
                ChartConfig.tooltipTextStyle,
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 100,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < widget.data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      widget.data[index].type,
                      style: ChartConfig.axisLabelStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(widget.data.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: widget.data[index].count * _animation.value,
                color: ChartConfig.getBarColor(index),
                width: 20,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: widget.data.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: ChartConfig.getBarColor(index),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${data.type} (${data.count})',
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _truncateLabel(String label) {
    if (label.length > 10) {
      return '${label.substring(0, 8)}...';
    }
    return label;
  }
}
