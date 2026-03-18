import 'package:flutter/material.dart';
import 'package:careeriq/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  String? _userName;
  String? _userEmail;
  String? _profilePictureUrl;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get profilePictureUrl => _profilePictureUrl;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithEmail(email, password);
      if (user != null) {
        _isAuthenticated = true;
        _userEmail = user.email;
        _profilePictureUrl = user.photoURL;
        final profile = await _authService.getUserProfile(user.uid);
        _userName = profile?['name'] ?? user.displayName ?? email.split('@')[0];
        if (profile?['photoUrl'] != null) {
          _profilePictureUrl = profile!['photoUrl'];
        }
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
        _profilePictureUrl = user.photoURL;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateName(String newName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.updateProfile(name: newName);
      _userName = newName;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfilePicture(dynamic fileBytes, String fileName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final uid = _authService.currentUser?.uid;
      if (uid != null) {
        final url = await _authService.uploadProfilePicture(uid, fileBytes, fileName);
        if (url != null) {
          await _authService.updateProfile(photoUrl: url);
          _profilePictureUrl = url;
        }
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
    _profilePictureUrl = null;
    notifyListeners();
  }
}
