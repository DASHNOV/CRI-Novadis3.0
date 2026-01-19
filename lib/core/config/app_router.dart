import 'package:go_router/go_router.dart';
import 'package:novadis_cri/features/auth/login_screen.dart';
import 'package:novadis_cri/features/dashboard/dashboard_screen.dart';
import 'package:novadis_cri/features/cri_form/cri_form_screen.dart';
import 'package:novadis_cri/features/cri_form/pages/cri_projet_form_page.dart';
import 'package:novadis_cri/features/cri_form/pages/cri_service_form_page.dart';
import 'package:novadis_cri/features/history/history_screen.dart';
import 'package:novadis_cri/features/admin/admin_screen.dart';

/// Configuration du routeur de l'application
/// Utilise GoRouter pour la navigation
class AppRouter {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String criForm = '/cri-form';
  static const String criNewProjet = '/cri/new/projet';
  static const String criNewService = '/cri/new/service';
  static const String criEdit = '/cri/edit/:id';
  static const String criView = '/cri/view/:id';
  static const String history = '/history';
  static const String admin = '/admin';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    routes: [
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: criForm,
        name: 'cri-form',
        builder: (context, state) => const CriFormScreen(),
      ),
      // Nouveau CRI Projet
      GoRoute(
        path: criNewProjet,
        name: 'cri-new-projet',
        builder: (context, state) => const CriProjetFormPage(),
      ),
      // Nouveau CRI Service
      GoRoute(
        path: criNewService,
        name: 'cri-new-service',
        builder: (context, state) => const CriServiceFormPage(),
      ),
      // Éditer un CRI (détecte le type automatiquement)
      GoRoute(
        path: criEdit,
        name: 'cri-edit',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          final type = state.uri.queryParameters['type'];

          if (type == 'projet') {
            return CriProjetFormPage(criId: id);
          } else {
            return CriServiceFormPage(criId: id);
          }
        },
      ),
      // Visualiser un CRI (lecture seule)
      GoRoute(
        path: criView,
        name: 'cri-view',
        builder: (context, state) {
          final id = state.pathParameters['id'];
          final type = state.uri.queryParameters['type'];

          // TODO: Implémenter une vue lecture seule
          // Pour l'instant, redirige vers l'écran d'édition
          if (type == 'projet') {
            return CriProjetFormPage(criId: id);
          } else {
            return CriServiceFormPage(criId: id);
          }
        },
      ),
      GoRoute(
        path: history,
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: admin,
        name: 'admin',
        builder: (context, state) => const AdminScreen(),
      ),
    ],
  );
}
