import 'package:flutter/material.dart';
import 'package:novadis_cri/models/user_role.dart';
import 'package:novadis_cri/screens/technician/technician_main_screen.dart';
import 'package:novadis_cri/screens/admin/admin_main_screen.dart';

/// Navigateur principal basé sur le rôle de l'utilisateur
class AppNavigator {
  /// Retourne l'écran principal en fonction du rôle
  static Widget getMainScreen(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const AdminMainScreen();
      case UserRole.technician:
        return const TechnicianMainScreen();
    }
  }

  /// Retourne le nombre d'onglets selon le rôle
  static int getTabCount(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 6; // Accueil, Nouveau CRI, Vue Globale, Tous les CRI, Documents, Administration
      case UserRole.technician:
        return 5; // Accueil, Nouveau CRI, Mes CRI, Documents, Profil
    }
  }
}
