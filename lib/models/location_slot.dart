import 'weather_model.dart';

class LocationSlot {
  final double lat;
  final double lon;
  final String cityName;
  final String countryName;

  CurrentWeather? currentWeather;
  List<DayWeather> forecast;
  bool loading;
  String? error;
  DateTime? lastFetchDate;

  LocationSlot({
    required this.lat,
    required this.lon,
    required this.cityName,
    required this.countryName,
    this.currentWeather,
    this.forecast = const [],
    this.loading = false,
    this.error,
    this.lastFetchDate,
  });

  bool get hasWeather => currentWeather != null;

  DayWeather? weatherForDate(DateTime date) {
    final key = _dateKey(date);
    try {
      return forecast.firstWhere((d) => _dateKey(d.date) == key);
    } catch (_) {
      return null;
    }
  }

  DayWeather? get todayForecast => weatherForDate(DateTime.now());

  bool get isStale {
    if (lastFetchDate == null) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return lastFetchDate != today;
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
