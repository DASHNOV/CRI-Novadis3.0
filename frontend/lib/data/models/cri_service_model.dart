import 'dart:convert';
import 'package:novadis_cri/data/local/tables/cri_service_table.dart';
import 'package:novadis_cri/data/local/app_database.dart';
import 'package:drift/drift.dart';

/// Modèle de données pour un CRI Service
class CriServiceModel {
  final String id;

  // Section 1: Général
  final DateTime interventionDate;
  final DateTime startTime;
  final DateTime endTime;
  final String ticketNumber;

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

  // Section 3: Demande
  final ServiceRequestType requestType;
  final ServicePriority priority;
  final String requestDescription;

  /// Statut du contrat (facultatif)
  final ServiceContratType? contratType;

  /// Types de système concernés (au moins 1 requis à la soumission)
  final List<ServiceSystemType> systemTypes;

  // Section 4: Diagnostic
  final String? diagnosticPerformed;
  final String? identifiedCause;

  // Section 5: Intervention
  final String actionsPerformed;
  final String? replacedParts;
  final int interventionDurationMinutes;

  // Section 6: Résultat
  final ResolutionStatus resolutionStatus;
  final String? testsPerformed;
  final String? recommendations;
  final String? cybersecurityRecommendations;

  // Section 7: Suivi
  final bool additionalInterventionRequired;
  final DateTime? followUpDate;
  final String? followUpComments;
  final bool devisARealiser;
  final bool facturable;

  // Section 8: Validation
  final List<String> photos;
  final String technicianName;
  final String? technicianSignature;
  final String? clientSignature;

  // Métadonnées
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String syncStatus;
  final bool isDraft;

  CriServiceModel({
    required this.id,
    required this.interventionDate,
    required this.startTime,
    required this.endTime,
    required this.ticketNumber,
    required this.clientName,
    required this.site,
    this.address,
    this.ville,
    this.codePostal,
    this.pays,
    this.clientContact,
    this.phone,
    this.email,
    required this.requestType,
    required this.priority,
    required this.requestDescription,
    this.contratType,
    this.systemTypes = const [],
    this.diagnosticPerformed,
    this.identifiedCause,
    required this.actionsPerformed,
    this.replacedParts,
    required this.interventionDurationMinutes,
    required this.resolutionStatus,
    this.testsPerformed,
    this.recommendations,
    this.cybersecurityRecommendations,
    this.additionalInterventionRequired = false,
    this.followUpDate,
    this.followUpComments,
    this.devisARealiser = false,
    this.facturable = false,
    this.photos = const [],
    required this.technicianName,
    this.technicianSignature,
    this.clientSignature,
    required this.createdAt,
    this.updatedAt,
    this.syncStatus = 'pending',
    this.isDraft = true,
  });

  /// Dérivé des 2 premiers chiffres du code postal
  String get departement {
    final cp = codePostal?.trim() ?? '';
    if (cp.length >= 2) return cp.substring(0, 2);
    return '';
  }

  /// Champ obsolète - retourne une liste vide
  List<String> get fraisSupplementaires => [];

  /// Champ utilisé dans le PDF - par défaut 'Terminée'
  String get interventionStatus => 'Terminée';

  /// Champ utilisé dans le PDF - par défaut liste vide
  List<dynamic> get piecesDetachees => [];

  /// Calcule la durée à partir des heures de début et fin
  static int calculateDuration(DateTime startTime, DateTime endTime) {
    return endTime.difference(startTime).inMinutes;
  }

  /// Formate la durée en heures et minutes
  String get formattedDuration {
    final hours = interventionDurationMinutes ~/ 60;
    final minutes = interventionDurationMinutes % 60;
    if (hours > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    }
    return '${minutes}min';
  }

