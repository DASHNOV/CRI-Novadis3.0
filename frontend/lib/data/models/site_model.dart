/// Modèle pour un site NovaDIS importé depuis la base de données
class SiteModel {
  final int numero;
  final String nomDuSite;
  final String? adresse;
  final String? ville;
  final String? codePostal;
  final String? pays;

  const SiteModel({
    required this.numero,
    required this.nomDuSite,
    this.adresse,
    this.ville,
    this.codePostal,
    this.pays,
  });

  /// Label affiché dans le dropdown : "Nom du site — Ville"
  String get displayLabel {
    if (ville != null && ville!.isNotEmpty) {
      return '$nomDuSite \u2014 $ville';
    }
    return nomDuSite;
  }

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      numero: json['numero'] as int,
      nomDuSite: json['nomDuSite'] as String,
      adresse: json['adresse'] as String?,
      ville: json['ville'] as String?,
      codePostal: json['codePostal'] as String?,
      pays: json['pays'] as String?,
    );
  }

  @override
  String toString() => displayLabel;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SiteModel && other.numero == numero;
  }

  @override
  int get hashCode => numero.hashCode;
}
