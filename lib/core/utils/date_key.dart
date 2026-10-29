/// A local calendar day as `yyyy-MM-dd`, so streaks follow the learner's
/// own days and ignore time zones and clock times.
String dateKey(DateTime time) {
  final local = time.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)}';
}

/// The day before [time], safe across daylight-saving changes.
String previousDateKey(DateTime time) {
  final local = time.toLocal();
  return dateKey(DateTime(local.year, local.month, local.day - 1));
}
