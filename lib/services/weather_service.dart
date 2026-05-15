import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

// ── Temperature unit helpers ─────────────────────────────────────────────────

class TempUnit {
  static double convert(double celsius, bool useFahrenheit) {
    return useFahrenheit ? celsius * 9 / 5 + 32 : celsius;
  }

  static String format(double celsius, bool useFahrenheit) {
    final v = convert(celsius, useFahrenheit).round();
    return '$v°${useFahrenheit ? 'F' : 'C'}';
  }

  static String symbol(bool useFahrenheit) => useFahrenheit ? '°F' : '°C';
}

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _airQualityUrl =
      'https://air-quality-api.open-meteo.com/v1/air-quality';
  static const String _geocodeUrl =
      'https://geocoding-api.open-meteo.com/v1/search';

  static double _asDouble(dynamic value, [double fallback = 0]) {
    return value is num ? value.toDouble() : fallback;
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    return value is num ? value.round() : fallback;
  }

  static dynamic _listValue(dynamic list, int index) {
    if (list is! List || index < 0 || index >= list.length) return null;
    return list[index];
  }

  /// Fetch current + 16-day daily + hourly forecast + air quality for given coordinates.
  Future<({CurrentWeather current, List<DayWeather> daily})> fetchWeather(
      double lat, double lon) async {
    // Run both requests in parallel
    final results = await Future.wait([
      _fetchForecast(lat, lon),
      _fetchAirQuality(lat, lon),
    ]);

    final forecastResult =
        results[0] as ({CurrentWeather current, List<DayWeather> daily});
    final aqResult = results[1] as _AirQualityResult;

    // Merge AQ into current weather
    final mergedCurrent = CurrentWeather(
      temperature: forecastResult.current.temperature,
      feelsLike: forecastResult.current.feelsLike,
      humidity: forecastResult.current.humidity,
      windSpeed: forecastResult.current.windSpeed,
      weatherCode: forecastResult.current.weatherCode,
      precipitation: forecastResult.current.precipitation,
      uvIndex: forecastResult.current.uvIndex,
      visibility: forecastResult.current.visibility,
      pressure: forecastResult.current.pressure,
      pressureChange: forecastResult.current.pressureChange,
      aqiUs: aqResult.currentAqi,
      pm25: aqResult.currentPm25,
      pollenGrass: aqResult.currentPollenGrass,
      pollenTree: aqResult.currentPollenTree,
      pollenWeed: aqResult.currentPollenWeed,
    );

    // Merge AQ into daily
    final mergedDaily = forecastResult.daily.map((day) {
      final dateKey =
          '${day.date.year}-${day.date.month.toString().padLeft(2, '0')}-${day.date.day.toString().padLeft(2, '0')}';
      final dayAq = aqResult.dailyAq[dateKey];
      return DayWeather(
        date: day.date,
        tempMax: day.tempMax,
        tempMin: day.tempMin,
        weatherCode: day.weatherCode,
        precipitationSum: day.precipitationSum,
        windSpeedMax: day.windSpeedMax,
        uvIndexMax: day.uvIndexMax,
        sunrise: day.sunrise,
        sunset: day.sunset,
        hourly: day.hourly,
        aqiUs: dayAq?['aqi'],
        pm25: dayAq?['pm25'],
        pollenGrass: dayAq?['pollenGrass'],
        pollenTree: dayAq?['pollenTree'],
        pollenWeed: dayAq?['pollenWeed'],
      );
    }).toList();

    return (current: mergedCurrent, daily: mergedDaily);
  }

  Future<({CurrentWeather current, List<DayWeather> daily})> _fetchForecast(
      double lat, double lon) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'current': [
        'temperature_2m',
        'apparent_temperature',
        'relative_humidity_2m',
        'precipitation',
        'weather_code',
        'wind_speed_10m',
        'visibility',
        'uv_index',
        'surface_pressure',
      ].join(','),
      'hourly': [
        'temperature_2m',
        'weather_code',
        'precipitation_probability',
        'uv_index',
        'surface_pressure',
      ].join(','),
      'daily': [
        'weather_code',
        'temperature_2m_max',
        'temperature_2m_min',
        'precipitation_sum',
        'wind_speed_10m_max',
        'uv_index_max',
        'sunrise',
        'sunset',
      ].join(','),
      'forecast_days': '16',
      'timezone': 'auto',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Weather API error: ${response.statusCode}');
    }

    final json = jsonDecode(response.body);
    final c = json['current'] as Map<String, dynamic>? ?? {};
    final d = json['daily'] as Map<String, dynamic>? ?? {};
    final h = json['hourly'] as Map<String, dynamic>? ?? {};

    // Parse hourly pressures to compute pressure change over ~3h
    final hourlyTimes = h['time'] as List? ?? [];
    final hourlyPressures = (h['surface_pressure'] as List?)
        ?.map((v) => (v as num?)?.toDouble())
        .toList();

    // Find pressure 3h ago for change calculation
    double? pressureChange;
    final currentPressure = (c['surface_pressure'] as num?)?.toDouble();
    if (hourlyPressures != null && currentPressure != null) {
      final now = DateTime.now();
      // find index closest to 3h ago
      double? pressureThreeHAgo;
      for (int i = 0; i < hourlyTimes.length; i++) {
        final t = DateTime.parse(hourlyTimes[i]);
        if (now.difference(t).inMinutes.abs() >= 150 &&
            now.difference(t).inMinutes.abs() <= 210) {
          pressureThreeHAgo = hourlyPressures[i];
          break;
        }
      }
      if (pressureThreeHAgo != null) {
        pressureChange = currentPressure - pressureThreeHAgo;
      }
    }

    final current = CurrentWeather(
      temperature: _asDouble(c['temperature_2m']),
      feelsLike:
          _asDouble(c['apparent_temperature'], _asDouble(c['temperature_2m'])),
      humidity: _asInt(c['relative_humidity_2m']),
      windSpeed: _asDouble(c['wind_speed_10m']),
      weatherCode: _asInt(c['weather_code'], 3),
      precipitation: _asDouble(c['precipitation']),
      uvIndex: _asInt(c['uv_index']),
      visibility: (_asDouble(c['visibility'], 10000) / 1000).round(),
      pressure: currentPressure,
      pressureChange: pressureChange,
    );

    // Parse all hourly entries into a map keyed by date string
    final hourlyByDate = <String, List<HourlyWeather>>{};
    for (int i = 0; i < hourlyTimes.length; i++) {
      final t = DateTime.parse(hourlyTimes[i]);
      final temperature = _listValue(h['temperature_2m'], i);
      if (temperature == null) continue;

      final dateKey =
          '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
      hourlyByDate.putIfAbsent(dateKey, () => []).add(HourlyWeather(
            time: t,
            temperature: _asDouble(temperature),
            weatherCode: _asInt(_listValue(h['weather_code'], i), 3),
            precipitationProbability:
                _asDouble(_listValue(h['precipitation_probability'], i)),
            uvIndex: _asDouble(_listValue(h['uv_index'], i)),
            pressure: _listValue(h['surface_pressure'], i) is num
                ? _asDouble(_listValue(h['surface_pressure'], i))
                : null,
          ));
    }

    final times = d['time'] as List? ?? [];
    final daily = <DayWeather>[];
    for (int i = 0; i < times.length; i++) {
      final dateKey = times[i] as String;
      daily.add(DayWeather(
        date: DateTime.parse(dateKey),
        tempMax: _asDouble(_listValue(d['temperature_2m_max'], i)),
        tempMin: _asDouble(_listValue(d['temperature_2m_min'], i)),
        weatherCode: _asInt(_listValue(d['weather_code'], i), 3),
        precipitationSum: _asDouble(_listValue(d['precipitation_sum'], i)),
        windSpeedMax: _asDouble(_listValue(d['wind_speed_10m_max'], i)),
        uvIndexMax: _asDouble(_listValue(d['uv_index_max'], i)),
        sunrise: DateTime.tryParse(_listValue(d['sunrise'], i) ?? '') ??
            DateTime.parse(dateKey),
        sunset: DateTime.tryParse(_listValue(d['sunset'], i) ?? '') ??
            DateTime.parse(dateKey),
        hourly: hourlyByDate[dateKey] ?? [],
      ));
    }

    return (current: current, daily: daily);
  }

  Future<_AirQualityResult> _fetchAirQuality(double lat, double lon) async {
    try {
      final uri = Uri.parse(
          '$_airQualityUrl?latitude=$lat&longitude=$lon&hourly=us_aqi,pm2_5&forecast_days=5&timezone=auto');

      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        debugPrint(
            'Air quality API error ${response.statusCode}: ${response.body}');
        return _AirQualityResult.empty();
      }

      final json = jsonDecode(response.body);
      final h = json['hourly'];

      double? currentAqi;
      double? currentPm25;
      double? currentPollenGrass;
      double? currentPollenTree;
      double? currentPollenWeed;

      // Build daily averages from hourly AQ data
      final dailyAq = <String, Map<String, double?>>{};
      if (h != null) {
        final times = h['time'] as List? ?? [];
        final aqiList = h['us_aqi'] as List? ?? [];
        final pm25List = h['pm2_5'] as List? ?? [];
        final grassList = h['grass_pollen'] as List? ?? [];
        final treeList = h['tree_pollen'] as List? ?? [];
        final weedList = h['weed_pollen'] as List? ?? [];

        if (times.isNotEmpty) {
          final now = DateTime.now();
          var closestIndex = 0;
          var closestDiff = const Duration(days: 9999);
          for (int i = 0; i < times.length; i++) {
            final diff = DateTime.parse(times[i]).difference(now).abs();
            if (diff < closestDiff) {
              closestDiff = diff;
              closestIndex = i;
            }
          }

          if (closestIndex < aqiList.length) {
            currentAqi = (aqiList[closestIndex] as num?)?.toDouble();
          }
          if (closestIndex < pm25List.length) {
            currentPm25 = (pm25List[closestIndex] as num?)?.toDouble();
          }
          if (closestIndex < grassList.length) {
            currentPollenGrass = (grassList[closestIndex] as num?)?.toDouble();
          }
          if (closestIndex < treeList.length) {
            currentPollenTree = (treeList[closestIndex] as num?)?.toDouble();
          }
          if (closestIndex < weedList.length) {
            currentPollenWeed = (weedList[closestIndex] as num?)?.toDouble();
          }
        }

        final dayCount = <String, int>{};
        final dayAqiSum = <String, double>{};
        final dayPm25Sum = <String, double>{};
        final dayGrassMax = <String, double>{};
        final dayTreeMax = <String, double>{};
        final dayWeedMax = <String, double>{};

        for (int i = 0; i < times.length; i++) {
          final t = DateTime.parse(times[i]);
          final dk =
              '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
          dayCount[dk] = (dayCount[dk] ?? 0) + 1;

          if (i < aqiList.length && aqiList[i] != null) {
            dayAqiSum[dk] =
                (dayAqiSum[dk] ?? 0) + (aqiList[i] as num).toDouble();
          }
          if (i < pm25List.length && pm25List[i] != null) {
            dayPm25Sum[dk] =
                (dayPm25Sum[dk] ?? 0) + (pm25List[i] as num).toDouble();
          }
          if (i < grassList.length && grassList[i] != null) {
            final v = (grassList[i] as num).toDouble();
            dayGrassMax[dk] =
                v > (dayGrassMax[dk] ?? 0) ? v : (dayGrassMax[dk] ?? 0);
          }
          if (i < treeList.length && treeList[i] != null) {
            final v = (treeList[i] as num).toDouble();
            dayTreeMax[dk] =
                v > (dayTreeMax[dk] ?? 0) ? v : (dayTreeMax[dk] ?? 0);
          }
          if (i < weedList.length && weedList[i] != null) {
            final v = (weedList[i] as num).toDouble();
            dayWeedMax[dk] =
                v > (dayWeedMax[dk] ?? 0) ? v : (dayWeedMax[dk] ?? 0);
          }
        }

        for (final dk in dayCount.keys) {
          final count = dayCount[dk]!.toDouble();
          dailyAq[dk] = {
            'aqi': dayAqiSum[dk] != null ? dayAqiSum[dk]! / count : null,
            'pm25': dayPm25Sum[dk] != null ? dayPm25Sum[dk]! / count : null,
            'pollenGrass': dayGrassMax[dk],
            'pollenTree': dayTreeMax[dk],
            'pollenWeed': dayWeedMax[dk],
          };
        }
      }

      return _AirQualityResult(
        currentAqi: currentAqi,
        currentPm25: currentPm25,
        currentPollenGrass: currentPollenGrass,
        currentPollenTree: currentPollenTree,
        currentPollenWeed: currentPollenWeed,
        dailyAq: dailyAq,
      );
    } catch (e) {
      debugPrint('Air quality fetch failed: $e');
      return _AirQualityResult.empty();
    }
  }

  Future<List<Map<String, dynamic>>> searchCity(String query) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse(_geocodeUrl).replace(queryParameters: {
      'name': query,
      'count': '5',
      'language': 'en',
      'format': 'json',
    });
    final response = await http.get(uri).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return [];
    final json = jsonDecode(response.body);
    return (json['results'] as List? ?? []).cast<Map<String, dynamic>>();
  }

  /// Fetch the latest radar and satellite tile paths from RainViewer
  Future<({String? radar, String? satellite})> fetchRadarAndSatellitePaths() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.rainviewer.com/public/weather-maps.json'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return (radar: null, satellite: null);

      final data = jsonDecode(response.body);
      
      String? radarPath;
      final radar = data['radar'];
      if (radar != null) {
        final past = radar['past'] as List?;
        if (past != null && past.isNotEmpty) {
          radarPath = past.last['path'];
        } else {
          final nowcast = radar['nowcast'] as List?;
          if (nowcast != null && nowcast.isNotEmpty) {
            radarPath = nowcast.first['path'];
          }
        }
      }

      String? satellitePath;
      final satellite = data['satellite'];
      if (satellite != null) {
        final infrared = satellite['infrared'] as List?;
        if (infrared != null && infrared.isNotEmpty) {
          satellitePath = infrared.last['path'];
        }
      }

      return (radar: radarPath, satellite: satellitePath);
    } catch (e) {
      debugPrint('Error fetching RainViewer paths: $e');
      return (radar: null, satellite: null);
    }
  }

  /// Old method for backward compatibility if needed, but we should migrate
  Future<String?> fetchRadarPath() async {
    final res = await fetchRadarAndSatellitePaths();
    return res.radar;
  }

  /// Build a smart notification message based on note content + weather
  static String buildNotificationMessage(
      String noteContent, DayWeather weather, DateTime date) {
    final dateStr = _formatDate(date);
    final keywords = noteContent.toLowerCase();

    if (weather.isBadWeather) {
      if (_hasKeyword(keywords,
          ['picnic', 'bbq', 'barbecue', 'outdoor', 'park', 'garden'])) {
        return '⚠️ Heads up! Your outdoor plan on $dateStr might be affected — ${weather.description} expected (${weather.tempMax.round()}°/${weather.tempMin.round()}°). Consider a backup plan!';
      }
      if (_hasKeyword(keywords, ['beach', 'swim', 'surf', 'boat', 'sail'])) {
        return '🌊 Beach day alert! $dateStr is showing ${weather.description}. Waves and weather might not cooperate.';
      }
      if (_hasKeyword(keywords, ['hike', 'trek', 'trail', 'climb', 'camp'])) {
        return '🥾 Trail warning! ${weather.description} expected on $dateStr. Stay safe — check conditions before you go.';
      }
      if (_hasKeyword(
          keywords, ['run', 'jog', 'cycle', 'bike', 'workout', 'exercise'])) {
        return '🏃 Weather check! ${weather.description} on $dateStr. You might want to move your workout indoors.';
      }
      if (_hasKeyword(
          keywords, ['wedding', 'party', 'event', 'birthday', 'celebration'])) {
        return '🎉 Event alert! ${weather.description} is forecast for $dateStr. If it\'s outdoors, time to prep a Plan B!';
      }
      if (_hasKeyword(
          keywords, ['travel', 'flight', 'trip', 'drive', 'road'])) {
        return '✈️ Travel heads up! ${weather.description} on $dateStr could affect your journey. Check for delays!';
      }
      return '🌧️ Weather alert for $dateStr: ${weather.description} (${weather.tempMax.round()}°/${weather.tempMin.round()}°). You have a plan that day — might be worth checking it!';
    } else if (weather.isGoodWeather) {
      if (_hasKeyword(keywords,
          ['picnic', 'bbq', 'barbecue', 'outdoor', 'park', 'garden'])) {
        return '☀️ Perfect conditions for $dateStr! ${weather.description}, ${weather.tempMax.round()}° — ideal for your outdoor plans. Enjoy!';
      }
      if (_hasKeyword(keywords, ['beach', 'swim', 'surf'])) {
        return '🏖️ Beach day approved! $dateStr looks beautiful — ${weather.description}, ${weather.tempMax.round()}°. Go make some memories!';
      }
      if (_hasKeyword(keywords, ['hike', 'trek', 'trail', 'climb', 'camp'])) {
        return '🌄 Trail conditions look great for $dateStr! ${weather.description} and ${weather.tempMax.round()}° — perfect hiking weather!';
      }
      if (_hasKeyword(keywords, ['run', 'jog', 'cycle', 'bike', 'workout'])) {
        return '🏃 Go crush it! $dateStr is ${weather.description}, ${weather.tempMax.round()}° — great day for your outdoor workout!';
      }
      if (_hasKeyword(
          keywords, ['wedding', 'party', 'event', 'birthday', 'celebration'])) {
        return '🎉 The weather gods are on your side! $dateStr looks gorgeous — ${weather.description}, ${weather.tempMax.round()}°. Your event is set!';
      }
      return '🌞 Great news for $dateStr! ${weather.description}, ${weather.tempMax.round()}°/${weather.tempMin.round()}° — perfect day for your plans!';
    } else {
      return '📅 Weather update for $dateStr: ${weather.emoji} ${weather.description}, ${weather.tempMax.round()}°/${weather.tempMin.round()}°. You have something planned!';
    }
  }

  static bool _hasKeyword(String text, List<String> keywords) {
    return keywords.any((k) => text.contains(k));
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}

class _AirQualityResult {
  final double? currentAqi;
  final double? currentPm25;
  final double? currentPollenGrass;
  final double? currentPollenTree;
  final double? currentPollenWeed;
  final Map<String, Map<String, double?>> dailyAq;

  _AirQualityResult({
    this.currentAqi,
    this.currentPm25,
    this.currentPollenGrass,
    this.currentPollenTree,
    this.currentPollenWeed,
    required this.dailyAq,
  });

  factory _AirQualityResult.empty() => _AirQualityResult(dailyAq: {});
}
