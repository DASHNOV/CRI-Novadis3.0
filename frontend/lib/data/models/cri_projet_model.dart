import 'dart:convert';
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

  // Section 2: Client
  final String clientName;
  final String site;
  final String? address;
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

  // Section 5: Suivi
  final String? actionsToDo;
  final DateTime? nextInterventionDate;
  final ProjectStatus projectStatus;

  // Section 6: Validation
  final List<String> photos;
  final String technicianName;
  final String? technicianSignature;
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
    required this.clientName,
    required this.site,
    this.address,
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
    this.actionsToDo,
    this.nextInterventionDate,
    required this.projectStatus,
    this.photos = const [],
    required this.technicianName,
    this.technicianSignature,
    this.clientSignature,
    this.clientComments,
    required this.createdAt,
    this.updatedAt,
    this.syncStatus = 'pending',
    this.isDraft = true,
  });

  /// Alias pour 'site' (ancien nom: ville)
  String get ville => site;

  /// Champ obsolète - retourne une chaîne vide
  String get departement => '';

  /// Calcule la durée de l'intervention en minutes
  int get durationMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  /// Alias pour durationMinutes
  int get interventionDurationMinutes => durationMinutes;

  /// Formate la durée en heures et minutes
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
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
    String? clientName,
    String? site,
    String? address,
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
    String? actionsToDo,
    DateTime? nextInterventionDate,
    ProjectStatus? projectStatus,
    List<String>? photos,
    String? technicianName,
    String? technicianSignature,
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
      clientName: clientName ?? this.clientName,
      site: site ?? this.site,
      address: address ?? this.address,
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
      actionsToDo: actionsToDo ?? this.actionsToDo,
      nextInterventionDate: nextInterventionDate ?? this.nextInterventionDate,
      projectStatus: projectStatus ?? this.projectStatus,
      photos: photos ?? this.photos,
      technicianName: technicianName ?? this.technicianName,
      technicianSignature: technicianSignature ?? this.technicianSignature,
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
      'clientName': clientName,
      'site': site,
      'address': address,
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
      'actionsToDo': actionsToDo,
      'nextInterventionDate': nextInterventionDate?.toIso8601String(),
      'projectStatus': projectStatus.name,
      'photos': jsonEncode(photos),
      'technicianName': technicianName,
      'technicianSignature': technicianSignature,
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
      clientName: Value(clientName),
      site: Value(site),
      address: Value(address),
      clientContact: Value(clientContact),
      phone: Value(phone),
      email: Value(email),
      projectName: Value(projectName),
      projectNumber: Value(projectNumber),
      projectPhase: Value(projectPhase.name),
      interventionType: Value(interventionType.name),
      workDescription: Value(workDescription),
      materialsUsed: Value(materialsUsed),
      problemsEncountered: Value(problemsEncountered),
      solutionsProvided: Value(solutionsProvided),
      actionsToDo: Value(actionsToDo),
      nextInterventionDate: Value(nextInterventionDate),
      projectStatus: Value(projectStatus.name),
      photos: Value(jsonEncode(photos)),
      technicianName: Value(technicianName),
      technicianSignature: Value(technicianSignature),
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
      clientName: db.clientName,
      site: db.site,
      address: db.address,
      clientContact: db.clientContact,
      phone: db.phone,
      email: db.email,
      projectName: db.projectName,
      projectNumber: db.projectNumber,
      projectPhase: ProjectPhase.fromString(db.projectPhase),
      interventionType: ProjetInterventionType.fromString(db.interventionType),
      workDescription: db.workDescription,
      materialsUsed: db.materialsUsed,
      problemsEncountered: db.problemsEncountered,
      solutionsProvided: db.solutionsProvided,
      actionsToDo: db.actionsToDo,
      nextInterventionDate: db.nextInterventionDate,
      projectStatus: ProjectStatus.fromString(db.projectStatus),
      photos: db.photos != null
          ? List<String>.from(jsonDecode(db.photos!))
          : [],
      technicianName: db.technicianName,
      technicianSignature: db.technicianSignature,
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
      clientName: json['clientName'] as String,
      site: json['site'] as String,
      address: json['address'] as String?,
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
      actionsToDo: json['actionsToDo'] as String?,
      nextInterventionDate: json['nextInterventionDate'] != null
          ? DateTime.parse(json['nextInterventionDate'] as String)
          : null,
      projectStatus: ProjectStatus.fromString(json['projectStatus'] as String),
      photos: json['photos'] != null
          ? List<String>.from(jsonDecode(json['photos'] as String))
          : [],
      technicianName: json['technicianName'] as String,
      technicianSignature: json['technicianSignature'] as String?,
      clientSignature: json['clientSignature'] as String?,
      clientComments: json['clientComments'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      syncStatus: json['syncStatus'] as String? ?? 'pending',
      isDraft: json['isDraft'] as bool? ?? true,
    );
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
      technicianName: technicianName,
      createdAt: now,
    );
  }

  /// Génère un numéro de projet automatique
  static String _generateProjectNumber() {
    final now = DateTime.now();
    final random = now.millisecondsSinceEpoch % 1000;
    return 'PRJ-${now.year}-${random.toString().padLeft(3, '0')}';
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
