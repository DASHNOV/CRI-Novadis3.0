import 'package:drift/drift.dart';

/// Table Drift pour les CRI Projet
/// Contient tous les champs des 6 sections du formulaire
@DataClassName('CriProjet')
class CriProjetTable extends Table {
  // Clé primaire
  TextColumn get id => text()();

  // Section 1: Général
  DateTimeColumn get interventionDate => dateTime()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();

  // Section 2: Client
  TextColumn get clientName => text()();
  TextColumn get site => text()();
  TextColumn get address => text().nullable()();
  TextColumn get ville => text().nullable()();
  TextColumn get codePostal => text().nullable()();
  TextColumn get pays => text().nullable()();
  TextColumn get clientContact => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();

  // Section 3: Projet
  TextColumn get projectName => text()();
  TextColumn get projectNumber =>
      text().withLength(max: 50)(); // PRJ-YYYY-NNN (optional)
  TextColumn get projectPhase => text()(); // Enum value

  // Section 4: Intervention
  TextColumn get interventionType => text()(); // Enum value
  TextColumn get workDescription => text()();
  TextColumn get materialsUsed => text().nullable()();
  TextColumn get problemsEncountered => text().nullable()();
  TextColumn get solutionsProvided => text().nullable()();

  // Logiciels utilisés durant l'intervention (JSON array de SoftwareEntry)
  // Obligatoire à la soumission (au moins 1 logiciel sélectionné)
  TextColumn get softwares => text().nullable()();

  // Section 5: Suivi
  TextColumn get actionsToDo => text().nullable()();
  DateTimeColumn get nextInterventionDate => dateTime().nullable()();
  TextColumn get projectStatus => text()(); // Enum value

  // Section 6: Validation
  TextColumn get photos => text().nullable()(); // JSON array of paths
  TextColumn get technicianName => text()();
  TextColumn get technicianSignature => text().nullable()(); // Base64 or path
  TextColumn get clientSignature => text().nullable()(); // Base64 or path
  TextColumn get clientComments => text().nullable()();

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
  String get tableName => 'cri_projet';
}

/// Phases du projet
enum ProjectPhase {
  etude('Étude'),
  installation('Installation'),
  configuration('Configuration'),
  tests('Tests'),
  miseEnProduction('Mise en production'),
  cloture('Clôture');

  final String label;
  const ProjectPhase(this.label);

  static ProjectPhase fromString(String value) {
    return ProjectPhase.values.firstWhere(
      (e) => e.name == value || e.label == value,
      orElse: () => ProjectPhase.etude,
    );
  }
}

/// Types d'intervention projet
enum ProjetInterventionType {
  installationMateriel('Installation matériel'),
  configuration('Configuration'),
  miseAJour('Mise à jour'),
  formation('Formation'),
  audit('Audit'),
  autre('Autre');

  final String label;
  const ProjetInterventionType(this.label);

  static ProjetInterventionType fromString(String value) {
    return ProjetInterventionType.values.firstWhere(
      (e) => e.name == value || e.label == value,
      orElse: () => ProjetInterventionType.autre,
    );
  }
}

/// Logiciels disponibles pour un CRI Projet (liste fermée).
enum ProjetSoftware {
  amadeus5('Amadeus 5'),
  amadeus8('Amadeus 8'),
  milestone('Milestone'),
  ocularis('Ocularis'),
  qvms('QVMS'),
  galaxy('Galaxy'),
  appvision('AppVision');

  final String label;
  const ProjetSoftware(this.label);

  static ProjetSoftware? fromString(String? value) {
    if (value == null) return null;
    for (final v in ProjetSoftware.values) {
      if (v.name == value || v.label == value) return v;
    }
    return null;
  }
}

/// Logiciel sélectionné + version éventuellement saisie.
class SoftwareEntry {
  final ProjetSoftware software;
  final String? version;

  const SoftwareEntry({required this.software, this.version});

  SoftwareEntry copyWith({ProjetSoftware? software, String? version}) {
    return SoftwareEntry(
      software: software ?? this.software,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toJson() => {
        'software': software.name,
        'version': version,
      };

  factory SoftwareEntry.fromJson(Map<String, dynamic> json) {
    return SoftwareEntry(
      software: ProjetSoftware.fromString(json['software'] as String?) ??
          ProjetSoftware.amadeus5,
      version: json['version'] as String?,
    );
  }
}

/// Statuts du projet
enum ProjectStatus {
  enCours('En cours'),
  enAttenteValidation('En attente validation'),
  termine('Terminé'),
  suspendu('Suspendu');

  final String label;
  const ProjectStatus(this.label);

  static ProjectStatus fromString(String value) {
    return ProjectStatus.values.firstWhere(
      (e) => e.name == value || e.label == value,
      orElse: () => ProjectStatus.enCours,
    );
  }
}
