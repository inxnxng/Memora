import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:memora/repositories/user/user_repository.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  final UserRepository _userRepository;

  AuthService(UserRepository read, {required UserRepository userRepository})
    : _userRepository = userRepository;

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      debugPrint("Error signing in with email: $e");
      return null;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // For web, use signInWithPopup which is handled by firebase_auth_web
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      } else {
        await _googleSignIn.initialize(); // Ensure previous sign-in is cleared
        final GoogleSignInAccount googleUser = await _googleSignIn.authenticate(
          scopeHint: [
            'https://www.googleapis.com/auth/userinfo.email',
            'https://www.googleapis.com/auth/userinfo.profile',
          ],
        );
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );

        if (userCredential.additionalUserInfo?.isNewUser == true) {
          final user = userCredential.user;
          if (user != null) {
            await _userRepository.createUser(
              user.uid,
              user.displayName,
              user.email,
              user.photoURL,
            );
          }
        }
        return userCredential;
      }
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    // It's recommended to sign out from Google on mobile platforms.
    // On the web, firebase_auth handles this implicitly.
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
  }
}
