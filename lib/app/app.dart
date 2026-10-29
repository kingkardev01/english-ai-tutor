import 'package:flutter/material.dart';

import '../features/auth/presentation/auth_gate.dart';
import 'theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI English Tutor',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: const AuthGate(),
    );
  }
}

/// Shown instead of [App] until config.json has a Gemini key or Firebase
/// config.
class SetupRequiredApp extends StatelessWidget {
  const SetupRequiredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'No keys found.\n\n'
              'Copy config.example.json to config.json, add your Gemini '
              'API key or Firebase config, then run:\n\n'
              'flutter run --dart-define-from-file=config.json',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
