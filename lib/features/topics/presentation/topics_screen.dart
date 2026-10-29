import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../../chat/data/chat_providers.dart';
import '../../chat/domain/tutor_settings.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../progress/data/progress_providers.dart';
import '../../progress/presentation/progress_screen.dart';

/// Home screen: pick a level and a topic to start practising.
class TopicsScreen extends ConsumerWidget {
  const TopicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(tutorSettingsProvider);
    final level = settings.level;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI English Tutor'),
        actions: [
          IconButton(
            key: const Key('history_button'),
            tooltip: 'Chat history',
            icon: const Icon(Icons.history),
            onPressed: () => _open(context, const HistoryScreen()),
          ),
          IconButton(
            key: const Key('progress_button'),
            tooltip: 'Progress',
            icon: const Icon(Icons.insights),
            onPressed: () => _open(context, const ProgressScreen()),
          ),
          if (ref.watch(signInEnabledProvider))
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _StreakCard(),
          const SizedBox(height: 24),
          Text('Your level', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<Level>(
            segments: [
              for (final l in Level.values)
                ButtonSegment(value: l, label: Text(l.label)),
            ],
            selected: {level},
            showSelectedIcon: false,
            onSelectionChanged: (s) =>
                ref.read(tutorSettingsProvider.notifier).setLevel(s.single),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const Key('bangla_switch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Explain mistakes in Bangla too'),
            subtitle: const Text('বাংলায় ব্যাখ্যা · helpful for beginners'),
            value: settings.explainInBangla,
            onChanged: (v) =>
                ref.read(tutorSettingsProvider.notifier).setExplainInBangla(v),
          ),
          const SizedBox(height: 16),
          Text('Choose a topic', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final topic in Topic.values)
            Card(
              child: ListTile(
                key: Key('topic_${topic.name}'),
                leading: Icon(topic.icon, color: theme.colorScheme.primary),
                title: Text(topic.label),
                subtitle: Text(topic.description),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ref.read(tutorSettingsProvider.notifier).startTopic(topic);
                  _open(context, const ChatScreen());
                },
              ),
            ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

class _StreakCard extends ConsumerWidget {
  const _StreakCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progress = ref.watch(progressProvider).value;
    final streak = progress?.currentStreak(DateTime.now()) ?? 0;
    final average = progress?.averageScore;

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department,
              size: 40,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    streak == 1 ? '1-day streak' : '$streak-day streak',
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    average == null
                        ? 'Practise today to start your streak'
                        : 'Average score ${average.toStringAsFixed(1)}/10',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Topic {
  IconData get icon => switch (this) {
    Topic.dailyLife => Icons.wb_sunny_outlined,
    Topic.jobInterview => Icons.work_outline,
    Topic.travel => Icons.flight_takeoff,
    Topic.ieltsSpeaking => Icons.record_voice_over_outlined,
  };

  String get description => switch (this) {
    Topic.dailyLife => 'Family, food, hobbies and your day',
    Topic.jobInterview => 'Answer common interview questions',
    Topic.travel => 'Airports, hotels, directions and shopping',
    Topic.ieltsSpeaking => 'Practise Part 1, 2 and 3 style questions',
  };
}
