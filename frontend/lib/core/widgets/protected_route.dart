import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/features/auth/presentation/providers/permissions_provider.dart';

class ProtectedRoute extends ConsumerWidget {
  final String requiredPermission;
  final Widget child;
  final Widget? fallback;

  const ProtectedRoute({
    super.key,
    required this.requiredPermission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionsProvider);

    if (permissions.hasPermission(requiredPermission)) {
      return child;
    }

    return fallback ??
        const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Accès refusé',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Vous n\'avez pas les permissions nécessaires.'),
              ],
            ),
          ),
        );
  }
}
