import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'features/auth/data/auth_providers.dart';
import 'features/history/data/hive_history_repository.dart';
import 'features/history/data/history_providers.dart';
import 'features/progress/data/progress_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseOptions = AppConfig.firebaseOptions;
  if (firebaseOptions == null && !AppConfig.hasGeminiKey) {
    runApp(const SetupRequiredApp());
    return;
  }

  if (firebaseOptions != null) {
    await Firebase.initializeApp(options: firebaseOptions);

    // Debug builds print a debug token to the console; add it under
    // App Check > Apps > Manage debug tokens in the Firebase console.
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  }

  final prefs = await SharedPreferences.getInstance();
  await Hive.initFlutter();
  final historyBox = await Hive.openBox<String>(HiveHistoryRepository.boxName);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        historyBoxProvider.overrideWithValue(historyBox),
        // Sign-in needs Firebase; with only a Gemini key, the app opens
        // straight into the chat.
        signInEnabledProvider.overrideWithValue(firebaseOptions != null),
      ],
      child: const App(),
    ),
  );
}
