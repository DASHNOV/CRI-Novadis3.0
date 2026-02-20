/// Activité d'un technicien (dashboard admin)
class TechnicianActivity {
  final String id;
  final String firstName;
  final String lastName;
  final int nbCriTotal;
  final int nbCri7j;
  final int nbCri30j;

  const TechnicianActivity({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.nbCriTotal,
    required this.nbCri7j,
    required this.nbCri30j,
  });

  String get fullName => '$firstName $lastName';

  factory TechnicianActivity.fromJson(Map<String, dynamic> json) {
    return TechnicianActivity(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      nbCriTotal: json['nbCriTotal'] ?? 0,
      nbCri7j: json['nbCri7j'] ?? 0,
      nbCri30j: json['nbCri30j'] ?? 0,
    );
  }
}
