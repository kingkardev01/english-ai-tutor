# AI English Tutor

Practise English by chatting with an AI tutor that corrects your grammar in real time.
Built with Flutter, Riverpod and Gemini (Firebase AI Logic).

Made for Bangla-speaking students and job seekers who want daily speaking and writing practice without a human tutor.

<!-- Add after recording: ![Demo](docs/demo.gif) -->

## Screenshots

<!-- Add 3–4 phone screenshots in a row, for example:
<p>
  <img src="docs/home.png" width="200">
  <img src="docs/chat.png" width="200">
  <img src="docs/progress.png" width="200">
  <img src="docs/history.png" width="200">
</p>
-->
_Screenshots coming soon._

## Features

- **Streaming AI conversation.** The tutor's reply appears word by word.
- **Grammar correction cards.** Each sentence you send is checked separately and shown with the original, the corrected sentence, a one-line explanation and a score out of 10.
- **Google sign-in** with Firebase Auth.
- **Practice topics and levels.** Daily life, job interview, travel or IELTS speaking, at Beginner, Intermediate or Advanced. Both feed the tutor's system prompt, and each topic starts a fresh session.
- **Progress tracking.** Daily streak, average score and sentences practised, saved to Firestore (or on the device when running without Firebase).
- **Mistake review.** Every corrected mistake is saved; mark each one as learned once you've got it.
- **Voice mode.** Speak instead of typing (speech-to-text), and hear the tutor's replies (text-to-speech). With voice mode on, your message is sent when you stop talking and the reply is read aloud: a hands-free speaking practice.
- **Bangla explanations.** An optional switch adds a short Bangla explanation to each correction, for beginners. It is saved with your mistakes for review.
- **Offline chat history.** Every chat is cached on the phone with Hive, so past conversations and their corrections can be reread without internet.
- **Friendly error handling.** Offline → retry button that keeps your message; quota hit → "Tutor is busy"; blocked or empty reply → "Could you say that another way?"; bad JSON → the card is skipped, never a crash.

## Architecture

```
lib/
  main.dart                # Firebase + App Check init, ProviderScope
  app/                     # App widget, theme
  core/                    # config (keys from config.json), failures, constants, utils
  features/
    chat/
      domain/              # Message, Correction, TutorSettings, TutorRepository (interface)
      data/                # AiService (Firebase AI Logic or Gemini API), ChatRepositoryImpl, prompts
      presentation/        # ChatScreen, ChatController, widgets/
    topics/
      presentation/        # TopicsScreen (home: level + topic picker, streak)
    progress/
      domain/              # Progress (streak + score logic), Mistake, ProgressRepository (interface)
      data/                # FirestoreProgressRepository, LocalProgressRepository
      presentation/        # ProgressScreen, MistakesScreen
    history/
      domain/              # ChatRecord, HistoryRepository (interface)
      data/                # HiveHistoryRepository
      presentation/        # HistoryScreen, HistoryDetailScreen
    voice/
      domain/              # SpeechInput, SpeechOutput (interfaces)
      data/                # speech_to_text and flutter_tts implementations
    auth/
      domain/ data/ presentation/
test/                      # mirrors lib/, plus fakes in test/helpers/
integration_test/          # full app flow on a device or simulator
```

- **Clean architecture.** Screens never call Firebase. They talk to `TutorRepository`, and only the data layer knows Gemini exists, so the model can be swapped, or faked in tests, without touching the UI.
- **Riverpod.** `ChatController` (a `Notifier`) owns the chat state. Tests override `tutorRepositoryProvider` with a fake.
- **Every outside dependency is an interface.** AI, progress, chat history, microphone and speaker each sit behind one, so all tests run with fakes: no network, keys or device needed.
- **Progress behind an interface too.** `ProgressRepository` has a Firestore version (signed in) and a `shared_preferences` version (Gemini key only). The chat saves progress in the background, and a failed save never interrupts the conversation.
- **Two Gemini calls per message.** A streaming chat call for the conversation and a structured-JSON call (`responseSchema`) for the grammar check run in parallel. The reply starts immediately, and the correction card appears when it is ready.

## Data model

All user data lives under one document per user, so the security rules in [`firestore.rules`](firestore.rules) stay simple: a user can read and write only their own path.

