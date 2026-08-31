import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  final _storage = const FlutterSecureStorage();
  final String _tokenKey = 'jwt_token';
  final String _emailKey = 'user_email';
  final String _nameKey = 'user_name';

  // Save token securely
  Future<void> saveToken(String token, {String? email, String? name}) async {
    await _storage.write(key: _tokenKey, value: token);
    if (email != null) await _storage.write(key: _emailKey, value: email);
    if (name != null) await _storage.write(key: _nameKey, value: name);
  }

  // Get token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Get user details
  Future<Map<String, String?>> getUserDetails() async {
    final email = await _storage.read(key: _emailKey);
    final name = await _storage.read(key: _nameKey);
    return {'email': email, 'name': name};
  }

  // Delete token (on logout)
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _nameKey);
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
