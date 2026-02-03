import 'package:novadis_cri/data/models/cri_service_model.dart';
import 'package:novadis_cri/data/models/cri_projet_model.dart';
import 'package:novadis_cri/data/local/tables/cri_service_table.dart';
import 'package:novadis_cri/data/local/tables/cri_projet_table.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';

/// Service de calcul des KPIs du dashboard
class KpiCalculatorService {
  /// Calcule le nombre total d'interventions
  int calculateTotalInterventions(
    List<CriServiceModel> services,
    List<CriProjetModel> projets,
    DashboardPeriod period,
  ) {
    final startDate = period.startDate;
    final endDate = period.endDate;

    final serviceCount = services.where((s) {
      return s.interventionDate.isAfter(startDate) &&
          s.interventionDate.isBefore(endDate.add(const Duration(days: 1)));
    }).length;

    final projetCount = projets.where((p) {
      return p.interventionDate.isAfter(startDate) &&
          p.interventionDate.isBefore(endDate.add(const Duration(days: 1)));
    }).length;

    return serviceCount + projetCount;
  }

  /// Calcule le nombre de sites actifs (distincts)
  int calculateActiveSites(
    List<CriServiceModel> services,
    List<CriProjetModel> projets,
    DashboardPeriod period,
  ) {
    final startDate = period.startDate;
    final endDate = period.endDate;

    final sites = <String>{};

    for (final service in services) {
      if (service.interventionDate.isAfter(startDate) &&
          service.interventionDate.isBefore(
            endDate.add(const Duration(days: 1)),
          )) {
        sites.add(service.site);
      }
    }

    for (final projet in projets) {
      if (projet.interventionDate.isAfter(startDate) &&
          projet.interventionDate.isBefore(
            endDate.add(const Duration(days: 1)),
          )) {
        sites.add(projet.site);
      }
    }

    return sites.length;
  }

  /// Calcule la durée moyenne des interventions en minutes
  double calculateAverageDuration(
    List<CriServiceModel> services,
    List<CriProjetModel> projets,
    DashboardPeriod period,
  ) {
    final startDate = period.startDate;
    final endDate = period.endDate;

    final durations = <int>[];

    for (final service in services) {
      if (service.interventionDate.isAfter(startDate) &&
          service.interventionDate.isBefore(
            endDate.add(const Duration(days: 1)),
          )) {
        durations.add(service.interventionDurationMinutes);
      }
    }

    for (final projet in projets) {
      if (projet.interventionDate.isAfter(startDate) &&
          projet.interventionDate.isBefore(
            endDate.add(const Duration(days: 1)),
          )) {
        durations.add(projet.durationMinutes);
      }
    }

    if (durations.isEmpty) return 0;
    return durations.reduce((a, b) => a + b) / durations.length;
  }

  /// Calcule le taux de complétion
  double calculateCompletionRate(
    List<CriServiceModel> services,
    List<CriProjetModel> projets,
    DashboardPeriod period,
  ) {
    final startDate = period.startDate;
    final endDate = period.endDate;

    int total = 0;
    int completed = 0;

    for (final service in services) {
      if (service.interventionDate.isAfter(startDate) &&
          service.interventionDate.isBefore(
            endDate.add(const Duration(days: 1)),
          )) {
        total++;
        if (service.resolutionStatus == ResolutionStatus.resolu ||
            service.resolutionStatus == ResolutionStatus.partiellementResolu) {
          completed++;
        }
      }
    }

    for (final projet in projets) {
      if (projet.interventionDate.isAfter(startDate) &&
          projet.interventionDate.isBefore(
            endDate.add(const Duration(days: 1)),
          )) {
        total++;
        if (projet.projectStatus == ProjectStatus.termine) {
          completed++;
        }
      }
    }

    if (total == 0) return 0;
    return (completed / total) * 100;
  }