  /// Crée une copie avec des modifications
  CriServiceModel copyWith({
    String? id,
    DateTime? interventionDate,
    DateTime? startTime,
    DateTime? endTime,
    String? ticketNumber,
    String? clientName,
    String? site,
    String? address,
    String? ville,
    String? codePostal,
    String? pays,
    String? clientContact,
    String? phone,
    String? email,
    ServiceRequestType? requestType,
    ServicePriority? priority,
    String? requestDescription,
    ServiceContratType? contratType,
    bool clearContratType = false,
    List<ServiceSystemType>? systemTypes,
    String? diagnosticPerformed,
    String? identifiedCause,
    String? actionsPerformed,
    String? replacedParts,
    int? interventionDurationMinutes,
    ResolutionStatus? resolutionStatus,
    String? testsPerformed,
    String? recommendations,
    String? cybersecurityRecommendations,
    bool? additionalInterventionRequired,
    DateTime? followUpDate,
    String? followUpComments,
    bool? devisARealiser,
    bool? facturable,
    List<String>? photos,
    String? technicianName,
    String? technicianSignature,
    String? clientSignature,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    bool? isDraft,
  }) {
    return CriServiceModel(
      id: id ?? this.id,
      interventionDate: interventionDate ?? this.interventionDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      clientName: clientName ?? this.clientName,
      site: site ?? this.site,
      address: address ?? this.address,
      ville: ville ?? this.ville,
      codePostal: codePostal ?? this.codePostal,
      pays: pays ?? this.pays,
      clientContact: clientContact ?? this.clientContact,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      requestType: requestType ?? this.requestType,
      priority: priority ?? this.priority,
      requestDescription: requestDescription ?? this.requestDescription,
      contratType: clearContratType ? null : (contratType ?? this.contratType),
      systemTypes: systemTypes ?? this.systemTypes,
      diagnosticPerformed: diagnosticPerformed ?? this.diagnosticPerformed,
      identifiedCause: identifiedCause ?? this.identifiedCause,
      actionsPerformed: actionsPerformed ?? this.actionsPerformed,
      replacedParts: replacedParts ?? this.replacedParts,
      interventionDurationMinutes:
          interventionDurationMinutes ?? this.interventionDurationMinutes,
      resolutionStatus: resolutionStatus ?? this.resolutionStatus,
      testsPerformed: testsPerformed ?? this.testsPerformed,
      recommendations: recommendations ?? this.recommendations,
      cybersecurityRecommendations:
          cybersecurityRecommendations ?? this.cybersecurityRecommendations,
      additionalInterventionRequired:
          additionalInterventionRequired ?? this.additionalInterventionRequired,
      followUpDate: followUpDate ?? this.followUpDate,
      followUpComments: followUpComments ?? this.followUpComments,
      devisARealiser: devisARealiser ?? this.devisARealiser,
      facturable: facturable ?? this.facturable,
      photos: photos ?? this.photos,
      technicianName: technicianName ?? this.technicianName,
      technicianSignature: technicianSignature ?? this.technicianSignature,
      clientSignature: clientSignature ?? this.clientSignature,
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
      'ticketNumber': ticketNumber,
      'clientName': clientName,
      'site': site,
      'address': address,
      'ville': ville,
      'codePostal': codePostal,
      'pays': pays,
      'clientContact': clientContact,
      'phone': phone,
      'email': email,
      'requestType': requestType.name,
      'priority': priority.name,
      'requestDescription': requestDescription,
      'contratType': contratType?.name,
      'systemTypes': systemTypes.map((e) => e.name).toList(),
      'diagnosticPerformed': diagnosticPerformed,
      'identifiedCause': identifiedCause,
      'actionsPerformed': actionsPerformed,
      'replacedParts': replacedParts,
      'interventionDurationMinutes': interventionDurationMinutes,
      'resolutionStatus': resolutionStatus.name,
      'testsPerformed': testsPerformed,
      'recommendations': recommendations,
      'cybersecurityRecommendations': cybersecurityRecommendations,
      'additionalInterventionRequired': additionalInterventionRequired,
      'followUpDate': followUpDate?.toIso8601String(),
      'followUpComments': followUpComments,
      'devisARealiser': devisARealiser,
      'facturable': facturable,
      'photos': jsonEncode(photos),
      'technicianName': technicianName,
      'technicianSignature': technicianSignature,
      'clientSignature': clientSignature,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'syncStatus': syncStatus,
      'isDraft': isDraft,
    };
  }

