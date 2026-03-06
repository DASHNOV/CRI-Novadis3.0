import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../data/local/app_database.dart';
import '../../../data/local/tables/cri_service_table.dart';
import '../../../data/local/tables/cri_projet_table.dart';
import 'base_service_interfaces.dart';

/// Service de génération CSV pour les statistiques d'un technicien (Version Native)
class TechnicianStatsCsvService implements BaseTechnicianStatsCsvService {
  final AppDatabase _database;

  TechnicianStatsCsvService(this._database);

  @override
  Future<dynamic> exportTechnicianStats({
    required String technicianName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final criServices = await _database.getAllCriService();
    final criProjets = await _database.getAllCriProjet();

    final filteredServices = criServices.where((cri) => 
      cri.technicianName == technicianName &&
      cri.interventionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
      cri.interventionDate.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();

    final filteredProjets = criProjets.where((cri) => 
      cri.technicianName == technicianName &&
      cri.interventionDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
      cri.interventionDate.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();

    final List<List<dynamic>> rows = [
      ['Rapport d\'activité de $technicianName'],
      ['Période', '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}'],
      [],
      ['Date', 'Type', 'Numéro', 'Client', 'Site', 'Durée (h)', 'Statut'],
    ];

    for (final cri in filteredServices) {
      rows.add([DateFormat('dd/MM/yyyy').format(cri.interventionDate), 'Service', cri.ticketNumber, cri.clientName, cri.site, (cri.interventionDurationMinutes / 60).toStringAsFixed(2), ResolutionStatus.fromString(cri.resolutionStatus).label]);
    }

    for (final cri in filteredProjets) {
      rows.add([DateFormat('dd/MM/yyyy').format(cri.interventionDate), 'Projet', cri.projectNumber, cri.clientName, cri.site, (cri.interventionDurationMinutes / 60).toStringAsFixed(2), ProjectStatus.fromString(cri.projectStatus).label]);
    }

    final csv = const ListToCsvConverter(fieldDelimiter: ';').convert(rows);
    return await _saveCSV(csv, 'stats_tech_${technicianName.replaceAll(' ', '_')}', 'Techniciens');
  }

  Future<dynamic> _saveCSV(String csv, String filename, String subfolder) async {
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


