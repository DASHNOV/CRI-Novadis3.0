import 'dart:convert';
import 'dart:math';
import 'package:novadis_cri/data/local/tables/cri_projet_table.dart';
import 'package:novadis_cri/data/local/app_database.dart';
import 'package:drift/drift.dart';

/// Modèle de données pour un CRI Projet
class CriProjetModel {
  final String id;

  // Section 1: Général
  final DateTime interventionDate;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? endDate;

  // Section 2: Client
  final String clientName;
  final String site;
  final String? address;
  final String? ville;
  final String? codePostal;
  final String? pays;
  final String? clientContact;
  final String? phone;
  final String? email;

  // Section 3: Projet
  final String projectName;
  final String projectNumber;
  final ProjectPhase projectPhase;

  // Section 4: Intervention
  final ProjetInterventionType interventionType;
  final String workDescription;
  final String? materialsUsed;
  final String? problemsEncountered;
  final String? solutionsProvided;

  /// Logiciels utilisés durant l'intervention (au moins 1 requis à la soumission).
  final List<SoftwareEntry> softwares;

  // Section 5: Suivi
  final String? actionsToDo;
  final DateTime? nextInterventionDate;
  final ProjectStatus projectStatus;

  // Section 6: Validation
  final List<String> photos;
  final List<String> technicianNames;
  final List<String?> technicianSignatures;
  final String? clientSignature;
  final String? clientComments;

  // Métadonnées
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String syncStatus;
  final bool isDraft;

  CriProjetModel({
    required this.id,
    required this.interventionDate,
    required this.startTime,
    required this.endTime,
    this.endDate,
    required this.clientName,
    required this.site,
    this.address,
    this.ville,
    this.codePostal,
    this.pays,
    this.clientContact,
    this.phone,
    this.email,
    required this.projectName,
    required this.projectNumber,
    required this.projectPhase,
    required this.interventionType,
    required this.workDescription,
    this.materialsUsed,
    this.problemsEncountered,
    this.solutionsProvided,
    this.softwares = const [],
    this.actionsToDo,
    this.nextInterventionDate,
    required this.projectStatus,
    this.photos = const [],
    this.technicianNames = const [],
    this.technicianSignatures = const [],
    this.clientSignature,
    this.clientComments,
    required this.createdAt,
    this.updatedAt,
    this.syncStatus = 'pending',
    this.isDraft = true,
  });

  /// Dérive le numéro de département depuis le code postal (2 premiers chiffres).
  String get departement {
    final cp = codePostal?.trim() ?? '';
    if (cp.length >= 2) return cp.substring(0, 2);
    return '';
  }

  /// Nom du premier technicien (rétrocompatibilité avec le dashboard/export)
  String get technicianName => technicianNames.isNotEmpty ? technicianNames.first : '';

  /// Signature du premier technicien (rétrocompatibilité)
  String? get technicianSignature =>
      technicianSignatures.isNotEmpty ? technicianSignatures.first : null;

  static List<String> _parseNamesList(dynamic raw) {
    if (raw == null) return [];
    final s = raw.toString();
    if (s.startsWith('[')) {
      try {
        return List<String>.from(jsonDecode(s));
      } catch (_) {}
    }
    return s.isNotEmpty ? [s] : [];
  }

  static List<String?> _parseSignaturesList(dynamic raw) {
    if (raw == null) return [null];
    final s = raw.toString();
    if (s.isEmpty) return [null];
    if (s.startsWith('[')) {
      try {
        return (jsonDecode(s) as List).map((e) => e as String?).toList();
      } catch (_) {}
    }
    return [s];
  }

  /// Calcule la durée en tenant compte d'une date de fin différente (multi-jours)
  int get durationMinutes {
    final start = DateTime(
      interventionDate.year,
      interventionDate.month,
      interventionDate.day,
      startTime.hour,
      startTime.minute,
    );
    final effectiveEndDate = endDate ?? interventionDate;
    final end = DateTime(
      effectiveEndDate.year,
      effectiveEndDate.month,
      effectiveEndDate.day,
      endTime.hour,
      endTime.minute,
    );
    return end.difference(start).inMinutes;
  }

  /// Alias pour durationMinutes
  int get interventionDurationMinutes => durationMinutes;

  /// Formate la durée en jours, heures et minutes
  String get formattedDuration {
    final totalMinutes = durationMinutes;
    final days = totalMinutes ~/ (60 * 24);
    final hours = (totalMinutes % (60 * 24)) ~/ 60;
    final minutes = totalMinutes % 60;
    if (days > 0) {
      return '${days}j ${hours}h${minutes.toString().padLeft(2, '0')}';
    }
    if (hours > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    }
    return '${minutes}min';
  }

