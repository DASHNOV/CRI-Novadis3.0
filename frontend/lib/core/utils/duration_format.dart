/// Formate une durée exprimée en minutes en "Xh Ymin" (ou "Ymin" si < 1h).
String formatDurationMinutes(num minutes) {
  final hours = minutes ~/ 60;
  final mins = (minutes % 60).round();
  if (hours > 0) {
    return '${hours}h ${mins}min';
  }
  return '${mins}min';
}
