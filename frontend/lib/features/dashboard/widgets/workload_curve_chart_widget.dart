import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';
import 'package:novadis_cri/features/dashboard/config/chart_config.dart';

/// Widget pour la courbe de charge de travail
class WorkloadCurveChartWidget extends StatefulWidget {
  final List<WorkloadData> data;
  final String title;
  final String? subtitle;
  final double thresholdHours;
  final bool animate;

  const WorkloadCurveChartWidget({
    super.key,
    required this.data,
    this.title = 'Charge de Travail Hebdomadaire',
    this.subtitle = 'Heures travaillées par semaine',
    this.thresholdHours = 40,
    this.animate = true,
  });

  @override
  State<WorkloadCurveChartWidget> createState() =>
      _WorkloadCurveChartWidgetState();
}

class _WorkloadCurveChartWidgetState extends State<WorkloadCurveChartWidget>
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
                  : AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return LineChart(_buildChartData());
                      },
                    ),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
            _buildAlerts(),
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
          Icon(Icons.timeline, size: 48, color: Colors.grey[400]),
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
    double maxY = widget.data.isEmpty
        ? widget.thresholdHours * 1.5
        : widget.data.map((e) => e.totalHours).reduce((a, b) => a > b ? a : b);
    maxY =
        [maxY, widget.thresholdHours * 1.2].reduce((a, b) => a > b ? a : b) *
        1.1;

    return LineChartData(
      gridData: FlGridData(
        show: true,
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
                    widget.data[index].weekLabel,
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
                '${value.toInt()}h',
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
              final status = _getWorkloadStatus(data.totalHours);
              return LineTooltipItem(
                '${data.weekLabel}\n${ChartConfig.formatHours(data.totalHours)}',
                ChartConfig.tooltipTextStyle,
                children: [
                  TextSpan(
                    text: '\n$status',
                    style: TextStyle(
                      color: _getStatusColor(data.totalHours),
                      fontSize: 11,
                    ),
                  ),
                ],
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
      extraLinesData: ExtraLinesData(
        horizontalLines: [
          HorizontalLine(
            y: widget.thresholdHours,
            color: ChartConfig.thresholdLineColor.withValues(alpha: 0.5),
            strokeWidth: 2,
            dashArray: [8, 4],
            label: HorizontalLineLabel(
              show: true,
              labelResolver: (line) =>
                  '${widget.thresholdHours.toInt()}h standard',
              style: TextStyle(
                color: ChartConfig.thresholdLineColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              alignment: Alignment.topRight,
            ),
          ),
        ],
      ),
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(widget.data.length, (index) {
            final animatedValue =
                widget.data[index].totalHours * _animation.value;
            return FlSpot(index.toDouble(), animatedValue);
          }),
          isCurved: true,
          curveSmoothness: 0.3,
          color: const Color(0xFF8B5CF6),
          barWidth: ChartConfig.lineWidth,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              final isSelected = index == _touchedIndex;
              final hours = widget.data[index].totalHours;
              final color = _getStatusColor(hours);
              return FlDotCirclePainter(
                radius: isSelected ? 6 : ChartConfig.dotRadius,
                color: color,
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
              colors: [
                const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                const Color(0xFF8B5CF6).withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Charge actuelle', const Color(0xFF8B5CF6)),
        const SizedBox(width: 24),
        _buildLegendItem(
          'Standard (${widget.thresholdHours.toInt()}h)',
          ChartConfig.thresholdLineColor,
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildAlerts() {
    final alerts = <Widget>[];

    for (final data in widget.data) {
      if (data.totalHours > 48) {
        alerts.add(
          _buildAlertBadge(
            '⚠️ Surcharge ${data.weekLabel}: ${ChartConfig.formatHours(data.totalHours)}',
            Colors.red,
          ),
        );
      } else if (data.totalHours < 30 && data.totalHours > 0) {
        alerts.add(
          _buildAlertBadge(
            'ℹ️ Charge faible ${data.weekLabel}: ${ChartConfig.formatHours(data.totalHours)}',
            Colors.blue,
          ),
        );
      }
    }

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(spacing: 8, runSpacing: 8, children: alerts.take(3).toList()),
    );
  }

  Widget _buildAlertBadge(String message, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 11,
          color: color.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getWorkloadStatus(double hours) {
    if (hours > 48) return 'Surcharge';
    if (hours > widget.thresholdHours) return 'Au-dessus';
    if (hours < 30) return 'En dessous';
    return 'Normal';
  }

  Color _getStatusColor(double hours) {
    if (hours > 48) return Colors.red;
    if (hours > widget.thresholdHours) return Colors.orange;
    if (hours < 30) return Colors.blue;
    return const Color(0xFF8B5CF6);
  }
}

extension on Color {
  Color get shade700 => HSLColor.fromColor(this).withLightness(0.35).toColor();
}
