import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorageService {
  TokenStorageService._();

  static final TokenStorageService instance = TokenStorageService._();

  static const String _key = "auth_token";

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  Future<void> saveToken(String token) async {
    await _storage.write(key: _key, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _key);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _key);
  }
}