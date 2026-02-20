/// Statistiques globales (admin uniquement)
class GlobalStats {
  final int totalCeMois;
  final int totalSignes;
  final int totalEnAttente;
  final int techniciensActifs;

  const GlobalStats({
    required this.totalCeMois,
    required this.totalSignes,
    required this.totalEnAttente,
    required this.techniciensActifs,
  });

  factory GlobalStats.fromJson(Map<String, dynamic> json) {
    return GlobalStats(
      totalCeMois: json['totalCeMois'] ?? 0,
      totalSignes: json['totalSignes'] ?? 0,
      totalEnAttente: json['totalEnAttente'] ?? 0,
      techniciensActifs: json['techniciensActifs'] ?? 0,
    );
  }

  factory GlobalStats.empty() {
    return const GlobalStats(
      totalCeMois: 0,
      totalSignes: 0,
      totalEnAttente: 0,
      techniciensActifs: 0,
    );
  }

  /// Pourcentage de CRI signés
  double get signedPercentage {
    final total = totalSignes + totalEnAttente;
    if (total == 0) return 0;
    return (totalSignes / total) * 100;
  }
}
