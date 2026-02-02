import 'dart:convert';
import 'package:novadis_cri/data/local/tables/cri_service_table.dart';

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
  final String? clientContact;
  final String? phone;

  // Section 3: Demande
  final ServiceRequestType requestType;
  final ServicePriority priority;
  final String requestDescription;

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

  // Section 7: Suivi
  final bool additionalInterventionRequired;
  final DateTime? followUpDate;
  final String? followUpComments;

  // Section 8: Validation
  final List<String> photos;
  final String technicianName;
  final String? technicianSignature;
  final String? clientSignature;
  final ClientSatisfaction? clientSatisfaction;

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
    this.clientContact,
    this.phone,
    required this.requestType,
    required this.priority,
    required this.requestDescription,
    this.diagnosticPerformed,
    this.identifiedCause,
    required this.actionsPerformed,
    this.replacedParts,
    required this.interventionDurationMinutes,
    required this.resolutionStatus,
    this.testsPerformed,
    this.recommendations,
    this.additionalInterventionRequired = false,
    this.followUpDate,
    this.followUpComments,
    this.photos = const [],
    required this.technicianName,
    this.technicianSignature,
    this.clientSignature,
    this.clientSatisfaction,
    required this.createdAt,
    this.updatedAt,
    this.syncStatus = 'pending',
    this.isDraft = true,
  });

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
    String? clientContact,
    String? phone,
    ServiceRequestType? requestType,
    ServicePriority? priority,
    String? requestDescription,
    String? diagnosticPerformed,
    String? identifiedCause,
    String? actionsPerformed,
    String? replacedParts,
    int? interventionDurationMinutes,
    ResolutionStatus? resolutionStatus,
    String? testsPerformed,
    String? recommendations,
    bool? additionalInterventionRequired,
    DateTime? followUpDate,
    String? followUpComments,
    List<String>? photos,
    String? technicianName,
    String? technicianSignature,
    String? clientSignature,
    ClientSatisfaction? clientSatisfaction,
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
      clientContact: clientContact ?? this.clientContact,
      phone: phone ?? this.phone,
      requestType: requestType ?? this.requestType,
      priority: priority ?? this.priority,
      requestDescription: requestDescription ?? this.requestDescription,
      diagnosticPerformed: diagnosticPerformed ?? this.diagnosticPerformed,
      identifiedCause: identifiedCause ?? this.identifiedCause,
      actionsPerformed: actionsPerformed ?? this.actionsPerformed,
      replacedParts: replacedParts ?? this.replacedParts,
      interventionDurationMinutes:
          interventionDurationMinutes ?? this.interventionDurationMinutes,
      resolutionStatus: resolutionStatus ?? this.resolutionStatus,
      testsPerformed: testsPerformed ?? this.testsPerformed,
      recommendations: recommendations ?? this.recommendations,
      additionalInterventionRequired:
          additionalInterventionRequired ?? this.additionalInterventionRequired,
      followUpDate: followUpDate ?? this.followUpDate,
      followUpComments: followUpComments ?? this.followUpComments,
      photos: photos ?? this.photos,
      technicianName: technicianName ?? this.technicianName,
      technicianSignature: technicianSignature ?? this.technicianSignature,
      clientSignature: clientSignature ?? this.clientSignature,
      clientSatisfaction: clientSatisfaction ?? this.clientSatisfaction,
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
      'clientContact': clientContact,
      'phone': phone,
      'requestType': requestType.name,
      'priority': priority.name,
      'requestDescription': requestDescription,
      'diagnosticPerformed': diagnosticPerformed,
      'identifiedCause': identifiedCause,
      'actionsPerformed': actionsPerformed,
      'replacedParts': replacedParts,
      'interventionDurationMinutes': interventionDurationMinutes,
      'resolutionStatus': resolutionStatus.name,
      'testsPerformed': testsPerformed,
      'recommendations': recommendations,
      'additionalInterventionRequired': additionalInterventionRequired,
      'followUpDate': followUpDate?.toIso8601String(),
      'followUpComments': followUpComments,
      'photos': jsonEncode(photos),
      'technicianName': technicianName,
      'technicianSignature': technicianSignature,
      'clientSignature': clientSignature,
      'clientSatisfaction': clientSatisfaction?.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'syncStatus': syncStatus,
      'isDraft': isDraft,
    };
  }

  /// Crée depuis un Map
  factory CriServiceModel.fromJson(Map<String, dynamic> json) {
    return CriServiceModel(
      id: json['id'] as String,
      interventionDate: DateTime.parse(json['interventionDate'] as String),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      ticketNumber: json['ticketNumber'] as String,
      clientName: json['clientName'] as String,
      site: json['site'] as String,
      address: json['address'] as String?,
      clientContact: json['clientContact'] as String?,
      phone: json['phone'] as String?,
      requestType: ServiceRequestType.fromString(json['requestType'] as String),
      priority: ServicePriority.fromString(json['priority'] as String),
      requestDescription: json['requestDescription'] as String,
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
      additionalInterventionRequired:
          json['additionalInterventionRequired'] as bool? ?? false,
      followUpDate: json['followUpDate'] != null
          ? DateTime.parse(json['followUpDate'] as String)
          : null,
      followUpComments: json['followUpComments'] as String?,
      photos: json['photos'] != null
          ? List<String>.from(jsonDecode(json['photos'] as String))
          : [],
      technicianName: json['technicianName'] as String,
      technicianSignature: json['technicianSignature'] as String?,
      clientSignature: json['clientSignature'] as String?,
      clientSatisfaction: json['clientSatisfaction'] != null
          ? ClientSatisfaction.fromString(json['clientSatisfaction'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      syncStatus: json['syncStatus'] as String? ?? 'pending',
      isDraft: json['isDraft'] as bool? ?? true,
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
      ticketNumber: _generateTicketNumber(),
      clientName: '',
      site: '',
      requestType: ServiceRequestType.depannage,
      priority: ServicePriority.normale,
      requestDescription: '',
      actionsPerformed: '',
      interventionDurationMinutes: 60,
      resolutionStatus: ResolutionStatus.nonResolu,
      technicianName: technicianName,
      createdAt: now,
    );
  }

  /// Génère un numéro de ticket automatique
  static String _generateTicketNumber() {
    final now = DateTime.now();
    final random = now.millisecondsSinceEpoch % 100000;
    return 'TICK-${now.year}-${random.toString().padLeft(5, '0')}';
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
