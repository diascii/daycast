import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/weather_model.dart';
import '../models/note_model.dart';
import '../services/weather_service.dart';
import '../services/note_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
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

  /// Check all notes against the current forecast and fire notifications
  /// for dates that just entered the forecast window.
  Future<void> checkAndNotify(
      List<DayWeather> forecast, NoteService noteService) async {
    await noteService.pruneOldNotified();
    final notified = await noteService.loadNotifiedKeys();
    final notes = await noteService.loadAllNotes();

    final forecastMap = {
      for (final d in forecast)
        '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}-${d.date.day.toString().padLeft(2, '0')}':
            d
    };

    int notifId = 1000;

    for (final entry in notes.entries) {
      final dateKey = entry.key;
      final note = entry.value;

      // Only future dates
      if (!note.date.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
        continue;
      }

      final weather = forecastMap[dateKey];
      if (weather == null) continue; // Not in forecast window yet

      // Build a unique key: dateKey + weatherCode
      final notifKey = '${dateKey}_${weather.weatherCode}';
      if (notified.contains(notifKey)) continue; // Already notified

      final message = WeatherService.buildNotificationMessage(
          note.content, weather, note.date);

      final title = weather.isBadWeather
          ? '${weather.emoji} Weather Warning for your plan!'
          : weather.isGoodWeather
              ? '${weather.emoji} Great weather for your plan!'
              : '${weather.emoji} Weather update for your plan';

      await showWeatherAlert(id: notifId++, title: title, body: message);
      await noteService.markNotified(notifKey);
    }
  }

  /// Schedule a daily morning check at 8 AM
  Future<void> scheduleDailyCheck() async {
    // In a real app you'd use timezone + tz.TZDateTime for precise scheduling.
    // For simplicity we show how to schedule a daily notification.
    const androidDetails = AndroidNotificationDetails(
      'daily_weather_check',
      'Daily Weather Check',
      channelDescription: 'Morning weather check for your plans',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
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
