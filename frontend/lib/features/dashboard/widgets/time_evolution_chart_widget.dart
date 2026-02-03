import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';
import 'package:novadis_cri/features/dashboard/config/chart_config.dart';

/// Widget pour le graphique d'évolution temporelle
class TimeEvolutionChartWidget extends StatefulWidget {
  final List<TimeEvolutionData> data;
  final String title;
  final String? subtitle;
  final bool showGrid;
  final bool animate;

  const TimeEvolutionChartWidget({
    super.key,
    required this.data,
    this.title = 'Évolution des 6 derniers mois',
    this.subtitle,
    this.showGrid = true,
    this.animate = true,
  });

  @override
  State<TimeEvolutionChartWidget> createState() =>
      _TimeEvolutionChartWidgetState();
}

class _TimeEvolutionChartWidgetState extends State<TimeEvolutionChartWidget>
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
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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
              height: 200,
              child: widget.data.isEmpty
                  ? _buildEmptyState()
                  : RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return LineChart(_buildChartData());
                        },
                      ),
                    ),
            ),
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
          Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Aucune donnée disponible',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData() {
    final maxY = widget.data.isEmpty
        ? 10.0
        : widget.data
                  .map((e) => e.count)
                  .reduce((a, b) => a > b ? a : b)
                  .toDouble() *
              1.2;

    return LineChartData(
      gridData: FlGridData(
        show: widget.showGrid,
        drawVerticalLine: false,
        horizontalInterval: maxY / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: ChartConfig.gridLineColor, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < widget.data.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    widget.data[index].label,
                    style: ChartConfig.axisLabelStyle,
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
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (widget.data.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => Colors.grey[800]!,
          tooltipRoundedRadius: 8,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final data = widget.data[spot.x.toInt()];
              return LineTooltipItem(
                '${data.label}\n${data.count} interventions',
                ChartConfig.tooltipTextStyle,
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
        touchCallback: (event, response) {
          if (event is FlTapUpEvent || event is FlPanUpdateEvent) {
            setState(() {
              _touchedIndex = response?.lineBarSpots?.isNotEmpty == true
                  ? response!.lineBarSpots!.first.x.toInt()
                  : null;
            });
          }
        },
      ),
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(widget.data.length, (index) {
            final animatedValue = widget.data[index].count * _animation.value;
            return FlSpot(index.toDouble(), animatedValue);
          }),
          isCurved: true,
          curveSmoothness: 0.3,
          color: ChartConfig.primaryLineColor,
          barWidth: ChartConfig.lineWidth,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              final isSelected = index == _touchedIndex;
              return FlDotCirclePainter(
                radius: isSelected ? 6 : ChartConfig.dotRadius,
                color: ChartConfig.primaryLineColor,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: ChartConfig.areaGradient,
            ),
          ),
        ),
      ],
    );
  }
}