  /// Crée une copie avec des modifications
  CriProjetModel copyWith({
    String? id,
    DateTime? interventionDate,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? endDate,
    bool clearEndDate = false,
    String? clientName,
    String? site,
    String? address,
    String? ville,
    String? codePostal,
    String? pays,
    String? clientContact,
    String? phone,
    String? email,
    String? projectName,
    String? projectNumber,
    ProjectPhase? projectPhase,
    ProjetInterventionType? interventionType,
    String? workDescription,
    String? materialsUsed,
    String? problemsEncountered,
    String? solutionsProvided,
    List<SoftwareEntry>? softwares,
    String? actionsToDo,
    DateTime? nextInterventionDate,
    ProjectStatus? projectStatus,
    List<String>? photos,
    List<String>? technicianNames,
    List<String?>? technicianSignatures,
    String? clientSignature,
    String? clientComments,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    bool? isDraft,
  }) {
    return CriProjetModel(
      id: id ?? this.id,
      interventionDate: interventionDate ?? this.interventionDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      clientName: clientName ?? this.clientName,
      site: site ?? this.site,
      address: address ?? this.address,
      ville: ville ?? this.ville,
      codePostal: codePostal ?? this.codePostal,
      pays: pays ?? this.pays,
      clientContact: clientContact ?? this.clientContact,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      projectName: projectName ?? this.projectName,
      projectNumber: projectNumber ?? this.projectNumber,
      projectPhase: projectPhase ?? this.projectPhase,
      interventionType: interventionType ?? this.interventionType,
      workDescription: workDescription ?? this.workDescription,
      materialsUsed: materialsUsed ?? this.materialsUsed,
      problemsEncountered: problemsEncountered ?? this.problemsEncountered,
      solutionsProvided: solutionsProvided ?? this.solutionsProvided,
      softwares: softwares ?? this.softwares,
      actionsToDo: actionsToDo ?? this.actionsToDo,
      nextInterventionDate: nextInterventionDate ?? this.nextInterventionDate,
      projectStatus: projectStatus ?? this.projectStatus,
      photos: photos ?? this.photos,
      technicianNames: technicianNames ?? this.technicianNames,
      technicianSignatures: technicianSignatures ?? this.technicianSignatures,
      clientSignature: clientSignature ?? this.clientSignature,
      clientComments: clientComments ?? this.clientComments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      isDraft: isDraft ?? this.isDraft,
    );
  }

