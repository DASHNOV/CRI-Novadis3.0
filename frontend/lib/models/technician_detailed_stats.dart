/// Statistiques détaillées par technicien (depuis l'API backend)
class TechnicianDetailedStats {
  final String id;
  final String prenom;
  final String nom;
  final String nomComplet;
  final int totalInterventions;
  final int sitesDistincts;
  final int clientsDistincts;
  final double? dureeMoyenneMinutes;
  final double totalHeures;
  final int totalServices;
  final int totalProjets;
  final int totalResolu;
  final int totalNonResolu;
  final int totalRecurrenceRequise;
  final DateTime? derniereIntervention;
  final List<String>? topSites;
  final Map<String, int>? repartitionParType;

  const TechnicianDetailedStats({
    required this.id,
    required this.prenom,
    required this.nom,
    required this.nomComplet,
    required this.totalInterventions,
    this.sitesDistincts = 0,
    this.clientsDistincts = 0,
    this.dureeMoyenneMinutes,
    this.totalHeures = 0,
    this.totalServices = 0,
    this.totalProjets = 0,
    this.totalResolu = 0,
    this.totalNonResolu = 0,
    this.totalRecurrenceRequise = 0,
    this.derniereIntervention,
    this.topSites,
    this.repartitionParType,
  });

  factory TechnicianDetailedStats.fromJson(Map<String, dynamic> json) {
    return TechnicianDetailedStats(
      id: json['id'] ?? '',
      prenom: json['prenom'] ?? '',
      nom: json['nom'] ?? '',
      nomComplet: json['nomComplet'] ?? '',
      totalInterventions: json['totalInterventions'] ?? 0,
      sitesDistincts: json['sitesDistincts'] ?? 0,
      clientsDistincts: json['clientsDistincts'] ?? 0,
      dureeMoyenneMinutes: (json['dureeMoyenneMinutes'] as num?)?.toDouble(),
      totalHeures: (json['totalHeures'] as num?)?.toDouble() ?? 0,
      totalServices: json['totalServices'] ?? 0,
      totalProjets: json['totalProjets'] ?? 0,
      totalResolu: json['totalResolu'] ?? 0,
      totalNonResolu: json['totalNonResolu'] ?? 0,
      totalRecurrenceRequise: json['totalRecurrenceRequise'] ?? 0,
      derniereIntervention: json['derniereIntervention'] != null
          ? DateTime.tryParse(json['derniereIntervention'])
          : null,
      topSites: (json['topSites'] as List?)?.cast<String>(),
      repartitionParType: _parseMap(json['repartitionParType']),
    );
  }

  static Map<String, int>? _parseMap(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    }
    return null;
  }

  String get dureeMoyenneFormatee {
    if (dureeMoyenneMinutes == null) return '-';
    final h = dureeMoyenneMinutes! ~/ 60;
    final m = (dureeMoyenneMinutes! % 60).round();
    if (h > 0) return '${h}h ${m}min';
    return '${m}min';
  }
}
