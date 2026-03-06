import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    // 1. Variable injectée au build (Vercel --dart-define)
    const defineUrl = String.fromEnvironment('API_URL');
    
    if (kReleaseMode) {
      if (defineUrl.isNotEmpty) {
        return defineUrl;
      }
      // En production, si rien n'est injecté, on affiche une erreur console
      debugPrint('WARNING: No API_URL defined in release mode!');
    }

    // 2. Ensuite au fichier .env (Local)
    final envUrl = dotenv.env['API_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // 3. Fallback IP locale pour le développement
    return 'http://192.168.70.114:5200/api';
  }
}
