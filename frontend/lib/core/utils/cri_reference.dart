/// Génération d'une référence CRI de secours quand le numéro de commande
/// n'a pas été renseigné manuellement par le technicien.
///
/// Format : `CRI<date>_<acronymeSite><nomClient>`
/// Exemple : `CRI20260720_CCRMonoprix`
class CriReference {
  /// Mots peu significatifs ignorés lors du calcul de l'acronyme du site.
  static const _stopWords = {
    'de', 'du', 'des', 'le', 'la', 'les', 'un', 'une', 'et', 'a', 'au', 'aux',
    'l', 'd', 'en', 'sur', 'sous', 'pour', 'par', 'dans', 'the', 'of',
  };

  /// Dérive un acronyme depuis le nom d'un site.
  /// "Centre Commercial Rivetoile" -> "CCR".
  /// Si aucun mot significatif, prend les 3 premières lettres alphanumériques.
  static String siteAcronym(String? siteName) {
    final name = (siteName ?? '').trim();
    if (name.isEmpty) return '';

    final words = name
        .split(RegExp(r'[\s\-_/]+'))
        .map((w) => w.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ0-9]'), ''))
        .where((w) => w.isNotEmpty)
        .toList();

    final significant = words
        .where((w) => !_stopWords.contains(w.toLowerCase()))
        .toList();

    final source = significant.isNotEmpty ? significant : words;
    final acronym = source.map((w) => w[0].toUpperCase()).join();

    if (acronym.isNotEmpty) return acronym;

    // Fallback : 3 premières lettres alphanumériques du nom.
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ0-9]'), '');
    return cleaned.isEmpty
        ? ''
        : cleaned.substring(0, cleaned.length < 3 ? cleaned.length : 3).toUpperCase();
  }

  /// Nettoie un nom client pour l'inclure dans une référence (sans espaces
  /// ni caractères spéciaux).
  static String _sanitizeClient(String? clientName) {
    final name = (clientName ?? '').trim();
    if (name.isEmpty) return '';
    return name
        .split(RegExp(r'\s+'))
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join()
        .replaceAll(RegExp(r'[^A-Za-zÀ-ÿ0-9]'), '');
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  /// Construit la référence de secours `CRI<date>_<acronymeSite><nomClient>`.
  static String generate({
    required DateTime date,
    String? siteName,
    String? clientName,
  }) {
    final acronym = siteAcronym(siteName);
    final client = _sanitizeClient(clientName);
    return 'CRI${_formatDate(date)}_$acronym$client';
  }
}
