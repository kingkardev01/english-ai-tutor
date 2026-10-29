import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/data/auth_providers.dart';
import '../domain/mistake.dart';
import '../domain/progress.dart';
import '../domain/progress_repository.dart';
import 'firestore_progress_repository.dart';
import 'local_progress_repository.dart';

/// Overridden in main() with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPreferencesProvider'),
);

/// Firestore when the learner is signed in, otherwise on-device storage.
/// Override this in tests with a fake.
final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  if (ref.watch(signInEnabledProvider)) {
    final uid = ref.watch(authStateProvider).value?.uid;
    if (uid != null) {
      return FirestoreProgressRepository(FirebaseFirestore.instance, uid);
    }
  }
  final local = LocalProgressRepository(ref.watch(sharedPreferencesProvider));
  ref.onDispose(local.dispose);
  return local;
});

final progressProvider = StreamProvider<Progress>(
  (ref) => ref.watch(progressRepositoryProvider).watchProgress(),
);

final mistakesProvider = StreamProvider<List<Mistake>>(
  (ref) => ref.watch(progressRepositoryProvider).watchMistakes(),
);
