import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../data/local/app_database.dart';
import '../../../data/local/tables/cri_service_table.dart';
import '../../../data/local/tables/cri_projet_table.dart';

/// Service de génération CSV pour les exports Dashboard
class DashboardCsvService {
  final AppDatabase _database;

  DashboardCsvService(this._database);

  /// Exporte toutes les interventions dans une période donnée
  Future<File> exportInterventions({
    required DateTime startDate,
    required DateTime endDate,
    String? interventionType,
    String? status,
  }) async {
    final criServices = await _database.getAllCriService();
    final criProjets = await _database.getAllCriProjet();

    // Filtrer par période
    final filteredServices = criServices.where((CriService cri) {
      final date = cri.interventionDate;
      return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final filteredProjets = criProjets.where((CriProjet cri) {
      final date = cri.interventionDate;
      return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Créer les données CSV
    final List<List<dynamic>> rows = [
      [
        'Date',
        'Type',
        'Numéro',
        'Client',
        'Site',
        'Technicien',
        'Durée (h)',
        'Statut',
      ],
    ];

    // Ajouter les CRI Service
    for (final CriService cri in filteredServices) {
      rows.add([
        DateFormat('dd/MM/yyyy').format(cri.interventionDate),
        'Service',
        cri.ticketNumber,
        cri.clientName,
        cri.site,
        cri.technicianName,
        (cri.interventionDurationMinutes / 60).toStringAsFixed(2),
        ResolutionStatus.fromString(cri.resolutionStatus).label,
      ]);
    }

    // Ajouter les CRI Projet
    for (final CriProjet cri in filteredProjets) {
      rows.add([
        DateFormat('dd/MM/yyyy').format(cri.interventionDate),
        'Projet',
        cri.projectNumber,
        cri.clientName,
        cri.site,
        cri.technicianName,
        (cri.interventionDurationMinutes / 60).toStringAsFixed(2),
        ProjectStatus.fromString(cri.projectStatus).label,
      ]);
    }

    // Générer le CSV avec point-virgule comme délimiteur
    final csv = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);

    // Sauvegarder
    final period =
        '${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}';
    return await _saveCSV(csv, 'interventions_$period', 'Dashboard');
  }

  /// Exporte la synthèse des KPI
  Future<File> exportKPISynthesis({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final criServices = await _database.getAllCriService();
    final criProjets = await _database.getAllCriProjet();

    // Filtrer par période
    final filteredServices = criServices.where((CriService cri) {
      final date = cri.interventionDate;
      return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final filteredProjets = criProjets.where((CriProjet cri) {
      final date = cri.interventionDate;
      return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final totalInterventions = filteredServices.length + filteredProjets.length;

    // Sites actifs
    final sites = <String>{};
    for (final CriService cri in filteredServices) {
      sites.add(cri.site);
    }
    for (final CriProjet cri in filteredProjets) {
      sites.add(cri.site);
    }

    // Durée moyenne
    int totalDuration = 0;
    for (final CriService cri in filteredServices) {
      totalDuration += cri.interventionDurationMinutes;
    }
    for (final CriProjet cri in filteredProjets) {
      totalDuration += cri.interventionDurationMinutes;
    }
    final avgDuration = totalInterventions > 0
        ? (totalDuration / totalInterventions / 60).toStringAsFixed(2)
        : '0';

    // Taux de complétion (interventions non brouillon)
    final completed =
        filteredServices.where((c) => !c.isDraft).length +
        filteredProjets.where((c) => !c.isDraft).length;
    final completionRate = totalInterventions > 0
        ? ((completed / totalInterventions) * 100).toStringAsFixed(1)
        : '0';

    // Créer les données CSV
    final List<List<dynamic>> rows = [
      ['Indicateur', 'Valeur'],
      [
        'Période',
        '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
      ],
      ['Total interventions', totalInterventions],
      ['Sites actifs', sites.length],
      ['Durée moyenne (h)', avgDuration],
      ['Taux de complétion (%)', completionRate],
    ];

    final csv = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);

    final period =
        '${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}';
    return await _saveCSV(csv, 'kpi_synthese_$period', 'Dashboard');
  }

  /// Exporte le top des sites
  Future<File> exportTopSites({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    final criServices = await _database.getAllCriService();
    final criProjets = await _database.getAllCriProjet();

    // Filtrer par période
    final filteredServices = criServices.where((CriService cri) {
      final date = cri.interventionDate;
      return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final filteredProjets = criProjets.where((CriProjet cri) {
      final date = cri.interventionDate;
      return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Agréger par site
    final Map<String, SiteStats> siteStats = {};

    for (final CriService cri in filteredServices) {
      if (!siteStats.containsKey(cri.site)) {
        siteStats[cri.site] = SiteStats(cri.site);
      }
      siteStats[cri.site]!.addIntervention(cri.interventionDurationMinutes);
      if (ResolutionStatus.fromString(cri.resolutionStatus) ==
          ResolutionStatus.resolu) {
        siteStats[cri.site]!.addResolved();
      }
    }

    for (final CriProjet cri in filteredProjets) {
      if (!siteStats.containsKey(cri.site)) {
        siteStats[cri.site] = SiteStats(cri.site);
      }
      siteStats[cri.site]!.addIntervention(cri.interventionDurationMinutes);
      if (ProjectStatus.fromString(cri.projectStatus) ==
          ProjectStatus.termine) {
        siteStats[cri.site]!.addResolved();
      }
    }

    // Trier par nombre d'interventions
    final sortedSites = siteStats.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    // Prendre le top N
    final topSites = sortedSites.take(limit).toList();

    // Créer les données CSV
    final List<List<dynamic>> rows = [
      [
        'Rang',
        'Nom du site',
        'Nombre d\'interventions',
        'Durée totale (h)',
        'Durée moyenne (h)',
        'Taux de résolution (%)',
      ],
    ];

    for (var i = 0; i < topSites.length; i++) {
      final site = topSites[i];
      rows.add([
        i + 1,
        site.name,
        site.count,
        (site.totalDuration / 60).toStringAsFixed(2),
        (site.avgDuration / 60).toStringAsFixed(2),
        site.resolutionRate.toStringAsFixed(1),
      ]);
    }

    final csv = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);

    final period =
        '${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}';
    return await _saveCSV(csv, 'top_sites_$period', 'Dashboard');
  }

  /// Exporte tout (interventions + KPI + top sites)
  Future<List<File>> exportAll({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await Future.wait([
      exportInterventions(startDate: startDate, endDate: endDate),
      exportKPISynthesis(startDate: startDate, endDate: endDate),
      exportTopSites(startDate: startDate, endDate: endDate),
    ]);
  }

  // ============================================================
  // Utilitaires
  // ============================================================

  Future<File> _saveCSV(String csv, String filename, String subfolder) async {
    final output = await getApplicationDocumentsDirectory();
    final exportDir = Directory(
      p.join(output.path, 'Novadis', 'Exports', subfolder),
    );

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final file = File(
      p.join(
        exportDir.path,
        '${filename}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
      ),
    );

    // Ajouter le BOM UTF-8 pour Excel Windows
    final utf8Bom = [0xEF, 0xBB, 0xBF];
    final bytes = utf8.encode(csv);
    await file.writeAsBytes([...utf8Bom, ...bytes]);

    return file;
  }
}

/// Classe utilitaire pour les statistiques par site
class SiteStats {
  final String name;
  int count = 0;
  int totalDuration = 0;
  int resolvedCount = 0;

  SiteStats(this.name);

  void addIntervention(int durationMinutes) {
    count++;
    totalDuration += durationMinutes;
  }

  void addResolved() {
    resolvedCount++;
  }

  double get avgDuration => count > 0 ? totalDuration / count : 0;
  double get resolutionRate => count > 0 ? (resolvedCount / count) * 100 : 0;
}
