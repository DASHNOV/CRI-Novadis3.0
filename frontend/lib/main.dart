import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/core/config/app_router.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';

import 'package:flutter/scheduler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SchedulerBinding.instance.addTimingsCallback((timings) {
    for (final timing in timings) {
      final duration = timing.totalSpan.inMilliseconds;
      if (duration > 16) {
        debugPrint('⚠️ Slow frame: ${duration}ms');
      }
    }
  });

  runApp(const ProviderScope(child: NovadisApp()));
}

class NovadisApp extends StatelessWidget {
  const NovadisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Novadis CRI',
      debugShowCheckedModeBanner: false,

      // Configuration du thème
      theme: AppTheme.lightTheme,

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
