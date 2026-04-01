import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:careeriq/core/services/cloudinary_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  bool get isExternalProvider {
    final user = _auth.currentUser;
    if (user == null) return false;
    for (final profile in user.providerData) {
      if (profile.providerId == 'google.com') return true;
    }
    return false;
  }

  Future<User?> signInWithEmail(String email, String password) async {
    UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<User?> signUpWithEmail(
    String email,
    String password, {
    String? displayName,
    String? role,
    String? companyName,
  }) async {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (result.user != null) {
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': displayName ?? email.split('@')[0],
        'email': email,
        'role': role ?? 'Job Seeker',
        'companyName': ?companyName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (displayName != null) {
        await result.user!.updateDisplayName(displayName);
      }
    }
    return result.user;
  }

  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final UserCredential result = await _auth.signInWithCredential(credential);

    if (result.user != null) {
      final userDoc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(result.user!.uid).set({
          'name': result.user!.displayName,
          'email': result.user!.email,
          'photoUrl': result.user!.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    return result.user;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> updateProfile({String? name, String? photoUrl}) async {
    User? user = _auth.currentUser;
    if (user != null) {
      if (name != null) {
        await user.updateDisplayName(name);
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
        }, SetOptions(merge: true));
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
        await _firestore.collection('users').doc(user.uid).set({
          'photoUrl': photoUrl,
        }, SetOptions(merge: true));
      }
    }
  }

  final CloudinaryService _cloudinary = CloudinaryService();

  Future<String?> uploadProfilePicture(
    String uid,
    dynamic file,
    String fileName,
  ) async {
    try {
      return await _cloudinary.uploadFile(
        file: file,
        folder: 'CareerIQ/Profile-Pictures',
        fileName: fileName,
        isImage: true,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> uploadResume(
    String uid,
    dynamic file,
    String fileName,
  ) async {
    try {
      return await _cloudinary.uploadFile(
        file: file,
        folder: 'CareerIQ/CV',
        fileName: fileName,
        isImage: false,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateResumeInfo(
    String uid, {
    required String fileName,
    required String url,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'resumeFileName': fileName,
      'resumeUrl': url,
      'resumeUploadedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  Future<void> updateSkills(String uid, List<String> skills) async {
    await _firestore.collection('users').doc(uid).set({
      'skills': skills,
    }, SetOptions(merge: true));
  }

  Future<void> updateEmail(String newEmail) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await user.verifyBeforeUpdateEmail(newEmail);
      } on FirebaseAuthException catch (e) {
        switch (e.code) {
          case 'requires-recent-login':
            throw 'Security check failed. Please log out and back in, then try again.';
          case 'email-already-in-use':
            throw 'This email is already taken by another account.';
          case 'invalid-email':
            throw 'Please enter a valid email address.';
          default:
            throw 'Email service error: ${e.message} (Code: ${e.code})';
        }
      } catch (e) {
        throw 'An unexpected error occurred: $e';
      }
    }
  }
}
