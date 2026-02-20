/// Activité journalière pour graphique (admin)
class DailyActivity {
  final DateTime jour;
  final int nb;

  const DailyActivity({required this.jour, required this.nb});

  factory DailyActivity.fromJson(Map<String, dynamic> json) {
    return DailyActivity(
      jour: DateTime.parse(json['jour']),
      nb: json['nb'] ?? 0,
    );
  }
}
