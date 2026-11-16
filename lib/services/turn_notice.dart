import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// How close the estimated wait must be for the "your turn is near" heads-up.
///
/// Suggested by a student in the user acceptance test: a warning about five
/// minutes before the turn, so a student who stepped away can come back in
/// time. Until then the app said nothing until the student was first in line,
/// and only on the screen, never as a phone notification.
const double kTurnSoonMinutes = 5;

/// Decides, once per ticket, whether the heads-up is due.
class TurnSoonNotice {
  static final Set<int> _shown = {};

  /// [minutes] is the app's estimated wait, null while there is none yet.
  /// At first in line the "You're next" screen takes over instead.
  static bool shouldShow(int queueNumber, double? minutes, int positionInLine) =>
      queueNumber > 0 &&
      minutes != null &&
      minutes <= kTurnSoonMinutes &&
      positionInLine > 1 &&
      !_shown.contains(queueNumber);

  static void markShown(int queueNumber) => _shown.add(queueNumber);
}

/// Phone notifications about the student's turn. Every call is best-effort:
/// a phone that refuses notifications still gets the on-screen message.
class TurnNotifier {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static final Set<String> _sent = {};

  static const AndroidNotificationDetails _android = AndroidNotificationDetails(
    'queue_turn',
    'Queue turn',
    channelDescription: 'Tells you when your turn at the cashier is near.',
    importance: Importance.max,
    priority: Priority.high,
  );

  static Future<void> init() async {
    if (_ready) return;
    try {
      await _plugin.initialize(
        settings: InitializationSettings(
          android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('[QueuEx] Notifications unavailable: $e');
    }
  }

  /// Asks Android 13 and later for permission to notify. Called when the
  /// student starts waiting, when the request makes sense to them.
  static Future<void> requestPermission() async {
    await init();
    if (!_ready) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (_) {
      // The on-screen message still appears.
    }
  }

  /// Shows a notification once per [key] (for example, once per ticket).
  static Future<void> showOnce(String key, String title, String body) async {
    if (_sent.contains(key)) return;
    _sent.add(key);
    await init();
    if (!_ready) return;
    try {
      await _plugin.show(
        id: key.hashCode & 0x7fffffff,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: _android,
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('[QueuEx] Notification failed: $e');
    }
  }
}