```
users/{uid}                  level, streakDays, lastPracticeDate, totalScore, sentencesChecked
  sessions/{sessionId}       topic, level, startedAt, messageCount, avgScore
    messages/{messageId}     role (user | tutor), text, createdAt
  mistakes/{mistakeId}       original, corrected, explanation, banglaExplanation, topic, createdAt, reviewed
```

Each correction updates the streak, the session average and the mistake list in one transaction, so they never disagree.

Chat history is also kept on the device (Hive box `chat_history`, newest 50 chats), so it works offline and without Firebase.

## Technical challenges

- Streaming + JSON correction in parallel without blocking the UI
- Mapping SDK and network errors to failures the learner can understand
- Keeping AI costs safe with App Check and no API key in the app
- Two backends behind one interface: Firebase AI Logic, or the Gemini REST API with server-sent-event streaming
- A streak that follows the learner's own calendar days, safe across month ends and daylight saving
- Voice mode that stops the tutor's speech before listening, so the microphone doesn't hear it

## Run locally (bring your own keys)

This repo contains **no API keys and no Firebase project**. All keys go in one git-ignored file:

```sh
cp config.example.json config.json   # then fill in your own values
flutter pub get
flutter run --dart-define-from-file=config.json
```

In VS Code, just press **F5**: [`.vscode/launch.json`](.vscode/launch.json) already passes `config.json`.

Fill in **either or both** of these:

| What you fill in | What you get |
|---|---|
| `GEMINI_API_KEY` only | The fastest way to try it: chat + corrections, no login. Get a free key from [Google AI Studio](https://aistudio.google.com/apikey). |
| `FIREBASE_*` values | Google sign-in, App Check, and Gemini via Firebase AI Logic (no API key inside the app). |
| Both | Firebase sign-in, with chat going straight to the Gemini API. |
| Neither | The app opens on a "No keys found" screen. |

Voice mode needs a real device or simulator with a microphone; the app asks for microphone and speech-recognition permission the first time you tap the mic.

> A `GEMINI_API_KEY` is built into the app binary. Use it only for local testing, and never share an APK built with it. For anything public, use Firebase AI Logic.

### Firebase setup (optional)

1. Create a project in the [Firebase console](https://console.firebase.google.com/) and add an Android and/or iOS app.
2. Copy the values from **Project settings → Your apps** into `config.json`. From the Android app's `google-services.json`:
   - `FIREBASE_PROJECT_ID` is `project_id`.
   - `FIREBASE_MESSAGING_SENDER_ID` is `project_number`.
   - `FIREBASE_ANDROID_APP_ID` is `mobilesdk_app_id`.
   - `FIREBASE_ANDROID_API_KEY` is `current_key`.
3. Open **AI Logic** and enable the **Gemini Developer API** (free tier).
4. Under **Authentication**, enable **Google** sign-in. On Android, add your debug SHA-1 (`cd android && ./gradlew signingReport`) to the Android app in Project settings.
5. Create a **Cloud Firestore** database and paste in the rules from [`firestore.rules`](firestore.rules).
6. In debug builds, App Check prints a debug token to the console. Add it under **App Check → Apps → Manage debug tokens**.
7. Set a budget alert in Google Cloud Billing.

## Tests

```sh
flutter test                 # unit + widget tests, no device needed
flutter test integration_test  # full app flow on a running device or simulator
```

Unit tests cover `Correction.fromJson`, the prompts, the repository with a mocked `AiService` (mocktail), and the Gemini REST client with a fake HTTP client (SSE parsing, history, errors). Progress tests cover streak rules (same day, next day, missed day, month boundary), on-device storage and the Firestore repository against `fake_cloud_firestore`. The controller and widget tests drive a fake `TutorRepository` chunk by chunk to check streaming, correction cards, retry, topic switching and mistake review. Voice tests use a fake microphone and speaker; history tests run Hive against a temp folder. The integration test goes from picking a topic to a streamed reply, a correction card and the chat appearing in history.

## What I learned

<!-- Write 3–5 short points in your own words, for example:
- What surprised you about streaming LLM replies in Flutter
- Why structured JSON output made the correction card reliable
- What clean architecture made easy to test
- What you would do differently next time
-->
_To be written._
