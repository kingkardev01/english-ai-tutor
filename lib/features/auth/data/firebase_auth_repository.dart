import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(
    (user) => user == null
        ? null
        : AppUser(
            uid: user.uid,
            name: user.displayName,
            email: user.email,
            photoUrl: user.photoURL,
          ),
  );

  /// Uses Firebase's built-in Google provider flow, so no extra
  /// google_sign_in setup is needed on Android and iOS.
  @override
  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    if (kIsWeb) {
      await _auth.signInWithPopup(provider);
    } else {
      await _auth.signInWithProvider(provider);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
