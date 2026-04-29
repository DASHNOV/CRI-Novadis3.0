/// Activité mensuelle pour sparkline personnel
class MonthlyActivity {
  final int annee;
  final int mois;
  final int nb;

  const MonthlyActivity({
    required this.annee,
    required this.mois,
    required this.nb,
  });

  factory MonthlyActivity.fromJson(Map<String, dynamic> json) {
    return MonthlyActivity(
      annee: json['annee'] ?? 0,
      mois: json['mois'] ?? 0,
      nb: json['nb'] ?? 0,
    );
  }
}
