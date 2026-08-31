import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'token_service.dart';

class AuthService {
  // Use your computer's local Wi-Fi IP Address
  static final String baseUrl = 'https://scanspend-backend.onrender.com/api/auth';

  final TokenService _tokenService = TokenService();
  final _authController = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;

  Stream<UserModel?> get authStateChanges => _authController.stream;
  UserModel? get currentUser => _currentUser;

  AuthService() {
    // Check if already logged in on startup
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final hasToken = await _tokenService.isLoggedIn();
    if (hasToken) {
      final details = await _tokenService.getUserDetails();
      final email = details['email'] ?? 'user@scanspend.com';
      final name = details['name'] ?? 'User';
      _currentUser = UserModel(uid: '1', email: email, name: name);
    } else {
      _currentUser = null;
    }
    _authController.add(_currentUser);
  }

  Future<UserModel> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['token'];
      
      String extractedName = 'User';
      String extractedEmail = email;

      // Try to decode JWT to extract real name
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = json.decode(
            utf8.decode(base64Url.decode(base64.normalize(parts[1])))
          );
          
          extractedEmail = payload['email'] ?? 
                           payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'] ?? 
                           email;
                           
          extractedName = payload['name'] ?? 
                          payload['unique_name'] ?? 
                          payload['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'] ?? 
                          extractedEmail.split('@')[0];
        }
      } catch (e) {
        print('Error decoding JWT: $e');
      }
      
      // Save JWT token
      await _tokenService.saveToken(token, email: extractedEmail, name: extractedName);
      
      _currentUser = UserModel(uid: '1', email: extractedEmail, name: extractedName);
      _authController.add(_currentUser);
      return _currentUser!;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<UserModel> signup(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      // Automatically login after successful registration
      final user = await login(email, password);
      // Ensure the entered name is updated
      await updateName(name);
      return _currentUser!;
    } else {
      throw Exception('Signup failed: ${response.body}');
    }
  }

  // The Web Client ID is needed to get an ID Token from Google
  // This is the "Web" client type (client_type: 3) from google-services.json
  static const _webClientId =
      '331115187512-2vou085fqmv3f2df0q6rsiknsbeq5j62.apps.googleusercontent.com';

  static bool _isGoogleInitialized = false;

  Future<UserModel> loginWithGoogle() async {
    // Initialize GoogleSignIn once before the first use
    if (!_isGoogleInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId: _webClientId,
      );
      _isGoogleInitialized = true;
    }

    // Step 1: Open the Google account picker on the phone
    // Throws an exception if the user cancels the flow.
    final googleUser = await GoogleSignIn.instance.authenticate();

    // Step 2: Get the authentication tokens from Google
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('Failed to get ID Token from Google.');
    }

    // Step 3: Send the ID Token to our .NET backend for verification
    final response = await http.post(
      Uri.parse('$baseUrl/google'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'idToken': idToken}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['token'] ?? data['Token'];
      final email = data['email'] ?? data['Email'] ?? googleUser.email;
      final name = data['name'] ?? data['Name'] ?? googleUser.displayName ?? 'User';

      // Step 4: Save our custom JWT token securely
      await _tokenService.saveToken(token, email: email, name: name);

      _currentUser = UserModel(uid: '1', email: email, name: name);
      _authController.add(_currentUser);
      return _currentUser!;
    } else {
      throw Exception('Google login failed: ${response.body}');
    }
  }

  Future<void> updateName(String newName) async {
    // Placeholder - would need a PUT /api/auth/profile endpoint
    if (_currentUser != null) {
      _currentUser = UserModel(
        uid: _currentUser!.uid,
        email: _currentUser!.email,
        name: newName,
      );
      // Persist the new name locally
      final token = await _tokenService.getToken();
      if (token != null) {
        await _tokenService.saveToken(token, email: _currentUser!.email, name: newName);
      }
      _authController.add(_currentUser);
    }
  }

  Future<void> updatePassword(String oldPassword, String newPassword) async {
    // Placeholder - would need a PUT /api/auth/password endpoint
    throw UnimplementedError('Password update is not implemented yet.');
  }

  Future<void> logout() async {
    await _tokenService.deleteToken();
    _currentUser = null;
    _authController.add(null);
  }

  void dispose() {
    _authController.close();
  }
}
