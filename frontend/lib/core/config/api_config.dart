import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    // 1. Priorité à la variable injectée au build (Vercel --dart-define)
    const defineUrl = String.fromEnvironment('API_URL');
    if (defineUrl.isNotEmpty) {
      return defineUrl;
    }

    // 2. Ensuite au fichier .env (Local)
    final envUrl = dotenv.env['API_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // 3. Fallback IP locale
    return 'http://192.168.70.114:5200/api';
  }
}