  /// Convertit en Map pour sérialisation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'interventionDate': interventionDate.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'clientName': clientName,
      'site': site,
      'address': address,
      'ville': ville,
      'codePostal': codePostal,
      'pays': pays,
      'clientContact': clientContact,
      'phone': phone,
      'email': email,
      'projectName': projectName,
      'projectNumber': projectNumber,
      'projectPhase': projectPhase.name,
      'interventionType': interventionType.name,
      'workDescription': workDescription,
      'materialsUsed': materialsUsed,
      'problemsEncountered': problemsEncountered,
      'solutionsProvided': solutionsProvided,
      'softwares': softwares.map((s) => s.toJson()).toList(),
      'actionsToDo': actionsToDo,
      'nextInterventionDate': nextInterventionDate?.toIso8601String(),
      'projectStatus': projectStatus.name,
      'photos': jsonEncode(photos),
      'technicianName': jsonEncode(technicianNames),
      'technicianSignature': jsonEncode(technicianSignatures),
      'clientSignature': clientSignature,
      'clientComments': clientComments,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'syncStatus': syncStatus,
      'isDraft': isDraft,
    };
  }

  /// Convertit pour insertion dans la base Drift
  CriProjetTableCompanion toDb() {
    return CriProjetTableCompanion(
      id: Value(id),
      interventionDate: Value(interventionDate),
      startTime: Value(startTime),
      endTime: Value(endTime),
      endDate: Value(endDate),
      clientName: Value(clientName),
      site: Value(site),
      address: Value(address),
      ville: Value(ville),
      codePostal: Value(codePostal),
      pays: Value(pays),
      clientContact: Value(clientContact),
      phone: Value(phone),
      email: Value(email),
      projectName: Value(projectName),
      projectNumber: Value(projectNumber.isEmpty ? '-' : projectNumber),
      projectPhase: Value(projectPhase.name),
      interventionType: Value(interventionType.name),
      workDescription: Value(workDescription),
      materialsUsed: Value(materialsUsed),
      problemsEncountered: Value(problemsEncountered),
      solutionsProvided: Value(solutionsProvided),
      softwares: Value(
        softwares.isEmpty
            ? null
            : jsonEncode(softwares.map((s) => s.toJson()).toList()),
      ),
      actionsToDo: Value(actionsToDo),
      nextInterventionDate: Value(nextInterventionDate),
      projectStatus: Value(projectStatus.name),
      photos: Value(jsonEncode(photos)),
      technicianName: Value(jsonEncode(technicianNames)),
      technicianSignature: Value(
        technicianSignatures.isEmpty ? null : jsonEncode(technicianSignatures),
      ),
      clientSignature: Value(clientSignature),
      clientComments: Value(clientComments),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      isDraft: Value(isDraft),
    );
  }

  factory CriProjetModel.fromDb(CriProjet db) {
    return CriProjetModel(
      id: db.id,
      interventionDate: db.interventionDate,
      startTime: db.startTime,
      endTime: db.endTime,
      endDate: db.endDate,
      clientName: db.clientName,
      site: db.site,
      address: db.address,
      ville: db.ville,
      codePostal: db.codePostal,
      pays: db.pays,
      clientContact: db.clientContact,
      phone: db.phone,
      email: db.email,
      projectName: db.projectName,
      projectNumber: db.projectNumber == '-' ? '' : db.projectNumber,
      projectPhase: ProjectPhase.fromString(db.projectPhase),
      interventionType: ProjetInterventionType.fromString(db.interventionType),
      workDescription: db.workDescription,
      materialsUsed: db.materialsUsed,
      problemsEncountered: db.problemsEncountered,
      solutionsProvided: db.solutionsProvided,
      softwares: db.softwares == null || db.softwares!.isEmpty
          ? const []
          : (jsonDecode(db.softwares!) as List)
              .map((e) => SoftwareEntry.fromJson(e as Map<String, dynamic>))
              .toList(),
      actionsToDo: db.actionsToDo,
      nextInterventionDate: db.nextInterventionDate,
      projectStatus: ProjectStatus.fromString(db.projectStatus),
      photos: db.photos != null
          ? List<String>.from(jsonDecode(db.photos!))
          : [],
      technicianNames: _parseNamesList(db.technicianName),
      technicianSignatures: _parseSignaturesList(db.technicianSignature),
      clientSignature: db.clientSignature,
      clientComments: db.clientComments,
      createdAt: db.createdAt,
      updatedAt: db.updatedAt,
      syncStatus: db.syncStatus,
      isDraft: db.isDraft,
    );
  }

  /// Crée depuis un Map
  factory CriProjetModel.fromJson(Map<String, dynamic> json) {
    return CriProjetModel(
      id: json['id'] as String,
      interventionDate: DateTime.parse(json['interventionDate'] as String),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      endDate: json['endDate'] != null
          ? DateTime.parse(json['endDate'] as String)
          : null,
      clientName: json['clientName'] as String,
      site: json['site'] as String,
      address: json['address'] as String?,
      ville: json['ville'] as String?,
      codePostal: json['codePostal'] as String?,
      pays: json['pays'] as String?,
      clientContact: json['clientContact'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      projectName: json['projectName'] as String,
      projectNumber: json['projectNumber'] as String,
      projectPhase: ProjectPhase.fromString(json['projectPhase'] as String),
      interventionType: ProjetInterventionType.fromString(
        json['interventionType'] as String,
      ),
      workDescription: json['workDescription'] as String,
      materialsUsed: json['materialsUsed'] as String?,
      problemsEncountered: json['problemsEncountered'] as String?,
      solutionsProvided: json['solutionsProvided'] as String?,
      softwares: json['softwares'] == null
          ? const []
          : (json['softwares'] is String
                  ? (jsonDecode(json['softwares'] as String) as List)
                  : (json['softwares'] as List))
              .map((e) => SoftwareEntry.fromJson(e as Map<String, dynamic>))
              .toList(),
      actionsToDo: json['actionsToDo'] as String?,
      nextInterventionDate: json['nextInterventionDate'] != null
          ? DateTime.parse(json['nextInterventionDate'] as String)
          : null,
      projectStatus: ProjectStatus.fromString(json['projectStatus'] as String),
      photos: json['photos'] != null
          ? List<String>.from(jsonDecode(json['photos'] as String))
          : [],
      technicianNames: _parseNamesList(json['technicianName']),
      technicianSignatures: _parseSignaturesList(json['technicianSignature']),
      clientSignature: json['clientSignature'] as String?,
      clientComments: json['clientComments'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String).toLocal()
          : null,
      syncStatus: json['syncStatus'] as String? ?? 'pending',
      isDraft: json['isDraft'] is int
          ? (json['isDraft'] as int) == 1
          : json['isDraft'] as bool? ?? true,
    );
  }

  /// Génère un numéro de projet au format PRJ-YYYY-NNN
  static String _generateProjectNumber() {
    final now = DateTime.now();
    final random = Random().nextInt(1000).toString().padLeft(3, '0');
    return 'PRJ-${now.year}-$random';
  }

  /// Crée un nouveau CRI vide avec valeurs par défaut
  factory CriProjetModel.empty({
    required String id,
    required String technicianName,
  }) {
    final now = DateTime.now();
    return CriProjetModel(
      id: id,
      interventionDate: now,
      startTime: now,
      endTime: now.add(const Duration(hours: 1)),
      clientName: '',
      site: '',
      projectName: '',
      projectNumber: _generateProjectNumber(),
      projectPhase: ProjectPhase.etude,
      interventionType: ProjetInterventionType.installationMateriel,
      workDescription: '',
      projectStatus: ProjectStatus.enCours,
      technicianNames: [technicianName],
      technicianSignatures: [null],
      createdAt: now,
    );
  }



  @override
  String toString() {
    return 'CriProjetModel(id: $id, projectName: $projectName, clientName: $clientName, site: $site)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CriProjetModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
