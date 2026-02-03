// Modèles de données pour le Dashboard

/// Énumération des périodes de filtre
enum DashboardPeriod {
  day('Jour', 1),
  week('Semaine', 7),
  month('Mois', 30);

  final String label;
  final int days;

  const DashboardPeriod(this.label, this.days);

  /// Retourne la date de début pour cette période
  DateTime get startDate => DateTime.now().subtract(Duration(days: days));

  /// Retourne la date de fin (aujourd'hui)
  DateTime get endDate => DateTime.now();

  /// Retourne la période précédente (pour comparaison)
  DateTime get previousStartDate =>
      DateTime.now().subtract(Duration(days: days * 2));

  DateTime get previousEndDate => DateTime.now().subtract(Duration(days: days));

  /// Formate le label de la période
  String get periodLabel {
    switch (this) {
      case DashboardPeriod.day:
        return "Aujourd'hui";
      case DashboardPeriod.week:
        return '7 derniers jours';
      case DashboardPeriod.month:
        return '30 derniers jours';
    }
  }
}

/// Données des KPIs du dashboard
class DashboardKpis {
  final int totalInterventions;
  final int activeSites;
  final double averageDurationMinutes;
  final double completionRate;
  final double? previousCompletionRate;
  final int realizedInterventions;
  final int pendingInterventions;
  final int plannedInterventions;

  const DashboardKpis({
    required this.totalInterventions,
    required this.activeSites,
    required this.averageDurationMinutes,
    required this.completionRate,
    this.previousCompletionRate,
    this.realizedInterventions = 0,
    this.pendingInterventions = 0,
    this.plannedInterventions = 0,
  });

  /// Durée moyenne formatée
  String get formattedAverageDuration {
    final hours = averageDurationMinutes ~/ 60;
    final minutes = (averageDurationMinutes % 60).round();
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  /// Calcule le changement de tendance
  double? get completionRateTrend {
    if (previousCompletionRate == null || previousCompletionRate == 0) {
      return null;
    }
    return completionRate - previousCompletionRate!;
  }

  /// Valeurs par défaut (état vide)
  factory DashboardKpis.empty() {
    return const DashboardKpis(
      totalInterventions: 0,
      activeSites: 0,
      averageDurationMinutes: 0,
      completionRate: 0,
    );
  }
}

/// Données pour le graphique d'évolution temporelle
class TimeEvolutionData {
  final DateTime date;
  final int count;
  final String label;

  const TimeEvolutionData({
    required this.date,
    required this.count,
    required this.label,
  });
}

/// Données pour le graphique de distribution par type
class TypeDistributionData {
  final String type;
  final int count;
  final double percentage;

  const TypeDistributionData({
    required this.type,
    required this.count,
    required this.percentage,
  });
}

/// Données pour le top sites
class TopSiteData {
  final String siteId;
  final String siteName;
  final String clientName;
  final int visitCount;

  const TopSiteData({
    required this.siteId,
    required this.siteName,
    required this.clientName,
    required this.visitCount,
  });
}

/// Données complètes du dashboard
class DashboardData {
  final DashboardKpis kpis;
  final List<TimeEvolutionData> timeEvolution;
  final List<TypeDistributionData> typeDistribution;
  final List<TopSiteData> topSites;
  final List<dynamic>
  recentInterventions; // Using dynamic to avoid further missing models
  final DateTime lastUpdated;

  const DashboardData({
    required this.kpis,
    required this.timeEvolution,
    required this.typeDistribution,
    required this.topSites,
    this.recentInterventions = const [],
    required this.lastUpdated,
  });

  factory DashboardData.empty() {
    return DashboardData(
      kpis: DashboardKpis.empty(),
      timeEvolution: [],
      typeDistribution: [],
      topSites: [],
      lastUpdated: DateTime.now(),
    );
  }
}

/// Modèle de technicien pour les statistiques
class TechnicianModel {
  final String id;
  final String name;
  final String email;
  final String? role;

  const TechnicianModel({
    required this.id,
    required this.name,
    required this.email,
    this.role,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TechnicianModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.role == role;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ email.hashCode ^ role.hashCode;
  }
}

/// KPIs individuels du technicien
class TechnicianKpis {
  // Volume
  final int assignedInterventions;
  final int completedInterventions;
  final double teamComparison;

  // Performance temporelle
  final double averageDurationMinutes;
  final double standardDeviation;
  final double punctualityRate;

  // Qualité
  final double firstTimeFixRate;
  final double escalationRate;

  const TechnicianKpis({
    required this.assignedInterventions,
    required this.completedInterventions,
    required this.teamComparison,
    required this.averageDurationMinutes,
    required this.standardDeviation,
    required this.punctualityRate,
    required this.firstTimeFixRate,
    required this.escalationRate,
  });

  String get formattedAverageDuration {
    final hours = averageDurationMinutes ~/ 60;
    final minutes = (averageDurationMinutes % 60).round();
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  factory TechnicianKpis.empty() {
    return const TechnicianKpis(
      assignedInterventions: 0,
      completedInterventions: 0,
      teamComparison: 0,
      averageDurationMinutes: 0,
      standardDeviation: 0,
      punctualityRate: 0,
      firstTimeFixRate: 0,
      escalationRate: 0,
    );
  }
}

/// Données pour le radar de compétences
class SkillRadarData {
  final String category;
  final int count;
  final double normalizedValue;

  const SkillRadarData({
    required this.category,
    required this.count,
    required this.normalizedValue,
  });
}

/// Données pour la courbe de charge
class WorkloadData {
  final DateTime weekStart;
  final double totalHours;
  final int interventionCount;
  final String weekLabel;

  const WorkloadData({
    required this.weekStart,
    required this.totalHours,
    this.interventionCount = 0,
    required this.weekLabel,
  });
}

/// Données des statistiques technicien
class TechnicianStatsData {
  final TechnicianKpis kpis;
  final List<SkillRadarData> skillsRadar;
  final List<WorkloadData> workloadCurve;
  final List<TopSiteData> topSites;
  final String? topCategory;

  const TechnicianStatsData({
    required this.kpis,
    required this.skillsRadar,
    required this.workloadCurve,
    this.topSites = const [],
    this.topCategory,
  });

  factory TechnicianStatsData.empty() {
    return TechnicianStatsData(
      kpis: TechnicianKpis.empty(),
      skillsRadar: const [],
      workloadCurve: const [],
    );
  }
}

/// Données de site détaillées
class SiteDetailsData {
  final String siteId;
  final String siteName;
  final String clientName;
  final String? address;
  final int totalInterventions;
  final double? averageResolutionTime;
  final List<SiteInterventionItem> interventionHistory;

  const SiteDetailsData({
    required this.siteId,
    required this.siteName,
    required this.clientName,
    this.address,
    required this.totalInterventions,
    this.averageResolutionTime,
    required this.interventionHistory,
  });
}

/// Élément d'historique d'intervention pour un site
class SiteInterventionItem {
  final String id;
  final DateTime date;
  final String type;
  final String technicianName;
  final String status;
  final String? source;
  final int durationMinutes;

  const SiteInterventionItem({
    required this.id,
    required this.date,
    required this.type,
    required this.technicianName,
    required this.status,
    this.source,
    required this.durationMinutes,
  });
}
