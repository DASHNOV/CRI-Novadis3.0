import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novadis_cri/core/network/dio_provider.dart';
import 'package:novadis_cri/core/storage/storage_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(dioProvider), ref.read(storageServiceProvider));
});

class AuthService {
  final Dio _dio;
  final StorageService _storage;

  AuthService(this._dio, this._storage);

  /// Demande un code de connexion (Step 1)
  Future<void> login(String email) async {
    try {
      await _dio.post('/auth/login', data: {'email': email});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Vérifie le code et connecte l'utilisateur (Step 2)
  Future<void> verifyCode(String email, String code) async {
    try {
      final response = await _dio.post(
        '/auth/verify',
        data: {
          'email': email,
          'code': code.toUpperCase(),
          'deviceInfo':
              'Mobile App', // You can use device_info_plus package here for real info
        },
      );

      final data = response.data['data']; // Assuming ApiResponse structure
      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];

      if (accessToken != null && refreshToken != null) {
        await _storage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        // Save user role and name for permissions and UI
        final user = data['user'];
        if (user != null) {
          if (user['id'] != null) {
            await _storage.saveUserId(user['id'].toString());
          }
          if (user['role'] != null) {
            await _storage.saveUserRole(user['role']);
          }
          final firstName = (user['firstName'] ?? '') as String;
          final lastName = (user['lastName'] ?? '') as String;
          final fullName = '$firstName $lastName'.trim();
          if (fullName.isNotEmpty) {
            await _storage.saveUserName(fullName);
          }
        }
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    try {
      // Optional: call server logout to revoke refresh token
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        await _dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      }
    } catch (e) {
      // Ignore logout errors
    } finally {
      await _storage.clearTokens();
    }
  }

  String _handleError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      // Try to extract message from API response
      // Assuming structure { "succeeded": false, "message": "Error...", "errors": [...] }
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        return data['message'];
      }
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }
}
