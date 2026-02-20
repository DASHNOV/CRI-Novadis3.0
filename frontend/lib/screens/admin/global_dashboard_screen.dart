import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:novadis_cri/models/global_stats.dart';
import 'package:novadis_cri/models/technician_activity.dart';
import 'package:novadis_cri/models/daily_activity.dart';
import 'package:novadis_cri/services/stats_api_service.dart';
import 'package:novadis_cri/features/documents/pages/documents_page.dart';
import 'package:fl_chart/fl_chart.dart';

/// Dashboard global - Vue d'ensemble admin avec statistiques et graphiques
class GlobalDashboardScreen extends ConsumerStatefulWidget {
  const GlobalDashboardScreen({super.key});

  @override
  ConsumerState<GlobalDashboardScreen> createState() =>
      _GlobalDashboardScreenState();
}

class _GlobalDashboardScreenState extends ConsumerState<GlobalDashboardScreen> {
  GlobalStats _stats = GlobalStats.empty();
  List<TechnicianActivity> _activity = [];
  List<DailyActivity> _dailyActivity = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final statsService = ref.read(statsApiServiceProvider);

      final results = await Future.wait([
        statsService.getGlobalStats(),
        statsService.getTechnicianActivity(),
        statsService.getActivityChartData(),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as GlobalStats;
          _activity = results[1] as List<TechnicianActivity>;
          _dailyActivity = results[2] as List<DailyActivity>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Global'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DocumentsPage()),
              );
            },
            tooltip: 'Mes Documents & Exports',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistiques principales
                    _buildStatsGrid(),
                    const SizedBox(height: 28),

                    // Graphique d'activité
                    _buildActivityChart(),
                    const SizedBox(height: 28),

                    // Activité des techniciens
                    _buildTechnicianActivitySection(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vue d\'ensemble',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _GlobalStatCard(
                icon: Icons.description,
                label: 'CRI ce mois',
                value: _stats.totalCeMois.toString(),
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GlobalStatCard(
                icon: Icons.people_alt,
                label: 'Techniciens actifs',
                value: _stats.techniciensActifs.toString(),
                color: Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _GlobalStatCard(
                icon: Icons.check_circle,
                label: 'Signés',
                value: _stats.totalSignes.toString(),
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _GlobalStatCard(
                icon: Icons.pending_actions,
                label: 'En attente',
                value: _stats.totalEnAttente.toString(),
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityChart() {
    if (_dailyActivity.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activité (7 jours)',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _dailyActivity.isEmpty
                      ? 10
                      : _dailyActivity
                                    .map((d) => d.nb.toDouble())
                                    .reduce((a, b) => a > b ? a : b) *
                                1.2 +
                            1,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final day = _dailyActivity[groupIndex];
                        final dateStr = DateFormat('dd/MM').format(day.jour);
                        return BarTooltipItem(
                          '$dateStr\n${day.nb} CRI',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= _dailyActivity.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat(
                                'E',
                                'fr_FR',
                              ).format(_dailyActivity[idx].jour),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: _dailyActivity.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.nb.toDouble(),
                          color: Theme.of(context).colorScheme.primary,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTechnicianActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activité par technicien',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (_activity.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Aucune activité récente',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
            ),
          )
        else
          ..._activity.map((tech) => _buildTechnicianCard(tech)),
      ],
    );
  }

  Widget _buildTechnicianCard(TechnicianActivity tech) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.1),
              child: Text(
                '${tech.firstName.isNotEmpty ? tech.firstName[0] : ''}${tech.lastName.isNotEmpty ? tech.lastName[0] : ''}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tech.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tech.nbCriTotal} CRI au total',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _ActivityBadge(label: '7j', value: tech.nbCri7j),
                const SizedBox(height: 4),
                _ActivityBadge(
                  label: '30j',
                  value: tech.nbCri30j,
                  isSecondary: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte de statistique globale
class _GlobalStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _GlobalStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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

/// Badge d'activité (7j / 30j)
class _ActivityBadge extends StatelessWidget {
  final String label;
  final int value;
  final bool isSecondary;

  const _ActivityBadge({
    required this.label,
    required this.value,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSecondary
            ? Colors.grey.withOpacity(0.1)
            : Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$value $label',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isSecondary
              ? Colors.grey[700]
              : Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
