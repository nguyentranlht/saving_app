import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Thông báo nhắc ghi chép hằng ngày (chỉ Android / iOS).
class Reminder {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static const _id = 1;

  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    }
    await _plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    ));
    _ready = true;
  }

  /// Xin quyền hiện thông báo. Trả về true nếu được cấp.
  static Future<bool> requestPermission() async {
    if (!supported) return false;
    await _init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? true;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, badge: false, sound: true) ?? false;
  }

  /// Đặt (hoặc đặt lại) thông báo lặp mỗi ngày lúc [hour]:[minute].
  static Future<void> schedule(int hour, int minute) async {
    if (!supported) return;
    await _init();
    await _plugin.cancel(_id);
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      _id,
      'Sổ thu chi',
      'Hôm nay bạn đã ghi chép thu chi chưa?',
      at,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Nhắc ghi chép',
          channelDescription: 'Nhắc ghi chép thu chi mỗi ngày',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // Không cần quyền "báo thức chính xác"; có thể lệch vài phút.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancel() async {
    if (!supported) return;
    await _init();
    await _plugin.cancel(_id);
  }
}
