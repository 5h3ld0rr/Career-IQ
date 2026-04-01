import 'package:flutter/material.dart';
import 'package:careeriq/features/auth/data/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:careeriq/core/widgets/app_snackbar.dart';
import 'dart:math';
import 'package:careeriq/core/services/twilio_service.dart';

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
  String _userRole = 'Job Seeker'; // Default role
  String? _companyName;
  String? _companyWebsite;
  String? _companyIndustry;
  String? _companyDescription;

  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;
  String? _phoneNumber;
  String? _currentOtp;
  String? _pendingPhone;

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
  String get userRole => _userRole;
  bool get isRecruiter => _userRole == 'Recruiter';
  bool get isExternalProvider => _authService.isExternalProvider;

  bool get isEmailVerified => _isEmailVerified;
  bool get isPhoneVerified => _isPhoneVerified;
  String? get phoneNumber => _phoneNumber;
  String? get companyName => _companyName;
  String? get companyWebsite => _companyWebsite;
  String? get companyIndustry => _companyIndustry;
  String? get companyDescription => _companyDescription;

  void showNotification(String message, {bool isError = false}) {
    AppSnackBar.show(message, isError: isError);
  }

  Future<void> _populateUserData(dynamic user) async {
    if (user == null) return;

    _isAuthenticated = true;
    _userEmail = user.email;
    _profilePictureUrl = user.photoURL;

    final profile = await _authService.getUserProfile(user.uid);
    _userName =
        profile?['name'] ?? user.displayName ?? _userEmail?.split('@')[0];

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
    _userRole = profile?['role'] ?? 'Job Seeker';
    _isEmailVerified = user.emailVerified;
    _isPhoneVerified = profile?['isPhoneVerified'] ?? false;
    _phoneNumber = profile?['phoneNumber'];
    _companyName = profile?['companyName'];
    _companyWebsite = profile?['companyWebsite'];
    _companyIndustry = profile?['companyIndustry'];
    _companyDescription = profile?['companyDescription'];
  }

  Future<void> checkAuthStatus() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        await user.reload();
        await _populateUserData(_authService.currentUser);
      } catch (e) {
        debugPrint('Error checking auth status: $e');
      }
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      showNotification("Email and password are required.", isError: true);
      return;
    }

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
      showNotification(_error!, isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp(
    String name,
    String email,
    String password, {
    String? role,
    String? companyName,
  }) async {
    if (name.trim().isEmpty ||
        email.trim().isEmpty ||
        password.trim().isEmpty) {
      showNotification("Please fill all required fields.", isError: true);
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signUpWithEmail(
        email,
        password,
        displayName: name,
        role: role,
        companyName: companyName,
      );
      if (user != null) {
        await _authService.sendEmailVerification();
        await logout();
        showNotification("Account created! Please check your email to verify.");
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      showNotification(_error!, isError: true);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      showNotification("Password reset link sent to $email");
    } catch (e) {
      _error = e.toString();
      showNotification(_error!, isError: true);
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
      showNotification(_error!, isError: true);
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
      showNotification("Profile name updated!");
    } catch (e) {
      _error = e.toString();
      showNotification(_error!, isError: true);
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
        final url = await _authService.uploadProfilePicture(
          uid,
          fileBytes,
          fileName,
        );
        if (url != null) {
          await _authService.updateProfile(photoUrl: url);
          _profilePictureUrl = url;
          showNotification("Profile picture updated!");
        }
      }
    } catch (e) {
      _error = e.toString();
      showNotification(_error!, isError: true);
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
          await _authService.updateResumeInfo(
            uid,
            fileName: fileName,
            url: url,
          );
          _resumeFileName = fileName;
          _resumeUrl = url;
          _resumeUploadedAt = DateTime.now();
          showNotification("Resume uploaded successfully!");
        } else {
          showNotification(
            "Upload failed. Please check your connection.",
            isError: true,
          );
        }
      }
    } catch (e) {
      _error = e.toString();
      showNotification(_error!, isError: true);
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

  Future<void> updateUserDetails({
    String? name,
    String? email,
    String? bio,
    String? experience,
    String? location,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uid = _authService.currentUser?.uid;
      if (uid == null) {
        showNotification(
          'Not logged in. Please re-login and try again.',
          isError: true,
        );
        return;
      }

      final isExternal = _authService.isExternalProvider;
      final data = <String, dynamic>{
        'name': ?name,
        if (email != null && !isExternal) 'email': email,
        'bio': ?bio,
        'experience': ?experience,
        'location': ?location,
      };

      debugPrint('[updateUserDetails] Writing to Firestore: $data');
      await _authService.updateUserProfile(uid, data);

      if (name != null) _userName = name;
      if (email != null && !isExternal) _userEmail = email;
      if (bio != null) _bio = bio;
      if (experience != null) _experience = experience;
      if (location != null) _location = location;

      if (name != null) {
        await _authService.updateProfile(name: name);
      }

      showNotification('Profile updated successfully!');
    } catch (e) {
      debugPrint('[updateUserDetails] ERROR: $e');
      _error = e.toString();
      showNotification(
        'Failed to save profile. Please try again.',
        isError: true,
      );
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
      showNotification("Skills updated successfully!");
    } catch (e) {
      _error = e.toString();
      showNotification(_error!, isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleUserRole() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final newRole = _userRole == 'Job Seeker' ? 'Recruiter' : 'Job Seeker';
      await _authService.updateUserProfile(uid, {'role': newRole});
      _userRole = newRole;
      showNotification("Switched to $newRole mode!");
    } catch (e) {
      _error = e.toString();
      showNotification("Failed to switch role.", isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        await user.reload();
        await _populateUserData(_authService.currentUser);
        notifyListeners();
      } catch (e) {
        debugPrint('Error reloading: $e');
      }
    }
  }

  Future<void> sendEmailVerification({String? newEmail}) async {
    _isLoading = true;
    notifyListeners();
    final trimmedNewEmail = newEmail?.trim() ?? '';
    try {
      if (trimmedNewEmail.isNotEmpty && trimmedNewEmail != _userEmail) {
        await _authService.updateEmail(trimmedNewEmail);
        showNotification("Verification email sent to $trimmedNewEmail.");
      } else {
        await _authService.sendEmailVerification();
        showNotification("Verification email sent to $_userEmail.");
      }
    } catch (e) {
      showNotification(e.toString(), isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendPhoneOtp(String phone) async {
    final trimmedPhone = phone.trim();
    if (trimmedPhone.isEmpty) {
      showNotification("Phone number is required.", isError: true);
      return false;
    }

    if (!trimmedPhone.startsWith('+')) {
      showNotification(
        "Phone number must include country code (e.g., +94).",
        isError: true,
      );
      return false;
    }

    _isLoading = true;
    notifyListeners();
    try {
      final otp = (100000 + Random().nextInt(900000)).toString();
      _currentOtp = otp;
      _pendingPhone = trimmedPhone;
      final success = await TwilioService().sendOtp(trimmedPhone, otp);
      if (success) {
        showNotification("OTP sent via SMS!");
        return true;
      } else {
        showNotification(
          "Twilio service error. Check .env configuration and balance.",
          isError: true,
        );
        return false;
      }
    } catch (e) {
      showNotification("Failed to connect to OTP service: $e", isError: true);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyPhoneOtp(String otp) async {
    _isLoading = true;
    notifyListeners();
    try {
      if (otp == _currentOtp && _pendingPhone != null) {
        final uid = _authService.currentUser?.uid;
        if (uid != null) {
          await _authService.updateUserProfile(uid, {
            'isPhoneVerified': true,
            'phoneNumber': _pendingPhone,
          });
          _isPhoneVerified = true;
          _phoneNumber = _pendingPhone;
          showNotification("Phone Number Verified Successfully!");
          return true;
        }
      }
      showNotification("Invalid Verification Code.", isError: true);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOrganizationConfigs({
    String? companyName,
    String? companyWebsite,
    String? companyIndustry,
    String? companyDescription,
  }) async {
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> data = {};
      if (companyName != null) {
        data['companyName'] = companyName;
      }
      if (companyWebsite != null) {
        data['companyWebsite'] = companyWebsite;
      }
      if (companyIndustry != null) {
        data['companyIndustry'] = companyIndustry;
      }
      if (companyDescription != null) {
        data['companyDescription'] = companyDescription;
      }

      await _authService.updateOrganizationConfigs(userId!, data);

      if (companyName != null) {
        _companyName = companyName;
      }
      if (companyWebsite != null) {
        _companyWebsite = companyWebsite;
      }
      if (companyIndustry != null) {
        _companyIndustry = companyIndustry;
      }
      if (companyDescription != null) {
        _companyDescription = companyDescription;
      }

      showNotification("Organization updated successfully!");
    } catch (e) {
      showNotification("Update failed: $e", isError: true);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
