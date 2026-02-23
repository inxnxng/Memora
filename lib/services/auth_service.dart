import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show debugPrint, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:memora/exceptions/auth_exception.dart';
import 'package:memora/firebase_options.dart';
import 'package:memora/repositories/user/user_repository.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  final UserRepository _userRepository;

  AuthService({required UserRepository userRepository})
    : _userRepository = userRepository;

  /// Google Sign-In 7.x: initialize with client ID (iOS/macOS also need GIDClientID in Info.plist).
  static Future<void> _ensureGoogleSignInInitialized() async {
    if (kIsWeb) return;
    final GoogleSignIn signIn = GoogleSignIn.instance;
    if (!signIn.supportsAuthenticate()) return;
    final String? clientId =
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)
        ? DefaultFirebaseOptions.ios.iosClientId
        : DefaultFirebaseOptions.android.androidClientId;
    if (clientId != null && clientId.isNotEmpty) {
      await signIn.initialize(clientId: clientId, serverClientId: null);
    }
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await _userRepository.updateUserLastLogin(userCredential.user!.uid);
      }
      return userCredential;
    } catch (e) {
      debugPrint("Error signing in with email: $e");
      return null;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        await _ensureGoogleSignInInitialized();
        final GoogleSignInAccount googleUser = await _googleSignIn
            .authenticate();
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }

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
      } else {
        final user = userCredential.user;
        if (user != null) {
          await _userRepository.updateUserLastLogin(user.uid);
        }
      }
      return userCredential;
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      debugPrint(e.toString());
      return null;
    }
  }

  Future<UserCredential?> signInWithGitHub() async {
    try {
      final GithubAuthProvider githubProvider = GithubAuthProvider();
      UserCredential userCredential;
      // signInWithPopup is web-only; on macOS/Windows use signInWithProvider (opens browser).
      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(githubProvider);
      } else {
        userCredential = await _auth.signInWithProvider(githubProvider);
      }

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
      } else {
        final user = userCredential.user;
        if (user != null) {
          await _userRepository.updateUserLastLogin(user.uid);
        }
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw AuthServiceException(
          'An account already exists with a different credential.',
        );
      } else {
        debugPrint("Error signing in with GitHub: $e");
        throw AuthServiceException(
          'Failed to sign in with GitHub: ${e.message}',
        );
      }
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
