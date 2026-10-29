import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chat/presentation/chat_screen.dart';
import '../data/auth_providers.dart';
import 'sign_in_screen.dart';

/// Shows the chat when signed in (or when sign-in is off because Firebase
/// isn't configured), otherwise the sign-in screen.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(signInEnabledProvider)) return const ChatScreen();
    return switch (ref.watch(authStateProvider)) {
      AsyncData(value: _?) => const ChatScreen(),
      AsyncData() || AsyncError() => const SignInScreen(),
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}
