import 'package:flutter/foundation.dart';

/// Logger applicatif : silencieux en release, actif en debug/profile.
///
/// Remplace les `debugPrint` directs pour garantir qu'aucune trace n'est
/// émise dans les builds de production (perf + RGPD).
class AppLogger {
  const AppLogger._();

  static void d(Object? message, {String? tag}) {
    if (kReleaseMode) return;
    debugPrint(_format('DEBUG', tag, message));
  }

  static void i(Object? message, {String? tag}) {
    if (kReleaseMode) return;
    debugPrint(_format('INFO ', tag, message));
  }

  static void w(Object? message, {String? tag, Object? error}) {
    if (kReleaseMode) return;
    final base = _format('WARN ', tag, message);
    debugPrint(error != null ? '$base | error: $error' : base);
  }

  /// Erreurs : on log même en release (utile pour un crash reporter futur).
  static void e(Object? message, {String? tag, Object? error, StackTrace? stack}) {
    final base = _format('ERROR', tag, message);
    debugPrint(error != null ? '$base | error: $error' : base);
    if (stack != null && !kReleaseMode) debugPrint(stack.toString());
  }

  static String _format(String level, String? tag, Object? message) {
    final t = tag != null ? '[$tag] ' : '';
    return '[$level] $t$message';
  }
}
