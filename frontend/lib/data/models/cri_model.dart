/// Modèle de données pour un Compte Rendu d'Intervention (CRI)
class CriModel {
  final String id;
  final String client;
  final String site;
  final String typeIntervention;
  final String description;
  final DateTime date;
  final DateTime createdAt;

  CriModel({
    required this.id,
    required this.client,
    required this.site,
    required this.typeIntervention,
    required this.description,
    required this.date,
    required this.createdAt,
  });

  /// Crée un CRI à partir d'un Map (pour la désérialisation)
  factory CriModel.fromJson(Map<String, dynamic> json) {
    return CriModel(
      id: json['id'] as String,
      client: json['client'] as String,
      site: json['site'] as String,
      typeIntervention: json['typeIntervention'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }

  /// Convertit le CRI en Map (pour la sérialisation)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client': client,
      'site': site,
      'typeIntervention': typeIntervention,
      'description': description,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Crée une copie du CRI avec des modifications
  CriModel copyWith({
    String? id,
    String? client,
    String? site,
    String? typeIntervention,
    String? description,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return CriModel(
      id: id ?? this.id,
      client: client ?? this.client,
      site: site ?? this.site,
      typeIntervention: typeIntervention ?? this.typeIntervention,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'CriModel(id: $id, client: $client, site: $site, typeIntervention: $typeIntervention, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CriModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
