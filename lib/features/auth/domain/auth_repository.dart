import 'app_user.dart';

abstract interface class AuthRepository {
  /// Emits the signed-in user, or null when signed out.
  Stream<AppUser?> authStateChanges();

  Future<void> signInWithGoogle();

  Future<void> signOut();
}
