import 'package:novadis_cri/data/models/cri_service_model.dart';
import 'package:novadis_cri/data/models/cri_projet_model.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';
import 'package:novadis_cri/features/dashboard/services/kpi_calculator_service.dart';
import 'package:novadis_cri/data/local/tables/cri_service_table.dart';
import 'package:novadis_cri/data/local/tables/cri_projet_table.dart';

/// Repository pour les données du Dashboard
/// Fournit les données en combinant les CRI Service et Projet
class DashboardRepository {
  final KpiCalculatorService _kpiCalculator = KpiCalculatorService();

  // Données mock en mémoire pour la démo
  List<CriServiceModel>? _cachedServices;
  List<CriProjetModel>? _cachedProjets;

  /// Récupère toutes les données du dashboard
  Future<DashboardData> getDashboardData(DashboardPeriod period) async {
    // Simule un délai réseau
    await Future.delayed(const Duration(milliseconds: 500));

    final services = await _getAllServices();
    final projets = await _getAllProjets();

    final kpis = DashboardKpis(
      totalInterventions: _kpiCalculator.calculateTotalInterventions(
        services,
        projets,
        period,
      ),
      activeSites: _kpiCalculator.calculateActiveSites(
        services,
        projets,
        period,
      ),
      averageDurationMinutes: _kpiCalculator.calculateAverageDuration(
        services,
        projets,
        period,
      ),
      completionRate: _kpiCalculator.calculateCompletionRate(
        services,
        projets,
        period,
      ),
      previousCompletionRate: _kpiCalculator.calculatePreviousCompletionRate(
        services,
        projets,
        period,
      ),
    );

    return DashboardData(
      kpis: kpis,
      timeEvolution: _kpiCalculator.calculateTimeEvolution(services, projets),
      typeDistribution: _kpiCalculator.calculateTypeDistribution(
        services,
        projets,
        period,
      ),
      topSites: _kpiCalculator.calculateTopSites(services, projets, period),
      lastUpdated: DateTime.now(),
    );
  }

  /// Récupère les statistiques d'un technicien
  Future<TechnicianStatsData> getTechnicianStats(
    String technicianName,
    DashboardPeriod period,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final services = await _getAllServices();
    final projets = await _getAllProjets();

    // Filtrer les services du technicien
    final techServices = services
        .where((s) => s.technicianName == technicianName)
        .toList();
    final techProjets = projets
        .where((p) => p.technicianName == technicianName)
        .toList();

    // Calcul des KPIs individuels
    final assignedCount = _kpiCalculator.calculateTotalInterventions(
      techServices,
      techProjets,
      period,
    );

    final teamAverage = _kpiCalculator.calculateTeamAverage(services, period);
    final teamComparison = teamAverage > 0
        ? (assignedCount / teamAverage) * 100
        : 0;

    // Calcul de la distribution par type pour le radar
    final typeCounts = <String, int>{};
    for (final service in techServices) {
      if (service.interventionDate.isAfter(period.startDate)) {
        final type = service.requestType.label;
        typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      }
    }

    final kpis = TechnicianKpis(
      assignedInterventions: assignedCount,
      completedInterventions: techServices
          .where(
            (s) =>
                s.resolutionStatus == ResolutionStatus.resolu ||
                s.resolutionStatus == ResolutionStatus.partiellementResolu,
          )
          .length,
      teamComparison: teamComparison.toDouble(),
      averageDurationMinutes: _kpiCalculator.calculateAverageDuration(
        techServices,
        techProjets,
        period,
      ),
      standardDeviation: 0, // Simplifié pour la démo
      punctualityRate: 85, // Mock pour la démo
      averageSatisfaction: _kpiCalculator.calculateSatisfactionScore(
        services,
        technicianName,
        period,
      ),
      firstTimeFixRate: _kpiCalculator.calculateFirstTimeFixRate(
        services,
        technicianName,
        period,
      ),
      escalationRate: _calculateEscalationRate(techServices, period),
    );

    final skillsRadar = _kpiCalculator.normalizeRadarData(typeCounts);
    final workloadCurve = _kpiCalculator.calculateWorkloadCurve(
      services,
      technicianName,
      period,
    );

    String? topCategory;
    if (typeCounts.isNotEmpty) {
      final sorted = typeCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topCategory = sorted.first.key;
    }

    return TechnicianStatsData(
      kpis: kpis,
      skillsRadar: skillsRadar,
      workloadCurve: workloadCurve,
      topCategory: topCategory,
    );
  }

  /// Récupère la liste des techniciens
  Future<List<TechnicianModel>> getTechnicians() async {
    await Future.delayed(const Duration(milliseconds: 200));

    final services = await _getAllServices();
    final projets = await _getAllProjets();

    final technicianSet = <String>{};
    for (final service in services) {
      technicianSet.add(service.technicianName);
    }
    for (final projet in projets) {
      technicianSet.add(projet.technicianName);
    }

    return technicianSet.map((name) {
      return TechnicianModel(
        id: name.replaceAll(' ', '_').toLowerCase(),
        name: name,
        email: '${name.replaceAll(' ', '.').toLowerCase()}@novadis.fr',
      );
    }).toList();
  }

