import 'package:flutter/material.dart';
import 'package:careeriq/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;
  String? _userName;
  String? _userEmail;
  String? _profilePictureUrl;
  String? _resumeFileName;
  String? _resumeUrl;
  DateTime? _resumeUploadedAt;
  List<String> _skills = [];
  String? _bio;
  String? _experience;
  String? _location;

  String? get userId => _authService.currentUser?.uid;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get profilePictureUrl => _profilePictureUrl;
  String? get resumeFileName => _resumeFileName;
  String? get resumeUrl => _resumeUrl;
  DateTime? get resumeUploadedAt => _resumeUploadedAt;
  List<String> get skills => _skills;
  String? get bio => _bio;
  String? get experience => _experience;
  String? get location => _location;

  Future<void> _populateUserData(dynamic user) async {
    if (user == null) return;
    
    _isAuthenticated = true;
    _userEmail = user.email;
    _profilePictureUrl = user.photoURL;
    
    final profile = await _authService.getUserProfile(user.uid);
    _userName = profile?['name'] ?? user.displayName ?? _userEmail?.split('@')[0];
    
    if (profile?['photoUrl'] != null) {
      _profilePictureUrl = profile!['photoUrl'];
    }
    
    _resumeFileName = profile?['resumeFileName'];
    _resumeUrl = profile?['resumeUrl'];
    
    if (profile?['resumeUploadedAt'] != null) {
      _resumeUploadedAt = (profile!['resumeUploadedAt'] as Timestamp).toDate();
    }
    
    _skills = List<String>.from(profile?['skills'] ?? []);
    _bio = profile?['bio'];
    _experience = profile?['experience'];
    _location = profile?['location'];
  }

  Future<void> checkAuthStatus() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        await _populateUserData(user);
      } catch (e) {
        debugPrint('Error checking auth status: $e');
      }
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signInWithEmail(email, password);
      if (user != null) {
        await _populateUserData(user);
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
        await _populateUserData(user);
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
        await _populateUserData(user);
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

  Future<void> uploadResume(dynamic fileBytes, String fileName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final uid = _authService.currentUser?.uid;
      if (uid != null) {
        final url = await _authService.uploadResume(uid, fileBytes, fileName);
        if (url != null) {
          await _authService.updateResumeInfo(uid, fileName: fileName, url: url);
          _resumeFileName = fileName;
          _resumeUrl = url;
          _resumeUploadedAt = DateTime.now();
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
    _resumeFileName = null;
    _resumeUrl = null;
    _resumeUploadedAt = null;
    _skills = [];
    _bio = null;
    _experience = null;
    _location = null;
    notifyListeners();
  }

  Future<void> updateUserDetails({String? bio, String? experience, String? location}) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final data = <String, dynamic>{};
      if (bio != null) data['bio'] = bio;
      if (experience != null) data['experience'] = experience;
      if (location != null) data['location'] = location;

      await _authService.updateUserProfile(uid, data);
      if (bio != null) _bio = bio;
      if (experience != null) _experience = experience;
      if (location != null) _location = location;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSkills(List<String> newSkills) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await _authService.updateSkills(uid, newSkills);
      _skills = newSkills;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
