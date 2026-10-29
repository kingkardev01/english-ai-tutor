/// Failures the UI knows how to explain to a learner.
///
/// The data layer maps SDK and network exceptions to one of these, so
/// screens never depend on Firebase exception types.
sealed class TutorFailure implements Exception {
  const TutorFailure();

  /// A short, friendly message shown in the chat.
  String get message;
}

/// The device is offline or the request never reached the server.
class NoConnectionFailure extends TutorFailure {
  const NoConnectionFailure();

  @override
  String get message => 'No internet connection. Check it and tap retry.';
}

/// Quota or rate limit reached.
class TutorBusyFailure extends TutorFailure {
  const TutorBusyFailure();

  @override
  String get message => 'Tutor is busy, try again in a minute.';
}

/// Anything else that went wrong.
class UnknownFailure extends TutorFailure {
  const UnknownFailure([this.cause]);

  final Object? cause;

  @override
  String get message => 'Something went wrong. Please try again.';
}
