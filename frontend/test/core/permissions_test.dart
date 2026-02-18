import 'package:flutter_test/flutter_test.dart';
import 'package:novadis_cri/core/constants/permissions.dart';
import 'package:novadis_cri/features/auth/presentation/providers/permissions_provider.dart';

void main() {
  group('Permissions System Tests', () {
    test('Technicien role should have limited permissions', () {
      final service = PermissionsService(UserRole.technicien);

      // Should have
      expect(service.hasPermission(Permission.viewOwnCris), true);
      expect(service.hasPermission(Permission.createCri), true);
      expect(service.hasPermission(Permission.editOwnCri), true);

      // Should NOT have
      expect(service.hasPermission(Permission.manageUsers), false);
      expect(service.hasPermission(Permission.viewGlobalDashboard), false);
      expect(service.hasPermission(Permission.deleteAnyCri), false);
    });

    test('Admin role should have all permissions', () {
      final service = PermissionsService(UserRole.admin);

      // Should have
      expect(service.hasPermission(Permission.viewOwnCris), true);
      expect(service.hasPermission(Permission.manageUsers), true);
      expect(service.hasPermission(Permission.viewGlobalDashboard), true);
      expect(service.hasPermission(Permission.deleteAnyCri), true);
    });

    test('Undefined role should have no permissions', () {
      final service = PermissionsService(null);

      expect(service.hasPermission(Permission.viewOwnCris), false);
      expect(service.hasPermission(Permission.createCri), false);
    });

    test('UserRole constants match requirements', () {
      expect(UserRole.technicien, 'Technicien');
      expect(UserRole.admin, 'Admin');
    });
  });
}
