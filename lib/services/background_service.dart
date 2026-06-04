import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../services/note_service.dart';
import '../services/notification_service.dart';

class BackgroundService {
  static Future<void> performWeatherCheck() async {
    final noteService = NoteService();
    final weatherService = WeatherService();
    final notificationService = NotificationService();

    try {
      // 1. Load the primary location
      final location = await noteService.loadLocation();
      if (location == null) return;

      final double lat = location['lat'];
      final double lon = location['lon'];

      // 2. Fetch fresh weather
      final result = await weatherService.fetchWeather(lat, lon);

      // 3. Initialize notifications and check
      await notificationService.init();
      await notificationService.checkAndNotify(result.daily, noteService);
    } catch (e) {
      debugPrint('Background weather check failed: $e');
    }
  }
}