  /// Convertit pour insertion dans la base Drift
  CriServiceTableCompanion toDb() {
    return CriServiceTableCompanion(
      id: Value(id),
      interventionDate: Value(interventionDate),
      startTime: Value(startTime),
      endTime: Value(endTime),
      ticketNumber: Value(ticketNumber.isEmpty ? null : ticketNumber),
      clientName: Value(clientName),
      site: Value(site),
      address: Value(address),
      ville: Value(ville),
      codePostal: Value(codePostal),
      pays: Value(pays),
      clientContact: Value(clientContact),
      phone: Value(phone),
      email: Value(email),
      requestType: Value(requestType.name),
      priority: Value(priority.name),
      requestDescription: Value(requestDescription),
      contratType: Value(contratType?.name),
      systemTypes: Value(
        systemTypes.isEmpty
            ? null
            : jsonEncode(systemTypes.map((e) => e.name).toList()),
      ),
      diagnosticPerformed: Value(diagnosticPerformed),
      identifiedCause: Value(identifiedCause),
      actionsPerformed: Value(actionsPerformed),
      replacedParts: Value(replacedParts),
      interventionDurationMinutes: Value(interventionDurationMinutes),
      resolutionStatus: Value(resolutionStatus.name),
      testsPerformed: Value(testsPerformed),
      recommendations: Value(recommendations),
      cybersecurityRecommendations: Value(cybersecurityRecommendations),
      additionalInterventionRequired: Value(additionalInterventionRequired),
      followUpDate: Value(followUpDate),
      followUpComments: Value(followUpComments),
      devisARealiser: Value(devisARealiser),
      facturable: Value(facturable),
      photos: Value(jsonEncode(photos)),
      technicianName: Value(technicianName),
      technicianSignature: Value(technicianSignature),
      clientSignature: Value(clientSignature),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      isDraft: Value(isDraft),
    );
  }

  factory CriServiceModel.fromDb(CriService db) {
    return CriServiceModel(
      id: db.id,
      interventionDate: db.interventionDate,
      startTime: db.startTime,
      endTime: db.endTime,
      ticketNumber: db.ticketNumber ?? '',
      clientName: db.clientName,
      site: db.site,
      address: db.address,
      ville: db.ville,
      codePostal: db.codePostal,
      pays: db.pays,
      clientContact: db.clientContact,
      phone: db.phone,
      email: db.email,
      requestType: ServiceRequestType.fromString(db.requestType),
      priority: ServicePriority.fromString(db.priority),
      requestDescription: db.requestDescription,
      contratType: ServiceContratType.fromString(db.contratType),
      systemTypes: db.systemTypes == null || db.systemTypes!.isEmpty
          ? const []
          : (jsonDecode(db.systemTypes!) as List)
              .map((e) => ServiceSystemType.fromString(e as String?))
              .whereType<ServiceSystemType>()
              .toList(),
      diagnosticPerformed: db.diagnosticPerformed,
      identifiedCause: db.identifiedCause,
      actionsPerformed: db.actionsPerformed,
      replacedParts: db.replacedParts,
      interventionDurationMinutes: db.interventionDurationMinutes,
      resolutionStatus: ResolutionStatus.fromString(db.resolutionStatus),
      testsPerformed: db.testsPerformed,
      recommendations: db.recommendations,
      cybersecurityRecommendations: db.cybersecurityRecommendations,
      additionalInterventionRequired: db.additionalInterventionRequired,
      followUpDate: db.followUpDate,
      followUpComments: db.followUpComments,
      devisARealiser: db.devisARealiser,
      facturable: db.facturable,
      photos: db.photos != null
          ? List<String>.from(jsonDecode(db.photos!))
          : [],
      technicianName: db.technicianName,
      technicianSignature: db.technicianSignature,
      clientSignature: db.clientSignature,
      createdAt: db.createdAt,
      updatedAt: db.updatedAt,
      syncStatus: db.syncStatus,
      isDraft: db.isDraft,
    );
  }

