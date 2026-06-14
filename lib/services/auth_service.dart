import 'dart:async';
import '../models/user_model.dart';

class AuthService {
  final _authController = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;

  Stream<UserModel?> get authStateChanges => _authController.stream;
  UserModel? get currentUser => _currentUser;

  // Mock initial state as unauthenticated
  AuthService() {
    _authController.add(null);
  }

  Future<UserModel> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Create a mock user
    _currentUser = UserModel(
      uid: 'user_123',
      email: email,
      name: 'Test User',
    );
    
    _authController.add(_currentUser);
    return _currentUser!;
  }

  Future<UserModel> signup(String name, String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Create a mock user
    _currentUser = UserModel(
      uid: 'user_123',
      email: email,
      name: name,
    );
    
    _authController.add(_currentUser);
    return _currentUser!;
  }

  Future<UserModel> loginWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
    
    _currentUser = UserModel(
      uid: 'user_google_123',
      email: 'google@test.com',
      name: 'Google User',
    );
    
    _authController.add(_currentUser);
    return _currentUser!;
  }

  Future<void> updateName(String newName) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_currentUser == null) return;
    _currentUser = UserModel(uid: _currentUser!.uid, email: _currentUser!.email, name: newName);
    _authController.add(_currentUser);
  }

  Future<void> updatePassword(String oldPassword, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // In production this calls Firebase Auth re-authenticate + updatePassword
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
    _authController.add(null);
  }

  void dispose() {
    _authController.close();
  }
}
