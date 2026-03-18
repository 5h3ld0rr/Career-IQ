import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Real backend implementation
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
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
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

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }
}
