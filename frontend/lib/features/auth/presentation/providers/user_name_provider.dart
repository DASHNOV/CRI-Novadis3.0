import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/core/storage/storage_service.dart';

// Provides the current user name
final userNameProvider = StateNotifierProvider<UserNameNotifier, String?>((
  ref,
) {
  return UserNameNotifier(ref.read(storageServiceProvider));
});

class UserNameNotifier extends StateNotifier<String?> {
  final StorageService _storage;

  UserNameNotifier(this._storage) : super(null) {
    _loadName();
  }

  Future<void> _loadName() async {
    final name = await _storage.getUserName();
    state = name;
  }

  Future<void> refresh() async {
    await _loadName();
  }
}
