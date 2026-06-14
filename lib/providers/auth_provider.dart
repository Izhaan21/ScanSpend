import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  UserModel? _user;
  bool _isLoading = false;

  AuthProvider(this._authService) {
    _init();
  }

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;

  void _init() {
    _authService.authStateChanges.listen((UserModel? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<void> login(String email, String password) async {
    try {
      _setLoading(true);
      await _authService.login(email, password);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signup(String name, String email, String password) async {
    try {
      _setLoading(true);
      await _authService.signup(name, email, password);
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      _setLoading(true);
      await _authService.loginWithGoogle();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      _setLoading(true);
      await _authService.logout();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateName(String newName) async {
    await _authService.updateName(newName);
  }

  Future<void> updatePassword(String old, String newPwd) async {
    await _authService.updatePassword(old, newPwd);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
