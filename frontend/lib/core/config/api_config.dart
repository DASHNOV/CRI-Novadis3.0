import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    // 1. Priorité absolue à la variable injectée au build (Vercel --dart-define)
    // C'est la SEULE méthode fiable pour Flutter Web en production
    const defineUrl = String.fromEnvironment('API_URL');
    
    if (defineUrl.isNotEmpty) {
      return defineUrl;
    }

    // 2. Si on est en mode Release (Vercel), on ne VEUT PAS du fallback IP locale
    if (kReleaseMode) {
      // Si on arrive ici sur Vercel, c'est que --dart-define a échoué
      return 'https://api.cri-novadis.tech/api';
    }

    // 3. Ensuite au fichier .env (Développement local uniquement)
    final envUrl = dotenv.env['API_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // 4. Fallback IP locale ultime pour le debug local
    return 'http://192.168.70.114:5200/api';
  }
}
