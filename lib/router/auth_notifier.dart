import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier() {
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((
      user,
    ) {
      _user = user;
      Future.microtask(() => notifyListeners());
    });
  }

  late final StreamSubscription<User?> _authStateSubscription;
  User? _user;

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  User? get user => _user;
}
