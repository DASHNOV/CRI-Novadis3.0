import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:novadis_cri/core/storage/storage_service.dart';
import 'package:novadis_cri/models/user_role.dart';
import 'package:novadis_cri/screens/technician/technician_main_screen.dart';
import 'package:novadis_cri/screens/admin/admin_main_screen.dart';
import 'package:novadis_cri/core/theme/theme_provider.dart';

/// Écran pivot qui détermine l'interface à afficher selon le rôle utilisateur.
/// Lit le rôle depuis le StorageService et redirige vers l'écran approprié.
class RoleHomeScreen extends ConsumerStatefulWidget {
  const RoleHomeScreen({super.key});

  @override
  ConsumerState<RoleHomeScreen> createState() => _RoleHomeScreenState();
}

class _RoleHomeScreenState extends ConsumerState<RoleHomeScreen> {
  UserRole? _role;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final storage = ref.read(storageServiceProvider);
    final roleStr = await storage.getUserRole();

    if (mounted) {
      setState(() {
        if (roleStr != null && roleStr.isNotEmpty) {
          _role = UserRole.fromString(roleStr);
        } else {
          _role = UserRole.technician;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeAnimationProvider);
    if (_isLoading || _role == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement de votre espace...'),
            ],
          ),
        ),
      );
    }

    return switch (_role!) {
      UserRole.admin => const AdminMainScreen(),
      UserRole.technician => const TechnicianMainScreen(),
    };
  }
}
