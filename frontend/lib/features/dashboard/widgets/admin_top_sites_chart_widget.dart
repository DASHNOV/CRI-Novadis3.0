import 'package:flutter/material.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/dashboard/config/chart_config.dart';
import 'package:novadis_cri/models/site_stats.dart';

/// Horizontal bar chart — sites ranked by total interventions.
/// Consumes server-aggregated [SiteStats] (endpoint /global/stats/by-site).
class AdminTopSitesChartWidget extends StatelessWidget {
  final List<SiteStats> sites;
  final int topN;
  final String title;
  final String? subtitle;

  const AdminTopSitesChartWidget({
    super.key,
    required this.sites,
    this.topN = 8,
    this.title = 'Top sites par interventions',
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...sites]
      ..sort((a, b) => b.totalInterventions.compareTo(a.totalInterventions));
    final data = sorted.take(topN).toList();
    final maxVal = data.isEmpty
        ? 0
        : data.map((s) => s.totalInterventions).reduce((a, b) => a > b ? a : b);

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
          Text(title, style: ChartConfig.chartTitleStyle),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: ChartConfig.chartSubtitleStyle),
          ],
          const SizedBox(height: 20),
          if (data.isEmpty)
            SizedBox(
              height: 120,
              child: Center(
                child: Text('Aucune donnée',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
            )
          else
            ...List.generate(data.length, (i) {
              final site = data[i];
              final ratio = maxVal == 0
                  ? 0.0
                  : site.totalInterventions / maxVal;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _siteRow(site, ratio, ChartConfig.getBarColor(i)),
              );
            }),
        ],
      ),
    );
  }

  Widget _siteRow(SiteStats site, double ratio, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                site.siteNom,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${site.totalInterventions}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 8,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  duration: ChartConfig.animationDuration,
                  curve: ChartConfig.animationCurve,
                  tween: Tween(begin: 0, end: ratio),
                  builder: (context, value, _) => Container(
                    height: 8,
                    width: constraints.maxWidth * value,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.engineering,
                size: 12, color: AppTheme.textTertiary),
            const SizedBox(width: 3),
            Text(
              '${site.techniciensDistincts} tech.',
              style: TextStyle(fontSize: 11, color: AppTheme.textTertiary),
            ),
            if (site.topCategorie != null) ...[
              const SizedBox(width: 12),
              Icon(Icons.label_outline,
                  size: 12, color: AppTheme.textTertiary),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  site.topCategorie!,
                  style:
                      TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (site.tauxResolution > 0) ...[
              const SizedBox(width: 12),
              Icon(Icons.check_circle_outline,
                  size: 12, color: AppTheme.success),
              const SizedBox(width: 3),
              Text(
                '${site.tauxResolution.toStringAsFixed(0)}%',
                style:
                    TextStyle(fontSize: 11, color: AppTheme.textTertiary),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
