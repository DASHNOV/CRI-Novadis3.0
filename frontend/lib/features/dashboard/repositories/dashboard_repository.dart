import 'package:novadis_cri/data/models/cri_service_model.dart';
import 'package:novadis_cri/data/models/cri_projet_model.dart';
import 'package:novadis_cri/features/dashboard/models/dashboard_models.dart';
import 'package:novadis_cri/features/dashboard/services/kpi_calculator_service.dart';
import 'package:novadis_cri/data/local/app_database.dart';
import 'package:novadis_cri/data/local/tables/cri_service_table.dart';
import 'package:novadis_cri/data/local/tables/cri_projet_table.dart';
import 'package:novadis_cri/data/repositories/cri_remote_repository.dart';

/// Repository pour les données du Dashboard
/// Fournit les données en combinant les CRI Service et Projet
class DashboardRepository {
  final KpiCalculatorService _kpiCalculator = KpiCalculatorService();
  final CriRemoteRepository _remoteRepository;
  final AppDatabase _db;

  DashboardRepository(this._remoteRepository, this._db);

  // Données en mémoire pour éviter de recharger trop souvent
  List<CriServiceModel>? _cachedServices;
  List<CriProjetModel>? _cachedProjets;

  /// Récupère toutes les données du dashboard
  Future<DashboardData> getDashboardData(DashboardPeriod period) async {
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
      realizedInterventions:
          services
              .where((s) => s.resolutionStatus == ResolutionStatus.resolu)
              .length +
          projets.where((p) => p.projectStatus == ProjectStatus.termine).length,
      pendingInterventions:
          services
              .where((s) => s.resolutionStatus == ResolutionStatus.nonResolu)
              .length +
          projets.where((p) => p.projectStatus == ProjectStatus.enCours).length,
    );

    // Récupérer les interventions récentes
    final allRecent = [
      ...services.map(
        (s) => RecentIntervention(
          id: s.id,
          technicianName: s.technicianName,
          date: s.interventionDate,
          durationMinutes: s.interventionDurationMinutes,
          status: s.resolutionStatus.label,
          type: 'Service',
          source: 'service',
        ),
      ),
      ...projets.map(
        (p) => RecentIntervention(
          id: p.id,
          technicianName: p.technicianName,
          date: p.interventionDate,
          durationMinutes: p.durationMinutes,
          status: p.projectStatus.label,
          type: 'Projet',
          source: 'projet',
        ),
      ),
    ];
    allRecent.sort((a, b) => b.date.compareTo(a.date));

