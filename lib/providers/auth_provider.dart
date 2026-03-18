import 'package:flutter/material.dart';
import 'package:elitehire/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  String? _userName;
  String? _userEmail;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userName => _userName;
  String? get userEmail => _userEmail;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithEmail(email, password);
      if (user != null) {
        _isAuthenticated = true;
        _userEmail = user.email;
        final profile = await _authService.getUserProfile(user.uid);
        _userName = profile?['name'] ?? user.displayName ?? email.split('@')[0];
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signUpWithEmail(
        email,
        password,
        displayName: name,
      );
      if (user != null) {
        _isAuthenticated = true;
        _userName = name;
        _userEmail = user.email;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> googleLogin() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        _isAuthenticated = true;
        _userName = user.displayName;
        _userEmail = user.email;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _isAuthenticated = false;
    _userEmail = null;
    _userName = null;
    notifyListeners();
  }
}