  /// Récupère les détails d'un site
  Future<SiteDetailsData> getSiteDetails(String siteId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final services = await _getAllServices();
    final projets = await _getAllProjets();

    final siteServices = services.where((s) => s.site == siteId).toList();
    final siteProjets = projets.where((p) => p.site == siteId).toList();

    final allInterventions = <SiteInterventionItem>[];

    for (final service in siteServices) {
      allInterventions.add(
        SiteInterventionItem(
          id: service.id,
          date: service.interventionDate,
          type: service.requestType.label,
          technicianName: service.technicianName,
          status: service.resolutionStatus.label,
          durationMinutes: service.interventionDurationMinutes,
        ),
      );
    }

    for (final projet in siteProjets) {
      allInterventions.add(
        SiteInterventionItem(
          id: projet.id,
          date: projet.interventionDate,
          type: projet.interventionType.label,
          technicianName: projet.technicianName,
          status: projet.projectStatus.label,
          durationMinutes: projet.durationMinutes,
        ),
      );
    }

    allInterventions.sort((a, b) => b.date.compareTo(a.date));

    String siteName = siteId;
    String clientName = '';
    String? address;

    if (siteServices.isNotEmpty) {
      siteName = siteServices.first.site;
      clientName = siteServices.first.clientName;
      address = siteServices.first.address;
    } else if (siteProjets.isNotEmpty) {
      siteName = siteProjets.first.site;
      clientName = siteProjets.first.clientName;
      address = siteProjets.first.address;
    }

    // Calcul de la satisfaction moyenne
    double? avgSatisfaction;
    final satisfactionScores = siteServices
        .where((s) => s.clientSatisfaction != null)
        .map((s) => s.clientSatisfaction!.rating)
        .toList();
    if (satisfactionScores.isNotEmpty) {
      avgSatisfaction =
          satisfactionScores.reduce((a, b) => a + b) /
          satisfactionScores.length;
    }

    // Calcul du temps moyen de résolution
    double? avgResolutionTime;
    if (allInterventions.isNotEmpty) {
      final durations = allInterventions.map((i) => i.durationMinutes).toList();
      avgResolutionTime =
          durations.reduce((a, b) => a + b) / durations.length.toDouble();
    }

    return SiteDetailsData(
      siteId: siteId,
      siteName: siteName,
      clientName: clientName,
      address: address,
      totalInterventions: allInterventions.length,
      averageResolutionTime: avgResolutionTime,
      averageSatisfaction: avgSatisfaction,
      interventionHistory: allInterventions,
    );
  }

  /// Calcule le taux d'escalade
  double _calculateEscalationRate(
    List<CriServiceModel> services,
    DashboardPeriod period,
  ) {
    final filteredServices = services
        .where((s) => s.interventionDate.isAfter(period.startDate))
        .toList();

    if (filteredServices.isEmpty) return 0;

    final escalated = filteredServices
        .where((s) => s.resolutionStatus == ResolutionStatus.escaladeNiveau2)
        .length;

    return (escalated / filteredServices.length) * 100;
  }

  /// Récupère tous les CRI Service (mock data)
  Future<List<CriServiceModel>> _getAllServices() async {
    if (_cachedServices != null) return _cachedServices!;
    _cachedServices = _generateMockServices();
    return _cachedServices!;
  }

  /// Récupère tous les CRI Projet (mock data)
  Future<List<CriProjetModel>> _getAllProjets() async {
    if (_cachedProjets != null) return _cachedProjets!;
    _cachedProjets = _generateMockProjets();
    return _cachedProjets!;
  }

