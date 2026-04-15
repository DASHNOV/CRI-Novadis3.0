import 'package:flutter/material.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/features/dashboard/config/chart_config.dart';
import 'package:novadis_cri/models/distribution_stats.dart';

/// Répartition des interventions par technicien et par site.
/// Chaque technicien est présenté avec une barre empilée indiquant
/// la part de ses interventions réalisée sur chaque site.
///
/// Alimenté par `DistributionStats.technicienParSite`
/// (backend renvoie `ligne = siteNom`, `colonne = techNom`).
class AdminTechnicianSiteHeatmapWidget extends StatelessWidget {
  final List<CrossTabEntry> entries;
  final String title;
  final String? subtitle;
  final int maxTechnicians;

  const AdminTechnicianSiteHeatmapWidget({
    super.key,
    required this.entries,
    this.title = 'Interventions par technicien',
    this.subtitle = 'Détail des sites visités par chaque technicien',
    this.maxTechnicians = 10,
  });

  @override
  Widget build(BuildContext context) {
    // Regroupe par technicien → liste de (site, count)
    final perTech = <String, Map<String, int>>{};
    for (final e in entries) {
      // ligne = site, colonne = technicien
      final tech = e.colonne;
      final site = e.ligne;
      perTech.putIfAbsent(tech, () => <String, int>{})[site] =
          (perTech[tech]?[site] ?? 0) + e.valeur;
    }

    // Trie les techniciens par total décroissant
    final techList = perTech.entries.map((e) {
      final total = e.value.values.fold<int>(0, (a, b) => a + b);
      return _TechRow(tech: e.key, sitesByCount: e.value, total: total);
    }).toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    final visible = techList.take(maxTechnicians).toList();

    // Palette de couleurs stable par nom de site (même site = même couleur)
    final allSites = <String>{};
    for (final t in visible) {
      allSites.addAll(t.sitesByCount.keys);
    }
    final sortedSites = allSites.toList()..sort();
    final siteColor = <String, Color>{
      for (var i = 0; i < sortedSites.length; i++)
        sortedSites[i]: ChartConfig.getBarColor(i),
    };

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
          if (visible.isEmpty)
            SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'Aucune donnée',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else ...[
            // Légende commune (sites)
            if (sortedSites.length > 1) _buildSitesLegend(sortedSites, siteColor),
            if (sortedSites.length > 1) const SizedBox(height: 16),
            ...visible.map((t) => _buildTechRow(t, siteColor)),
          ],
        ],
      ),
    );
  }

  Widget _buildSitesLegend(List<String> sites, Map<String, Color> colors) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: sites.map((s) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colors[s],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              s,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTechRow(_TechRow row, Map<String, Color> siteColor) {
    // Trie les sites du technicien par count desc
    final sitesSorted = row.sitesByCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : nom technicien + total
          Row(
            children: [
              Icon(Icons.person_outline,
                  size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  row.tech,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${row.total} intervention${row.total > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· ${sitesSorted.length} site${sitesSorted.length > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 11, color: AppTheme.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Barre empilée
          LayoutBuilder(
            builder: (context, constraints) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 10,
                  width: constraints.maxWidth,
                  child: Row(
                    children: sitesSorted.map((e) {
                      final flex = e.value;
                      return Expanded(
                        flex: flex,
                        child: Container(
                          color: siteColor[e.key] ??
                              ChartConfig.primaryLineColor,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Chips détaillés : site + count
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: sitesSorted.map((e) {
              final color =
                  siteColor[e.key] ?? ChartConfig.primaryLineColor;
              final pct = row.total == 0
                  ? 0.0
                  : (e.value / row.total) * 100;
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: color.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${e.key} · ${e.value} (${pct.toStringAsFixed(0)}%)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TechRow {
  final String tech;
  final Map<String, int> sitesByCount;
  final int total;

  _TechRow({
    required this.tech,
    required this.sitesByCount,
    required this.total,
  });
}