    return DashboardData(
      kpis: kpis,
      timeEvolution: _kpiCalculator.calculateTimeEvolution(services, projets),
      typeDistribution: _kpiCalculator.calculateTypeDistribution(
        services,
        projets,
        period,
      ),
      topSites: _kpiCalculator.calculateTopSites(services, projets, period),
      recentInterventions: allRecent.take(15).toList(),
      lastUpdated: DateTime.now(),
    );
  }

  /// Récupère les statistiques d'un technicien
  Future<TechnicianStatsData> getTechnicianStats(
    String technicianName,
    DashboardPeriod period,
  ) async {
    final services = await _getAllServices();
    final projets = await _getAllProjets();

    final techServices = services
        .where((s) => s.technicianName == technicianName)
        .toList();
    final techProjets = projets
        .where((p) => p.technicianName == technicianName)
        .toList();

    final assignedCount = _kpiCalculator.calculateTotalInterventions(
      techServices,
      techProjets,
      period,
    );
    final teamAverage = _kpiCalculator.calculateTeamAverage(services, period);

    final kpis = TechnicianKpis(
      assignedInterventions: assignedCount,
      completedInterventions:
          techServices
              .where((s) => s.resolutionStatus == ResolutionStatus.resolu)
              .length +
          techProjets
              .where((p) => p.projectStatus == ProjectStatus.termine)
              .length,
      teamComparison: teamAverage > 0 ? (assignedCount / teamAverage) * 100 : 0,
      averageDurationMinutes: _kpiCalculator.calculateAverageDuration(
        techServices,
        techProjets,
        period,
      ),
      standardDeviation: 0,
      punctualityRate: 90,
      firstTimeFixRate: _kpiCalculator.calculateFirstTimeFixRate(
        services,
        technicianName,
        period,
      ),
      escalationRate: _calculateEscalationRate(techServices, period),
    );

    return TechnicianStatsData(
      kpis: kpis,
      skillsRadar: _kpiCalculator.normalizeRadarData({}), // À affiner
      workloadCurve: _kpiCalculator.calculateWorkloadCurve(
        services,
        technicianName,
        period,
      ),
      topSites: _kpiCalculator.calculateTopSites(
        techServices,
        techProjets,
        period,
      ),
    );
  }

  /// Récupère la liste des techniciens
  Future<List<TechnicianModel>> getTechnicians() async {
    final services = await _getAllServices();
    final projets = await _getAllProjets();

    final technicianSet = <String>{};
    for (final s in services) technicianSet.add(s.technicianName);
    for (final p in projets) technicianSet.add(p.technicianName);

    return technicianSet
        .map(
          (name) => TechnicianModel(
            id: name.toLowerCase().replaceAll(' ', '_'),
            name: name,
            email: '${name.toLowerCase().replaceAll(' ', '.')}@novadis.fr',
          ),
        )
        .toList();
  }

  /// Récupère les détails d'un site
  Future<SiteDetailsData> getSiteDetails(String siteId) async {
    final services = await _getAllServices();
    final projets = await _getAllProjets();

    final siteServices = services.where((s) => s.site == siteId).toList();
    final siteProjets = projets.where((p) => p.site == siteId).toList();

    final history = [
      ...siteServices.map(
        (s) => SiteInterventionItem(
          id: s.id,
          date: s.interventionDate,
          type: s.requestType.label,
          technicianName: s.technicianName,
          status: s.resolutionStatus.label,
          durationMinutes: s.interventionDurationMinutes,
          source: 'service',
        ),
      ),
      ...siteProjets.map(
        (p) => SiteInterventionItem(
          id: p.id,
          date: p.interventionDate,
          type: p.interventionType.label,
          technicianName: p.technicianName,
          status: p.projectStatus.label,
          durationMinutes: p.durationMinutes,
          source: 'projet',
        ),
      ),
    ];
    history.sort((a, b) => b.date.compareTo(a.date));

    String clientName = siteServices.isNotEmpty
        ? siteServices.first.clientName
        : (siteProjets.isNotEmpty
              ? siteProjets.first.clientName
              : 'Client Inconnu');

    return SiteDetailsData(
      siteId: siteId,
      siteName: siteId,
      clientName: clientName,
      totalInterventions: history.length,
      interventionHistory: history,
    );
  }

  double _calculateEscalationRate(
    List<CriServiceModel> services,
    DashboardPeriod period,
  ) {
    final filtered = services
        .where((s) => s.interventionDate.isAfter(period.startDate))
        .toList();
    if (filtered.isEmpty) return 0;
    final escalated = filtered
        .where((s) => s.resolutionStatus == ResolutionStatus.escaladeNiveau2)
        .length;
    return (escalated / filtered.length) * 100;
  }

  /// Récupère tous les CRI Service (Combinaison Local + Remote)
  Future<List<CriServiceModel>> _getAllServices() async {
    if (_cachedServices != null) return _cachedServices!;

    try {
      final localServices = await _db.getAllCriService();
      final List<CriServiceModel> localModels = localServices
          .map((s) => CriServiceModel.fromDb(s))
          .toList();

      final remoteData = await _remoteRepository.getAllCris();
      final remoteServices = remoteData.whereType<CriServiceModel>().toList();

      final Map<String, CriServiceModel> merged = {
        for (var s in localModels) s.id: s,
      };
      for (var s in remoteServices) {
        merged[s.id] = s;
      }

      _cachedServices = merged.values.toList();
      return _cachedServices!;
    } catch (e) {
      final localServices = await _db.getAllCriService();
      return localServices.map((s) => CriServiceModel.fromDb(s)).toList();
    }
  }

  /// Récupère tous les CRI Projet (Combinaison Local + Remote)
  Future<List<CriProjetModel>> _getAllProjets() async {
    if (_cachedProjets != null) return _cachedProjets!;

    try {
      final localProjets = await _db.getAllCriProjet();
      final List<CriProjetModel> localModels = localProjets
          .map((p) => CriProjetModel.fromDb(p))
          .toList();

      final remoteData = await _remoteRepository.getAllCris();
      final remoteProjets = remoteData.whereType<CriProjetModel>().toList();

      final Map<String, CriProjetModel> merged = {
        for (var p in localModels) p.id: p,
      };
      for (var p in remoteProjets) {
        merged[p.id] = p;
      }

      _cachedProjets = merged.values.toList();
      return _cachedProjets!;
    } catch (e) {
      final localProjets = await _db.getAllCriProjet();
      return localProjets.map((p) => CriProjetModel.fromDb(p)).toList();
    }
  }

  /// Efface le cache pour forcer un rechargement
  void clearCache() {
    _cachedServices = null;
    _cachedProjets = null;
  }
}
