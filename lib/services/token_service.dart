import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  final _storage = const FlutterSecureStorage();
  final String _tokenKey = 'jwt_token';

  // Save token securely
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Get token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Delete token (on logout)
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