  /// Génère des données mock de CRI Service
  List<CriServiceModel> _generateMockServices() {
    final now = DateTime.now();
    final services = <CriServiceModel>[];

    final sites = [
      ('Site Paris Nord', 'Client A'),
      ('Site Lyon Centre', 'Client B'),
      ('Site Marseille Sud', 'Client C'),
      ('Site Bordeaux Ouest', 'Client D'),
      ('Site Lille Est', 'Client E'),
      ('Site Nantes Port', 'Client F'),
      ('Site Strasbourg', 'Client G'),
    ];

    final technicians = [
      'Jean Dupont',
      'Marie Martin',
      'Pierre Bernard',
      'Sophie Leroy',
      'Lucas Moreau',
    ];

    final requestTypes = ServiceRequestType.values;
    final priorities = ServicePriority.values;
    final resolutions = [
      ResolutionStatus.resolu,
      ResolutionStatus.resolu,
      ResolutionStatus.resolu,
      ResolutionStatus.partiellementResolu,
      ResolutionStatus.nonResolu,
      ResolutionStatus.escaladeNiveau2,
    ];
    final satisfactions = ClientSatisfaction.values;

    // Générer 100 interventions sur les 6 derniers mois
    for (int i = 0; i < 100; i++) {
      final daysAgo = (i * 1.8).round(); // Répartir sur ~180 jours
      final interventionDate = now.subtract(Duration(days: daysAgo));
      final startTime = DateTime(
        interventionDate.year,
        interventionDate.month,
        interventionDate.day,
        8 + (i % 8),
        (i * 17) % 60,
      );
      final durationMinutes = 30 + (i % 120);
      final endTime = startTime.add(Duration(minutes: durationMinutes));

      final siteData = sites[i % sites.length];
      final technician = technicians[i % technicians.length];

      services.add(
        CriServiceModel(
          id: 'service_$i',
          interventionDate: interventionDate,
          startTime: startTime,
          endTime: endTime,
          ticketNumber: 'TICK-${now.year}-${10000 + i}',
          clientName: siteData.$2,
          site: siteData.$1,
          address: '${i * 10} Rue Example, 75001 Paris',
          clientContact: 'Contact ${i % 10}',
          phone: '01 23 45 67 ${(i % 100).toString().padLeft(2, '0')}',
          requestType: requestTypes[i % requestTypes.length],
          priority: priorities[i % priorities.length],
          requestDescription: 'Description de la demande #$i',
          diagnosticPerformed: 'Diagnostic effectué pour intervention #$i',
          identifiedCause: 'Cause identifiée #$i',
          actionsPerformed: 'Actions réalisées pour #$i',
          replacedParts: i % 3 == 0 ? 'Pièces remplacées #$i' : null,
          interventionDurationMinutes: durationMinutes,
          resolutionStatus: resolutions[i % resolutions.length],
          testsPerformed: 'Tests effectués #$i',
          recommendations: i % 2 == 0 ? 'Recommandations #$i' : null,
          additionalInterventionRequired: i % 7 == 0,
          technicianName: technician,
          clientSatisfaction: satisfactions[i % satisfactions.length],
          createdAt: interventionDate,
          isDraft: false,
          syncStatus: 'synced',
        ),
      );
    }

    return services;
  }

  /// Génère des données mock de CRI Projet
  List<CriProjetModel> _generateMockProjets() {
    final now = DateTime.now();
    final projets = <CriProjetModel>[];

    final sites = [
      ('Site Paris Centre', 'Client H'),
      ('Site Lyon Tech', 'Client I'),
      ('Site Marseille Port', 'Client J'),
    ];

    final technicians = ['Jean Dupont', 'Marie Martin', 'Pierre Bernard'];

    final phases = ProjectPhase.values;
    final interventionTypes = ProjetInterventionType.values;
    final statuses = [
      ProjectStatus.termine,
      ProjectStatus.termine,
      ProjectStatus.enCours,
      ProjectStatus.enAttenteValidation,
    ];

    // Générer 30 projets sur les 6 derniers mois
    for (int i = 0; i < 30; i++) {
      final daysAgo = (i * 6).round();
      final interventionDate = now.subtract(Duration(days: daysAgo));
      final startTime = DateTime(
        interventionDate.year,
        interventionDate.month,
        interventionDate.day,
        9,
        0,
      );
      final endTime = startTime.add(Duration(hours: 2 + (i % 4)));

      final siteData = sites[i % sites.length];
      final technician = technicians[i % technicians.length];

      projets.add(
        CriProjetModel(
          id: 'projet_$i',
          interventionDate: interventionDate,
          startTime: startTime,
          endTime: endTime,
          clientName: siteData.$2,
          site: siteData.$1,
          address: '${i * 5} Boulevard Projet, 69001 Lyon',
          clientContact: 'Chef Projet ${i % 5}',
          phone: '04 56 78 90 ${(i % 100).toString().padLeft(2, '0')}',
          email: 'projet$i@client.fr',
          projectName: 'Projet Installation #$i',
          projectNumber:
              'PRJ-${now.year}-${(i + 1).toString().padLeft(3, '0')}',
          projectPhase: phases[i % phases.length],
          interventionType: interventionTypes[i % interventionTypes.length],
          workDescription: 'Description des travaux pour le projet #$i',
          materialsUsed: 'Matériaux utilisés #$i',
          problemsEncountered: i % 3 == 0 ? 'Problèmes rencontrés #$i' : null,
          solutionsProvided: i % 3 == 0 ? 'Solutions apportées #$i' : null,
          actionsToDo: i % 2 == 0 ? 'Actions à faire #$i' : null,
          projectStatus: statuses[i % statuses.length],
          technicianName: technician,
          createdAt: interventionDate,
          isDraft: false,
          syncStatus: 'synced',
        ),
      );
    }

    return projets;
  }

  /// Efface le cache pour forcer un rechargement
  void clearCache() {
    _cachedServices = null;
    _cachedProjets = null;
  }
}
