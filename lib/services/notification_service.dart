import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../models/weather_model.dart';
import '../services/notification_message_builder.dart';
import '../services/note_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    tz.initializeTimeZones();
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> showWeatherAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'weather_plan_alerts',
      'Weather Plan Alerts',
      channelDescription: 'Alerts when forecast matches your plans',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  Future<void> checkAndNotify(List<DayWeather> forecast, NoteService noteService) async {
    await noteService.pruneOldNotified();
    final notified = await noteService.loadNotifiedKeys();
    final notes = await noteService.loadAllNotes();

    final forecastMap = {
      for (final d in forecast)
        '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}-${d.date.day.toString().padLeft(2, '0')}': d
    };

    int notifId = 1000;

    for (final entry in notes.entries) {
      final dateKey = entry.key;
      final note = entry.value;

      if (!note.date.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
        continue;
      }

      final weather = forecastMap[dateKey];
      if (weather == null) continue;

      final notifKey = '${dateKey}_${weather.weatherCode}';
      if (notified.contains(notifKey)) continue;

      final message = NotificationMessageBuilder.build(note.content, weather, note.date);

      final title = weather.isBadWeather
          ? '${weather.emoji} Weather Warning for your plan!'
          : weather.isGoodWeather
              ? '${weather.emoji} Great weather for your plan!'
              : '${weather.emoji} Weather update for your plan';

      await showWeatherAlert(id: notifId++, title: title, body: message);
      await noteService.markNotified(notifKey);
    }
  }

  Future<void> scheduleDailySummary(int hour, int minute) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_summary',
      'Daily Weather Summary',
      channelDescription: 'Summary of tomorrow\'s weather',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      1,
      '📅 Tomorrow\'s Outlook',
      'Tap to see the weather summary for your plans.',
      scheduledDate,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailySummary() async {
    await _plugin.cancel(1);
  }

  Future<void> scheduleDailyCheck() async {
    const androidDetails = AndroidNotificationDetails(
      'daily_weather_check',
      'Daily Weather Check',
      channelDescription: 'Morning weather check for your plans',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.periodicallyShow(
      0,
      '🌤️ Good morning!',
      'Checking weather for your upcoming plans...',
      RepeatInterval.daily,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
