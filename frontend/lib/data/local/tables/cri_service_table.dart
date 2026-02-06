import 'dart:ui';

import 'package:drift/drift.dart';

/// Table Drift pour les CRI Service
/// Contient tous les champs des 8 sections du formulaire
@DataClassName('CriService')
class CriServiceTable extends Table {
  // Clé primaire
  TextColumn get id => text()();

  // Section 1: Général
  DateTimeColumn get interventionDate => dateTime()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  TextColumn get ticketNumber =>
      text().withLength(min: 1, max: 50)(); // TICK-YYYY-NNNNN

  // Section 2: Client
  TextColumn get clientName => text().withLength(min: 1, max: 255)();
  TextColumn get site => text().withLength(min: 1, max: 255)();
  TextColumn get address => text().nullable()();
  TextColumn get clientContact => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();

  // Section 3: Demande
  TextColumn get requestType => text()(); // Enum value
  TextColumn get priority => text()(); // Enum value
  TextColumn get requestDescription => text()();

  // Section 4: Diagnostic
  TextColumn get diagnosticPerformed => text().nullable()();
  TextColumn get identifiedCause => text().nullable()();

  // Section 5: Intervention
  TextColumn get actionsPerformed => text()();
  TextColumn get replacedParts => text().nullable()();
  IntColumn get interventionDurationMinutes => integer()(); // Durée en minutes

  // Section 6: Résultat
  TextColumn get resolutionStatus => text()(); // Enum value
  TextColumn get testsPerformed => text().nullable()();
  TextColumn get recommendations => text().nullable()();
  TextColumn get cybersecurityRecommendations => text().nullable()();

  // Section 7: Suivi
  BoolColumn get additionalInterventionRequired =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get followUpDate => dateTime().nullable()();
  TextColumn get followUpComments => text().nullable()();

  // Section 8: Validation
  TextColumn get photos => text().nullable()(); // JSON array of paths
  TextColumn get technicianName => text()();
  TextColumn get technicianSignature => text().nullable()(); // Base64 or path
  TextColumn get clientSignature => text().nullable()(); // Base64 or path

  // Métadonnées
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get syncStatus => text().withDefault(
    const Constant('pending'),
  )(); // pending, synced, failed
  BoolColumn get isDraft => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'cri_service';
}

/// Types de demande service
enum ServiceRequestType {
  maintenancePreventive('Maintenance préventive'),
  maintenanceCorrective('Maintenance corrective'),
  depannage('Dépannage'),
  supportTechnique('Support technique'),
  assistanceUtilisateur('Assistance utilisateur'),
  autre('Autre');

  final String label;
  const ServiceRequestType(this.label);

  static ServiceRequestType fromString(String value) {
    return ServiceRequestType.values.firstWhere(
      (e) => e.name == value || e.label == value,
      orElse: () => ServiceRequestType.autre,
    );
  }
}

/// Niveaux de priorité
enum ServicePriority {
  basse('Basse'),
  normale('Normale'),
  haute('Haute'),
  critique('Critique');

  final String label;
  const ServicePriority(this.label);

  Color get color {
    switch (this) {
      case ServicePriority.basse:
        return const Color(0xFF4CAF50); // Green
      case ServicePriority.normale:
        return const Color(0xFF2196F3); // Blue
      case ServicePriority.haute:
        return const Color(0xFFFF9800); // Orange
      case ServicePriority.critique:
        return const Color(0xFFF44336); // Red
    }
  }

  static ServicePriority fromString(String value) {
    return ServicePriority.values.firstWhere(
      (e) => e.name == value || e.label == value,
      orElse: () => ServicePriority.normale,
    );
  }
}

/// Statuts de résolution
enum ResolutionStatus {
  resolu('Résolu'),
  partiellementResolu('Partiellement résolu'),
  nonResolu('Non résolu'),
  enAttentePieces('En attente pièces'),
  escaladeNiveau2('Escaladé niveau 2');

  final String label;
  const ResolutionStatus(this.label);

  static ResolutionStatus fromString(String value) {
    return ResolutionStatus.values.firstWhere(
      (e) => e.name == value || e.label == value,
      orElse: () => ResolutionStatus.nonResolu,
    );
  }
}
