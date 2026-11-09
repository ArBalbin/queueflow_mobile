/// When a wait counts as long enough to warn the student about it.
///
/// Most waits at the cashier are two or three minutes; a quarter of an hour is
/// long enough that a student may want to come back later instead.
const double kLongWaitMinutes = 15;

bool isLongWait(double minutes) => minutes >= kLongWaitMinutes;

/// "about 25 min", or "about 1 hr 10 min" past an hour.
String describeWait(double minutes) {
  final total = minutes.round();
  if (total < 60) return 'about $total min';
  final hours = total ~/ 60;
  final rest = total % 60;
  return rest == 0 ? 'about $hours hr' : 'about $hours hr $rest min';
}

/// "1:00 PM" in the phone's own time.
String formatClockTime(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${time.hour < 12 ? 'AM' : 'PM'}';
}

/// Remembers which tickets were already shown the long-wait message, so it
/// appears once per ticket rather than on every refresh.
class LongWaitNotice {
  static final Set<int> _shown = {};

  static bool shouldShow(int queueNumber, double minutes) =>
      queueNumber > 0 && isLongWait(minutes) && !_shown.contains(queueNumber);

  static void markShown(int queueNumber) => _shown.add(queueNumber);
}
