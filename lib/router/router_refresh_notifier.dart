import 'package:flutter/material.dart';
import 'package:memora/providers/user_provider.dart';
import 'package:memora/router/auth_notifier.dart';

/// A [ChangeNotifier] that listens to both [AuthNotifier] and [UserProvider]
/// to trigger a router refresh when either of them changes.
class RouterRefreshNotifier extends ChangeNotifier {
  final AuthNotifier _authNotifier;
  final UserProvider _userProvider;

  RouterRefreshNotifier(this._authNotifier, this._userProvider) {
    _authNotifier.addListener(notifyListeners);
    _userProvider.addListener(notifyListeners);
  }

  @override
  void dispose() {
    _authNotifier.removeListener(notifyListeners);
    _userProvider.removeListener(notifyListeners);
    super.dispose();
  }
}