  /// Calcule le taux de complétion pour la période précédente
  double calculatePreviousCompletionRate(
    List<CriServiceModel> services,
    List<CriProjetModel> projets,
    DashboardPeriod period,
  ) {
    final startDate = period.previousStartDate;
    final endDate = period.previousEndDate;

    int total = 0;
    int completed = 0;

    for (final service in services) {
      if (service.interventionDate.isAfter(startDate) &&
          service.interventionDate.isBefore(endDate)) {
        total++;
        if (service.resolutionStatus == ResolutionStatus.resolu ||
            service.resolutionStatus == ResolutionStatus.partiellementResolu) {
          completed++;
        }
      }
    }

    for (final projet in projets) {
      if (projet.interventionDate.isAfter(startDate) &&
          projet.interventionDate.isBefore(endDate)) {
        total++;
        if (projet.projectStatus == ProjectStatus.termine) {
          completed++;
        }
      }
    }

    if (total == 0) return 0;
    return (completed / total) * 100;
  }

  /// Calcule la tendance entre deux valeurs
  TrendDirection calculateTrend(double currentValue, double previousValue) {
    if (previousValue == 0) return TrendDirection.neutral;
    final change = currentValue - previousValue;
    if (change > 0.5) return TrendDirection.up;
    if (change < -0.5) return TrendDirection.down;
    return TrendDirection.neutral;
  }

  /// Calcule les données d'évolution temporelle (6 derniers mois)
  List<TimeEvolutionData> calculateTimeEvolution(
    List<CriServiceModel> services,
    List<CriProjetModel> projets,
  ) {
    final now = DateTime.now();
    final months = <TimeEvolutionData>[];
    final monthNames = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);

      int count = 0;

      count += services.where((s) {
        return s.interventionDate.isAfter(monthDate) &&
            s.interventionDate.isBefore(nextMonth);
      }).length;

      count += projets.where((p) {
        return p.interventionDate.isAfter(monthDate) &&
            p.interventionDate.isBefore(nextMonth);
      }).length;

