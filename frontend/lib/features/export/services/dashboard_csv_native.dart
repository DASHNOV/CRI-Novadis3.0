import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../data/local/app_database.dart';
import '../../../data/local/tables/cri_service_table.dart';
import '../../../data/local/tables/cri_projet_table.dart';

import 'dashboard_csv_service.dart';

/// Service de génération CSV pour les exports Dashboard (Version Native)
class DashboardCsvService implements BaseDashboardCsvService {
  final AppDatabase _database;

  DashboardCsvService(this._database);

  @override
  Future<File> exportInterventions({
    required DateTime startDate,
    required DateTime endDate,
    String? interventionType,
    String? status,
  }) async {
    final criServices = await _database.getAllCriService();
    final criProjets = await _database.getAllCriProjet();

    final filteredServices = criServices.where((cri) {
      final date = cri.interventionDate;
      return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final filteredProjets = criProjets.where((cri) {
      final date = cri.interventionDate;
      return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final List<List<dynamic>> rows = [['Date', 'Type', 'Numéro', 'Client', 'Site', 'Technicien', 'Durée (h)', 'Statut']];

    for (final cri in filteredServices) {
      rows.add([DateFormat('dd/MM/yyyy').format(cri.interventionDate), 'Service', cri.ticketNumber, cri.clientName, cri.site, cri.technicianName, (cri.interventionDurationMinutes / 60).toStringAsFixed(2), ResolutionStatus.fromString(cri.resolutionStatus).label]);
    }

    for (final cri in filteredProjets) {
      rows.add([DateFormat('dd/MM/yyyy').format(cri.interventionDate), 'Projet', cri.projectNumber, cri.clientName, cri.site, cri.technicianName, (cri.interventionDurationMinutes / 60).toStringAsFixed(2), ProjectStatus.fromString(cri.projectStatus).label]);
    }

    final csv = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);
    final period = '${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}';
    return await _saveCSV(csv, 'interventions_$period', 'Dashboard');
  }

  Future<File> exportKPISynthesis({required DateTime startDate, required DateTime endDate}) async {
    final criServices = await _database.getAllCriService();
    final criProjets = await _database.getAllCriProjet();

    final filteredServices = criServices.where((cri) {
      final date = cri.interventionDate;
      return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final filteredProjets = criProjets.where((cri) {
      final date = cri.interventionDate;
      return date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final total = filteredServices.length + filteredProjets.length;
    final sites = <String>{...filteredServices.map((e) => e.site), ...filteredProjets.map((e) => e.site)};
    
    int totalDur = 0;
    for (var c in filteredServices) totalDur += c.interventionDurationMinutes;
    for (var c in filteredProjets) totalDur += c.interventionDurationMinutes;
    
    final completed = filteredServices.where((c) => !c.isDraft).length + filteredProjets.where((c) => !c.isDraft).length;

    final List<List<dynamic>> rows = [
      ['Indicateur', 'Valeur'],
      ['Période', '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}'],
      ['Total interventions', total],
      ['Sites actifs', sites.length],
      ['Durée moyenne (h)', total > 0 ? (totalDur / total / 60).toStringAsFixed(2) : '0'],
      ['Taux de complétion (%)', total > 0 ? ((completed / total) * 100).toStringAsFixed(1) : '0'],
    ];

    final csv = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);
    final period = '${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}';
    return await _saveCSV(csv, 'kpi_synthese_$period', 'Dashboard');
  }

  Future<File> exportTopSites({required DateTime startDate, required DateTime endDate, int limit = 10}) async {
    final criServices = await _database.getAllCriService();
    final criProjets = await _database.getAllCriProjet();

    final filteredServices = criServices.where((cri) => cri.interventionDate.isAfter(startDate.subtract(const Duration(days: 1))) && cri.interventionDate.isBefore(endDate.add(const Duration(days: 1)))).toList();
    final filteredProjets = criProjets.where((cri) => cri.interventionDate.isAfter(startDate.subtract(const Duration(days: 1))) && cri.interventionDate.isBefore(endDate.add(const Duration(days: 1)))).toList();

    final Map<String, SiteStats> stats = {};
    for (var cri in filteredServices) {
      stats.putIfAbsent(cri.site, () => SiteStats(cri.site)).addIntervention(cri.interventionDurationMinutes);
      if (ResolutionStatus.fromString(cri.resolutionStatus) == ResolutionStatus.resolu) stats[cri.site]!.addResolved();
    }
    for (var cri in filteredProjets) {
      stats.putIfAbsent(cri.site, () => SiteStats(cri.site)).addIntervention(cri.interventionDurationMinutes);
      if (ProjectStatus.fromString(cri.projectStatus) == ProjectStatus.termine) stats[cri.site]!.addResolved();
    }

    final sorted = stats.values.toList()..sort((a, b) => b.count.compareTo(a.count));
    final top = sorted.take(limit).toList();

    final List<List<dynamic>> rows = [['Rang', 'Nom du site', 'Nombre d\'interventions', 'Durée totale (h)', 'Durée moyenne (h)', 'Taux de résolution (%)']];
    for (var i = 0; i < top.length; i++) {
      final s = top[i];
      rows.add([i + 1, s.name, s.count, (s.totalDuration / 60).toStringAsFixed(2), (s.avgDuration / 60).toStringAsFixed(2), s.resolutionRate.toStringAsFixed(1)]);
    }

    final csv = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);
    final period = '${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}';
    return await _saveCSV(csv, 'top_sites_$period', 'Dashboard');
  }

  Future<List<File>> exportAll({required DateTime startDate, required DateTime endDate}) async {
    return await Future.wait([
      exportInterventions(startDate: startDate, endDate: endDate),
      exportKPISynthesis(startDate: startDate, endDate: endDate),
      exportTopSites(startDate: startDate, endDate: endDate),
    ]);
  }

  Future<File> _saveCSV(String csv, String filename, String subfolder) async {
    final output = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(output.path, 'Novadis', 'Exports', subfolder));
    if (!await exportDir.exists()) await exportDir.create(recursive: true);
    final file = File(p.join(exportDir.path, '${filename}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv'));
    final utf8Bom = [0xEF, 0xBB, 0xBF];
    final bytes = utf8.encode(csv);
    await file.writeAsBytes([...utf8Bom, ...bytes]);
    return file;
  }
}

class SiteStats {
  final String name;
  int count = 0;
  int totalDuration = 0;
  int resolvedCount = 0;
  SiteStats(this.name);
  void addIntervention(int d) { count++; totalDuration += d; }
  void addResolved() { resolvedCount++; }
  double get avgDuration => count > 0 ? totalDuration / count : 0;
  double get resolutionRate => count > 0 ? (resolvedCount / count) * 100 : 0;
}

BaseDashboardCsvService createDashboardCsvService(AppDatabase database) => DashboardCsvService(database);


