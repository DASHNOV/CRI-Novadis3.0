/// Statistiques personnelles d'un technicien
class PersonalStats {
  final int criCeMois;
  final int criEnCours;
  final int criEnAttente;

  const PersonalStats({
    required this.criCeMois,
    required this.criEnCours,
    required this.criEnAttente,
  });

  factory PersonalStats.fromJson(Map<String, dynamic> json) {
    return PersonalStats(
      criCeMois: json['criCeMois'] ?? 0,
      criEnCours: json['criEnCours'] ?? 0,
      criEnAttente: json['criEnAttente'] ?? 0,
    );
  }

  factory PersonalStats.empty() {
    return const PersonalStats(criCeMois: 0, criEnCours: 0, criEnAttente: 0);
  }
}
