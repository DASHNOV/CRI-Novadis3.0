/// Énumération des rôles utilisateur
enum UserRole {
  technician,
  admin;

  /// Convertit une string en UserRole
  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (e) => e.name.toLowerCase() == role.toLowerCase(),
      orElse: () => UserRole.technician,
    );
  }

  /// Retourne le nom du rôle pour l'API
  String toApiString() {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.technician:
        return 'Technician';
    }
  }
}
