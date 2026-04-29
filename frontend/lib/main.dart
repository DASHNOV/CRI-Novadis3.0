import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:novadis_cri/core/config/app_router.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';

import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔇 En release, neutralise tous les debugPrint (perf + RGPD :
  //    pas de fuite d'infos dans la console navigateur ou logcat).
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  // Chargement des variables d'environnement
  await dotenv.load(fileName: ".env");

  // Préchargement de la police Inter
  GoogleFonts.config.allowRuntimeFetching = true;

  // Détection des frames lentes uniquement en debug
  if (!kReleaseMode) {
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        final duration = timing.totalSpan.inMilliseconds;
        if (duration > 16) {
          debugPrint('Slow frame: ${duration}ms');
        }
      }
    });
  }

  runApp(const ProviderScope(child: NovadisApp()));
}

class NovadisApp extends ConsumerStatefulWidget {
  const NovadisApp({super.key});

  @override
  ConsumerState<NovadisApp> createState() => _NovadisAppState();
}

class _NovadisAppState extends ConsumerState<NovadisApp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: AppTheme.themeT, // Start at current value (set by provider _load)
    )..addListener(() {
        AppTheme.themeT = _themeController.value;
        // Update the reactive provider so all watching widgets rebuild
        ref.read(themeAnimationProvider.notifier).state = _themeController.value;
      });
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    // Animate themeT towards the target
    final target = themeMode == ThemeMode.dark ? 1.0 : 0.0;
    if (_themeController.value != target) {
      if (target == 1.0) {
        _themeController.forward();
      } else {
        _themeController.reverse();
      }
    }

    return MaterialApp.router(
      title: 'Novadis CRI',
      debugShowCheckedModeBanner: false,

      // Light & dark themes
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Smooth animated transition between themes
      themeAnimationDuration: const Duration(milliseconds: 400),
      themeAnimationCurve: Curves.easeInOut,

      // Configuration du routeur
      routerConfig: AppRouter.router,

      // Localisation en français
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR')],
      locale: const Locale('fr', 'FR'),
    );
  }
}
