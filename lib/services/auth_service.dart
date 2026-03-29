import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? get currentUser => _auth.currentUser;

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
  }) async {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (result.user != null) {
      // Create user profile in Firestore
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': displayName ?? email.split('@')[0],
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (displayName != null) {
        await result.user!.updateDisplayName(displayName);
      }
    }
    return result.user;
  }

  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        googleUser.authentication;
    
    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final UserCredential result = await _auth.signInWithCredential(credential);

    // Sync Google user with Firestore if new
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

  Future<String?> uploadProfilePicture(String uid, dynamic fileBytes, String fileName) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('profiles').child(uid).child(fileName);
      await ref.putData(fileBytes);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadResume(String uid, dynamic fileBytes, String fileName) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('resumes').child(uid).child(fileName);
      await ref.putData(fileBytes);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> updateResumeInfo(String uid, {required String fileName, required String url}) async {
    await _firestore.collection('users').doc(uid).set({
      'resumeFileName': fileName,
      'resumeUrl': url,
      'resumeUploadedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  Future<void> updateSkills(String uid, List<String> skills) async {
    await _firestore.collection('users').doc(uid).set({
      'skills': skills,
    }, SetOptions(merge: true));
  }
}
