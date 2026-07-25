import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  final fb.FirebaseAuth _firebaseAuth = fb.FirebaseAuth.instance;
  final _authController = StreamController<UserModel?>.broadcast();
  StreamSubscription<fb.User?>? _userSubscription;
  UserModel? _currentUser;

  Stream<UserModel?> get authStateChanges => _authController.stream;
  UserModel? get currentUser => _currentUser;

  AuthService() {
    _userSubscription = _firebaseAuth.userChanges().listen((fb.User? fbUser) {
      if (fbUser == null) {
        _currentUser = null;
      } else {
        _currentUser = UserModel(
          uid: fbUser.uid,
          email: fbUser.email ?? '',
          name: fbUser.displayName ?? '',
        );
      }
      _authController.add(_currentUser);
    });
  }

  Future<UserModel> login(String email, String password) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final fbUser = credential.user;
    if (fbUser == null) {
      throw Exception('Login failed: user is null');
    }
    _currentUser = UserModel(
      uid: fbUser.uid,
      email: fbUser.email ?? '',
      name: fbUser.displayName ?? '',
    );
    return _currentUser!;
  }

  Future<UserModel> signup(String name, String email, String password) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final fbUser = credential.user;
    if (fbUser == null) {
      throw Exception('Signup failed: user is null');
    }
    await fbUser.updateDisplayName(name);
    await fbUser.reload();

    final updatedUser = _firebaseAuth.currentUser;
    _currentUser = UserModel(
      uid: updatedUser?.uid ?? fbUser.uid,
      email: updatedUser?.email ?? fbUser.email ?? '',
      name: name,
    );
    _authController.add(_currentUser);
    return _currentUser!;
  }

  Future<UserModel> loginWithGoogle() async {
    // google_sign_in v7: use instance singleton + authenticate()
    await GoogleSignIn.instance.initialize();
    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();

    // v7: get id token via authentication property (synchronous in v7)
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final credential = fb.GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await _firebaseAuth.signInWithCredential(credential);
    final fbUser = userCredential.user;
    if (fbUser == null) {
      throw Exception('Google Sign-In failed: user is null');
    }

    _currentUser = UserModel(
      uid: fbUser.uid,
      email: fbUser.email ?? '',
      name: fbUser.displayName ?? '',
    );

    _authController.add(_currentUser);
    return _currentUser!;
  }

  Future<void> updateName(String newName) async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser != null) {
      await fbUser.updateDisplayName(newName);
      await fbUser.reload();
      _currentUser = UserModel(
        uid: fbUser.uid,
        email: fbUser.email ?? '',
        name: newName,
      );
      _authController.add(_currentUser);
    }
  }

  Future<void> updatePassword(String oldPassword, String newPassword) async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser != null && fbUser.email != null) {
      final credential = fb.EmailAuthProvider.credential(
        email: fbUser.email!,
        password: oldPassword,
      );
      await fbUser.reauthenticateWithCredential(credential);
      await fbUser.updatePassword(newPassword);
    }
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Ignore if Google Sign-In is not initialized
    }
    _currentUser = null;
    _authController.add(null);
  }

  void dispose() {
    _userSubscription?.cancel();
    _authController.close();
  }
}
