import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    // Tente de récupérer l'URL depuis les variables d'environnement (.env ou Vercel)
    // Sinon utilise l'IP locale par défaut
    final envUrl = dotenv.env['API_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // Ip du serveur backend sur le réseau local (fallback)
    return 'http://192.168.70.114:5200/api';
  }
}
