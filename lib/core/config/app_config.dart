import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Every key the app needs, read from `config.json` at build time:
///
///     flutter run --dart-define-from-file=config.json
///
/// Copy `config.example.json` to `config.json` and fill in your own values.
/// `config.json` is git-ignored, so keys never reach the repo.
abstract final class AppConfig {
  /// Optional. When set, the tutor calls the Gemini API directly with this
  /// key; otherwise it goes through Firebase AI Logic.
  static const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _senderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const _androidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
  );
  static const _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );
  static const _iosApiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const _iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

  static bool get hasGeminiKey => geminiApiKey.isNotEmpty;

  /// Firebase options for the current platform, or null when the config
  /// for this platform is missing.
  static FirebaseOptions? get firebaseOptions {
    if (kIsWeb || _projectId.isEmpty) return null;
    final (apiKey, appId) = switch (defaultTargetPlatform) {
      TargetPlatform.android => (_androidApiKey, _androidAppId),
      TargetPlatform.iOS => (_iosApiKey, _iosAppId),
      _ => ('', ''),
    };
    if (apiKey.isEmpty || appId.isEmpty) return null;
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: _senderId,
      projectId: _projectId,
      storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
      iosBundleId: _iosBundleId.isEmpty ? null : _iosBundleId,
    );
  }
}