      months.add(
        TimeEvolutionData(
          date: monthDate,
          count: count,
          label: monthNames[monthDate.month - 1],
        ),
      );
    }

    return months;
  }

  /// Calcule la distribution par type d'intervention (Top 5)
  List<TypeDistributionData> calculateTypeDistribution(
    List<CriServiceModel> services,
    List<CriProjetModel> projets,
    DashboardPeriod period,
  ) {
    final startDate = period.startDate;
    final endDate = period.endDate;
    final typeCounts = <String, int>{};

    for (final service in services) {
      if (service.interventionDate.isAfter(startDate) &&
          service.interventionDate.isBefore(
            endDate.add(const Duration(days: 1)),
          )) {
        final type = service.requestType.label;
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }
    }

    for (final projet in projets) {
      if (projet.interventionDate.isAfter(startDate) &&
          projet.interventionDate.isBefore(
            endDate.add(const Duration(days: 1)),
          )) {
        final type = projet.interventionType.label;
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }
    }

    final total = typeCounts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return [];

    final sortedEntries = typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries.take(5).map((entry) {
      return TypeDistributionData(
        type: entry.key,
        count: entry.value,
        percentage: (entry.value / total) * 100,
      );
    }).toList();
  }

  /// Calcule le top 5 des sites les plus visités
  List<TopSiteData> calculateTopSites(
    List<CriServiceModel> services,
    List<CriProjetModel> projets,
    DashboardPeriod period,
  ) {
    final startDate = period.startDate;
    final endDate = period.endDate;
    final siteData = <String, _SiteInfo>{};

    for (final service in services) {
      if (service.interventionDate.isAfter(startDate) &&
          service.interventionDate.isBefore(
            endDate.add(const Duration(days: 1)),
          )) {
        final key = service.site;
        if (siteData.containsKey(key)) {
          siteData[key]!.count++;
        } else {
          siteData[key] = _SiteInfo(
            siteName: service.site,
            clientName: service.clientName,
            count: 1,
          );
        }
      }
    }

    for (final projet in projets) {
      if (projet.interventionDate.isAfter(startDate) &&
          projet.interventionDate.isBefore(
            endDate.add(const Duration(days: 1)),
          )) {
        final key = projet.site;
        if (siteData.containsKey(key)) {
          siteData[key]!.count++;
        } else {
          siteData[key] = _SiteInfo(
            siteName: projet.site,
            clientName: projet.clientName,
            count: 1,
          );
        }
      }
    }

    final sorted = siteData.entries.toList()
      ..sort((a, b) => b.value.count.compareTo(a.value.count));

    return sorted.take(5).map((entry) {
      return TopSiteData(
        siteId: entry.key,
        siteName: entry.value.siteName,
        clientName: entry.value.clientName,
        visitCount: entry.value.count,
      );
    }).toList();
  }

  /// Calcule la moyenne de l'équipe pour un métrique donné
  double calculateTeamAverage(
    List<CriServiceModel> services,
    DashboardPeriod period,
  ) {
    final startDate = period.startDate;
    final endDate = period.endDate;
    final technicianCounts = <String, int>{};

    for (final service in services) {
      if (service.interventionDate.isAfter(startDate) &&
          service.interventionDate.isBefore(
            endDate.add(const Duration(days: 1)),
          )) {
        final tech = service.technicianName;
        technicianCounts[tech] = (technicianCounts[tech] ?? 0) + 1;
      }
    }

    if (technicianCounts.isEmpty) return 0;
    final total = technicianCounts.values.fold<int>(0, (a, b) => a + b);
    return total / technicianCounts.length;
  }

  /// Calcule le taux de résolution au premier passage
  double calculateFirstTimeFixRate(
    List<CriServiceModel> services,
    String? technicianName,
    DashboardPeriod period,
  ) {
    final startDate = period.startDate;
    final endDate = period.endDate;
    int total = 0;
    int firstTimeFix = 0;

    for (final service in services) {
      if (service.interventionDate.isAfter(startDate) &&
          service.interventionDate.isBefore(
            endDate.add(const Duration(days: 1)),
          )) {
        if (technicianName == null ||
            service.technicianName == technicianName) {
          total++;
          if (service.resolutionStatus == ResolutionStatus.resolu &&
              !service.additionalInterventionRequired) {
            firstTimeFix++;
          }
        }
      }
    }

    if (total == 0) return 0;
    return (firstTimeFix / total) * 100;
  }

  /// Normalise les données du radar (0-100)
  List<SkillRadarData> normalizeRadarData(
    Map<String, int> categoryData, {
    int maxCategories = 8,
  }) {
    if (categoryData.isEmpty) return [];

    final maxValue = categoryData.values
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final sorted = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(maxCategories).map((entry) {
      return SkillRadarData(
        category: entry.key,
        count: entry.value,
        normalizedValue: maxValue > 0 ? (entry.value / maxValue) * 100 : 0,
      );
    }).toList();
  }

  /// Calcule la charge de travail hebdomadaire
  List<WorkloadData> calculateWorkloadCurve(
    List<CriServiceModel> services,
    String technicianName,
    DashboardPeriod period,
  ) {
    final now = DateTime.now();
    final weeks = <WorkloadData>[];

    // 8 dernières semaines
    for (int i = 7; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + (i * 7)));
      final weekEnd = weekStart.add(const Duration(days: 7));

      double totalMinutes = 0;

      for (final service in services) {
        if (service.technicianName == technicianName &&
            service.interventionDate.isAfter(weekStart) &&
            service.interventionDate.isBefore(weekEnd)) {
          totalMinutes += service.interventionDurationMinutes;
        }
      }

      weeks.add(
        WorkloadData(
          weekStart: weekStart,
          totalHours: totalMinutes / 60,
          weekLabel: 'S${8 - i}',
        ),
      );
    }

    return weeks;
  }
}

/// Classe helper pour les infos de site
class _SiteInfo {
  final String siteName;
  final String clientName;
  int count;

  _SiteInfo({
    required this.siteName,
    required this.clientName,
    required this.count,
  });
}

/// Direction de la tendance
enum TrendDirection { up, down, neutral }
