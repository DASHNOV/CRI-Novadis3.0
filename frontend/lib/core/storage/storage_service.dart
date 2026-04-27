import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);

class StorageService {
  final _storage = const FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userRoleKey = 'user_role';
  static const _userNameKey = 'user_name';
  static const _themeModeKey = 'theme_mode';
  static const _trustedDeviceTokenKey = 'trusted_device_token';
  static const _trustedDeviceEmailKey = 'trusted_device_email';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveUserId(String id) async {
    await _storage.write(key: _userIdKey, value: id);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<void> saveUserRole(String role) async {
    await _storage.write(key: _userRoleKey, value: role);
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: _userRoleKey);
  }

  Future<void> saveUserName(String name) async {
    await _storage.write(key: _userNameKey, value: name);
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: _userNameKey);
  }

  Future<void> saveThemeMode(String mode) async {
    await _storage.write(key: _themeModeKey, value: mode);
  }

  Future<String?> getThemeMode() async {
    return await _storage.read(key: _themeModeKey);
  }

  Future<void> saveTrustedDevice({
    required String token,
    required String email,
  }) async {
    await _storage.write(key: _trustedDeviceTokenKey, value: token);
    await _storage.write(key: _trustedDeviceEmailKey, value: email);
  }

  Future<String?> getTrustedDeviceToken() async {
    return await _storage.read(key: _trustedDeviceTokenKey);
  }

  Future<String?> getTrustedDeviceEmail() async {
    return await _storage.read(key: _trustedDeviceEmailKey);
  }

  Future<void> clearTrustedDevice() async {
    await _storage.delete(key: _trustedDeviceTokenKey);
    await _storage.delete(key: _trustedDeviceEmailKey);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userRoleKey);
    await _storage.delete(key: _userNameKey);
    // Le trusted device token est volontairement conservé pour permettre
    // une reconnexion sans OTP pendant 7 jours sur le même appareil.
  }
}
