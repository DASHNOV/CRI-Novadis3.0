import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/core/network/dio_provider.dart';

final userApiServiceProvider = Provider<UserApiService>((ref) {
  return UserApiService(ref.watch(dioProvider));
});

/// Provider de la signature pré-enregistrée du technicien connecté.
/// Charge depuis l'API au premier accès. Null si aucune signature enregistrée.
final savedSignatureProvider =
    AsyncNotifierProvider<SavedSignatureNotifier, String?>(() {
  return SavedSignatureNotifier();
});

class SavedSignatureNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final service = ref.read(userApiServiceProvider);
    return await service.getSavedSignature();
  }

  Future<void> setSignature(String? base64) async {
    final service = ref.read(userApiServiceProvider);
    await service.saveSignature(base64);
    state = AsyncData(base64);
  }
}

class UserApiService {
  final Dio _dio;

  UserApiService(this._dio);

  Future<String?> getSavedSignature() async {
    try {
      final response = await _dio.get('/users/me');
      return response.data['data']?['savedSignature'] as String?;
    } on DioException {
      return null;
    }
  }

  Future<void> saveSignature(String? base64) async {
    await _dio.put('/users/me/signature', data: {'signatureBase64': base64});
  }
}
