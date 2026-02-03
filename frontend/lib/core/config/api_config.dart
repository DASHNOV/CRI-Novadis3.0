import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5245/api';
    } else if (Platform.isAndroid) {
      // Use host IP for Genymotion (or specific IP 10.0.3.2 if strictly Genymotion, but real IP is safer)
      return 'http://10.0.0.61:5245/api';
    } else {
      return 'http://localhost:5245/api';
    }
  }
}
