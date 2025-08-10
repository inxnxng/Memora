import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:memora/repositories/user/user_repository.dart';
import 'package:memora/screens/login_screen.dart';
import 'package:memora/utils/platform_utils.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  final UserRepository _userRepository;

  AuthService({required UserRepository userRepository})
    : _userRepository = userRepository;

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
      } else {
        final user = userCredential.user;
        if (user != null) {
          await _userRepository.updateUserLastLogin(user.uid);
        }
      }
      return userCredential;
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
      return null;
    }
  }

  Future<UserCredential?> signInWithGitHub() async {
    try {
      final GithubAuthProvider githubProvider = GithubAuthProvider();
      UserCredential userCredential;

      if (PlatformUtils.isDesktop) {
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
