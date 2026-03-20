import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/core/storage/storage_service.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';

/// Provider for theme mode (light/dark/system)
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.read(storageServiceProvider));
});

/// Reactive provider for the current theme animation value (0.0=light, 1.0=dark).
/// Watch this in any widget that uses AppTheme.xxx colors to get automatic rebuilds.
final themeAnimationProvider = StateProvider<double>((ref) => AppTheme.themeT);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storage;

  ThemeModeNotifier(this._storage) : super(ThemeMode.light) {
    _load();
  }

  Future<void> _load() async {
    final saved = await _storage.getThemeMode();
    if (saved != null) {
      final mode = _fromString(saved);
      // Set themeT immediately (no animation) for initial load
      AppTheme.themeT = mode == ThemeMode.dark ? 1.0 : 0.0;
      state = mode;
    }
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    // Animation is handled by NovadisApp's AnimationController
    await _storage.saveThemeMode(next.name);
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _storage.saveThemeMode(mode.name);
  }

  static ThemeMode _fromString(String value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }
}