  /// Crée depuis un Map
  factory CriServiceModel.fromJson(Map<String, dynamic> json) {
    return CriServiceModel(
      id: json['id'] as String,
      interventionDate: DateTime.parse(json['interventionDate'] as String),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      ticketNumber: (json['ticketNumber'] as String?) ?? '',
      clientName: json['clientName'] as String,
      site: json['site'] as String,
      address: json['address'] as String?,
      ville: json['ville'] as String?,
      codePostal: json['codePostal'] as String?,
      pays: json['pays'] as String?,
      clientContact: json['clientContact'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      requestType: ServiceRequestType.fromString(json['requestType'] as String),
      priority: ServicePriority.fromString(json['priority'] as String),
      requestDescription: json['requestDescription'] as String,
      contratType: ServiceContratType.fromString(json['contratType'] as String?),
      systemTypes: json['systemTypes'] == null
          ? const []
          : (json['systemTypes'] is String
                  ? (jsonDecode(json['systemTypes'] as String) as List)
                  : (json['systemTypes'] as List))
              .map((e) => ServiceSystemType.fromString(e as String?))
              .whereType<ServiceSystemType>()
              .toList(),
      diagnosticPerformed: json['diagnosticPerformed'] as String?,
      identifiedCause: json['identifiedCause'] as String?,
      actionsPerformed: json['actionsPerformed'] as String,
      replacedParts: json['replacedParts'] as String?,
      interventionDurationMinutes: json['interventionDurationMinutes'] as int,
      resolutionStatus: ResolutionStatus.fromString(
        json['resolutionStatus'] as String,
      ),
      testsPerformed: json['testsPerformed'] as String?,
      recommendations: json['recommendations'] as String?,
      cybersecurityRecommendations:
          json['cybersecurityRecommendations'] as String?,
      additionalInterventionRequired:
          json['additionalInterventionRequired'] is int
          ? (json['additionalInterventionRequired'] as int) == 1
          : json['additionalInterventionRequired'] as bool? ?? false,
      followUpDate: json['followUpDate'] != null
          ? DateTime.parse(json['followUpDate'] as String)
          : null,
      followUpComments: json['followUpComments'] as String?,
      devisARealiser: json['devisARealiser'] is int
          ? (json['devisARealiser'] as int) == 1
          : json['devisARealiser'] as bool? ?? false,
      facturable: json['facturable'] is int
          ? (json['facturable'] as int) == 1
          : json['facturable'] as bool? ?? false,
      photos: json['photos'] != null
          ? List<String>.from(jsonDecode(json['photos'] as String))
          : [],
      technicianName: json['technicianName'] as String,
      technicianSignature: json['technicianSignature'] as String?,
      clientSignature: json['clientSignature'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      syncStatus: json['syncStatus'] as String? ?? 'pending',
      isDraft: json['isDraft'] is int
          ? (json['isDraft'] as int) == 1
          : json['isDraft'] as bool? ?? true,
    );
  }

  /// Crée un nouveau CRI vide avec valeurs par défaut
  factory CriServiceModel.empty({
    required String id,
    required String technicianName,
  }) {
    final now = DateTime.now();
    return CriServiceModel(
      id: id,
      interventionDate: now,
      startTime: now,
      endTime: now.add(const Duration(hours: 1)),
      ticketNumber: '',
      clientName: '',
      site: '',
      requestType: ServiceRequestType.depannage,
      priority: ServicePriority.normale,
      requestDescription: '',
      actionsPerformed: '',
      interventionDurationMinutes: 60,
      resolutionStatus: ResolutionStatus.resolu,
      technicianName: technicianName,
      createdAt: now,
    );
  }


  @override
  String toString() {
    return 'CriServiceModel(id: $id, ticketNumber: $ticketNumber, clientName: $clientName, priority: ${priority.label})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CriServiceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
