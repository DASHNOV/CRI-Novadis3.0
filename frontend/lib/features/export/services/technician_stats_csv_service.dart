import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../data/local/app_database.dart';
import '../../../data/local/tables/cri_service_table.dart';
import '../../../data/local/tables/cri_projet_table.dart';

/// Service de génération CSV pour les statistiques technicien
class TechnicianStatsCsvService {
  final AppDatabase _database;

  TechnicianStatsCsvService(this._database);

  /// Exporte les statistiques complètes d'un technicien
  Future<File> exportTechnicianStats({
    required String technicianName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final criServices = await _database.getAllCriService();
    final criProjets = await _database.getAllCriProjet();

    // Filtrer par technicien et période
    final techServices = criServices.where((cri) {
      final date = cri.interventionDate;
      return cri.technicianName == technicianName &&
          date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    final techProjets = criProjets.where((cri) {
      final date = cri.interventionDate;
      return cri.technicianName == technicianName &&
          date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Calculer les statistiques
    final stats = _calculateStats(techServices, techProjets);

    // Créer le CSV avec plusieurs sections
    final List<List<dynamic>> rows = [];

    // Section 1: Synthèse
    rows.addAll([
      ['=== SYNTHÈSE ==='],
      ['Nom du technicien', technicianName],
      [
        'Période',
        '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
      ],
      ['Interventions totales', stats.totalInterventions],
      ['Interventions résolues', stats.resolvedInterventions],
      ['Durée moyenne (h)', stats.avgDuration.toStringAsFixed(2)],
      [
        'Taux résolution 1er passage (%)',
        stats.firstPassResolutionRate.toStringAsFixed(1),
      ],
      [], // Ligne vide
    ]);

    // Section 2: Détail des interventions
    rows.addAll([
      ['=== DÉTAIL DES INTERVENTIONS ==='],
      ['Date', 'Numéro', 'Type', 'Client', 'Site', 'Durée (h)', 'Statut'],
    ]);

    // Ajouter les CRI Service
    for (final cri in techServices) {
      rows.add([
        DateFormat('dd/MM/yyyy').format(cri.interventionDate),
        cri.ticketNumber,
        'Service - ${ServiceRequestType.fromString(cri.requestType).label}',
        cri.clientName,
        cri.site,
        (cri.interventionDurationMinutes / 60).toStringAsFixed(2),
        ResolutionStatus.fromString(cri.resolutionStatus).label,
      ]);
    }

    // Ajouter les CRI Projet
    for (final cri in techProjets) {
      rows.add([
        DateFormat('dd/MM/yyyy').format(cri.interventionDate),
        cri.projectNumber,
        'Projet - ${ProjetInterventionType.fromString(cri.interventionType).label}',
        cri.clientName,
        cri.site,
        (cri.interventionDurationMinutes / 60).toStringAsFixed(2),
        ProjectStatus.fromString(cri.projectStatus).label,
      ]);
    }

    rows.add([]); // Ligne vide

    // Section 3: Répartition par type
    rows.addAll([
      ['=== RÉPARTITION PAR TYPE ==='],
      ['Type d\'intervention', 'Nombre', 'Pourcentage', 'Durée moyenne (h)'],
    ]);

    // Répartition des types de service
    final serviceTypeStats = _calculateServiceTypeStats(techServices);
    for (final entry in serviceTypeStats.entries) {
      rows.add([
        'Service - ${entry.key}',
        entry.value.count,
        '${((entry.value.count / stats.totalInterventions) * 100).toStringAsFixed(1)}%',
        (entry.value.avgDuration / 60).toStringAsFixed(2),
      ]);
    }

    // Répartition des types de projet
    final projetTypeStats = _calculateProjetTypeStats(techProjets);
    for (final entry in projetTypeStats.entries) {
      rows.add([
        'Projet - ${entry.key}',
        entry.value.count,
        '${((entry.value.count / stats.totalInterventions) * 100).toStringAsFixed(1)}%',
        (entry.value.avgDuration / 60).toStringAsFixed(2),
      ]);
    }

    // Générer le CSV avec point-virgule comme délimiteur
    final csv = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);

    // Sauvegarder
    final period =
        '${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}';
    final sanitizedName = technicianName.replaceAll(' ', '_').toLowerCase();
    return await _saveCSV(csv, 'stats_${sanitizedName}_$period');
  }

  /// Exporte une comparaison de plusieurs techniciens
  Future<File> exportTechniciansComparison({
    required List<String> technicianNames,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final List<List<dynamic>> rows = [
      [
        'Technicien',
        'Interventions totales',
        'Interventions résolues',
        'Durée moyenne (h)',
        'Satisfaction moyenne',
        'Taux résolution (%)',
      ],
    ];

    for (final name in technicianNames) {
      final criServices = await _database.getAllCriService();
      final criProjets = await _database.getAllCriProjet();

      final techServices = criServices.where((cri) {
        final date = cri.interventionDate;
        return cri.technicianName == name &&
            date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      final techProjets = criProjets.where((cri) {
        final date = cri.interventionDate;
        return cri.technicianName == name &&
            date.isAfter(startDate.subtract(const Duration(days: 1))) &&
            date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();

      final stats = _calculateStats(techServices, techProjets);

      rows.add([
        name,
        stats.totalInterventions,
        stats.resolvedInterventions,
        stats.avgDuration.toStringAsFixed(2),
        stats.firstPassResolutionRate.toStringAsFixed(1),
      ]);
    }

    final csv = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);

    final period =
        '${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}';
    return await _saveCSV(csv, 'comparaison_techniciens_$period');
  }

  // ============================================================
  // Calculs statistiques
  // ============================================================

  TechnicianStats _calculateStats(
    List<CriService> services,
    List<CriProjet> projets,
  ) {
    final total = services.length + projets.length;

    // Interventions résolues
    var resolved = 0;
    for (final CriService cri in services) {
      if (ResolutionStatus.fromString(cri.resolutionStatus) ==
              ResolutionStatus.resolu &&
          !cri.additionalInterventionRequired) {
        resolved++;
      }
    }
    for (final CriProjet cri in projets) {
      if (ProjectStatus.fromString(cri.projectStatus) ==
          ProjectStatus.termine) {
        resolved++;
      }
    }

    // Durée moyenne
    int totalDuration = 0;
    for (final CriService cri in services) {
      totalDuration += cri.interventionDurationMinutes;
    }
    for (final CriProjet cri in projets) {
      totalDuration += cri.interventionDurationMinutes;
    }
    final avgDuration = total > 0 ? totalDuration / total / 60 : 0.0;

    // Taux de résolution 1er passage
    final resolutionRate = total > 0 ? (resolved / total) * 100 : 0.0;

    return TechnicianStats(
      totalInterventions: total,
      resolvedInterventions: resolved,
      avgDuration: avgDuration,
      firstPassResolutionRate: resolutionRate,
    );
  }

  Map<String, TypeStats> _calculateServiceTypeStats(List<CriService> services) {
    final Map<String, TypeStats> stats = {};

    for (final cri in services) {
      final type = ServiceRequestType.fromString(cri.requestType).label;
      if (!stats.containsKey(type)) {
        stats[type] = TypeStats();
      }
      stats[type]!.addIntervention(cri.interventionDurationMinutes);
    }

    return stats;
  }

  Map<String, TypeStats> _calculateProjetTypeStats(List<CriProjet> projets) {
    final Map<String, TypeStats> stats = {};

    for (final cri in projets) {
      final type = ProjetInterventionType.fromString(
        cri.interventionType,
      ).label;
      if (!stats.containsKey(type)) {
        stats[type] = TypeStats();
      }
      stats[type]!.addIntervention(cri.interventionDurationMinutes);
    }

    return stats;
  }

  Future<File> _saveCSV(String csv, String filename) async {
    final output = await getApplicationDocumentsDirectory();
    final exportDir = Directory(
      p.join(output.path, 'Novadis', 'Exports', 'Techniciens'),
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

/// Statistiques d'un technicien
class TechnicianStats {
  final int totalInterventions;
  final int resolvedInterventions;
  final double avgDuration;
  final double firstPassResolutionRate;

  TechnicianStats({
    required this.totalInterventions,
    required this.resolvedInterventions,
    required this.avgDuration,
    required this.firstPassResolutionRate,
  });
}

/// Statistiques par type d'intervention
class TypeStats {
  int count = 0;
  int totalDuration = 0;

  void addIntervention(int durationMinutes) {
    count++;
    totalDuration += durationMinutes;
  }

  double get avgDuration => count > 0 ? totalDuration / count : 0;
}
