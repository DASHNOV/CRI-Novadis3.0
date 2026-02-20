import 'package:novadis_cri/models/user_role.dart';

/// Classe utilitaire de permissions selon le rôle utilisateur
class Permissions {
  /// Peut accéder au dashboard global (stats de tous les CRI)
  static bool canAccessGlobalDashboard(UserRole role) => role == UserRole.admin;

  /// Peut voir tous les CRI de tous les techniciens
  static bool canAccessAllCRIs(UserRole role) => role == UserRole.admin;

  /// Peut accéder à la page Administration
  static bool canAccessAdmin(UserRole role) => role == UserRole.admin;

  /// Peut créer un CRI (tout le monde)
  static bool canCreateCRI(UserRole role) => true;

  /// Peut modifier ses propres CRI (tout le monde)
  static bool canEditOwnCRI(UserRole role) => true;

  /// Peut modifier les CRI des autres (admin uniquement)
  static bool canEditAnyCRI(UserRole role) => role == UserRole.admin;

  /// Peut supprimer un CRI (admin uniquement)
  static bool canDeleteCRI(UserRole role) => role == UserRole.admin;

  /// Peut gérer les utilisateurs
  static bool canManageUsers(UserRole role) => role == UserRole.admin;

  /// Peut exporter les données
  static bool canExportData(UserRole role) => role == UserRole.admin;
}
