import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/core/constants/permissions.dart';
import 'package:novadis_cri/core/storage/storage_service.dart';

// Provides the current user role
final userRoleProvider = StateNotifierProvider<UserRoleNotifier, String?>((
  ref,
) {
  return UserRoleNotifier(ref.read(storageServiceProvider));
});

class UserRoleNotifier extends StateNotifier<String?> {
  final StorageService _storage;

  UserRoleNotifier(this._storage) : super(null) {
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await _storage.getUserRole();
    state = role;
  }

  Future<void> refresh() async {
    await _loadRole();
  }
}

// Provides helper to check permissions
final permissionsProvider = Provider<PermissionsService>((ref) {
  final role = ref.watch(userRoleProvider);
  return PermissionsService(role);
});

class PermissionsService {
  final String? _role;

  PermissionsService(this._role);

  bool hasPermission(String permission) {
    if (_role == null) return false;
    // Handle case sensitivity if needed, but constants should match
    // Map role from DB (e.g. 'Technicien') to keys in rolePermissions
    final permissions = rolePermissions[_role];
    return permissions != null && permissions.contains(permission);
  }

  String? get role => _role;
}
