import 'dart:math';

class HourlyWeather {
  final DateTime time;
  final double temperature;
  final int weatherCode;
  final double precipitationProbability;
  final double uvIndex;
  final double? pressure; // hPa

  HourlyWeather({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    required this.precipitationProbability,
    required this.uvIndex,
    this.pressure,
  });

  String get emoji {
    if (weatherCode == 0 || weatherCode == 1) { return '☀️'; }
    if (weatherCode == 2) { return '⛅'; }
    if (weatherCode == 3) { return '☁️'; }
    if (weatherCode == 45 || weatherCode == 48) { return '🌫️'; }
    if (weatherCode >= 51 && weatherCode <= 55) { return '🌦️'; }
    if (weatherCode >= 61 && weatherCode <= 65) { return '🌧️'; }
    if (weatherCode >= 71 && weatherCode <= 77) { return '❄️'; }
    if (weatherCode >= 80 && weatherCode <= 82) { return '🌧️'; }
    if (weatherCode >= 95) { return '⛈️'; }
    return '🌤️';
  }
}

class DayWeather {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final int weatherCode;
  final double precipitationSum;
  final double windSpeedMax;
  final double uvIndexMax;
  final DateTime sunrise;
  final DateTime sunset;
  final List<HourlyWeather> hourly;

  // Daily air quality (averaged or max from hourly AQ data)
  final double? aqiUs;       // US AQI 0–500
  final double? pm25;
  final double? pollenGrass; // grains/m³
  final double? pollenTree;
  final double? pollenWeed;

  DayWeather({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.weatherCode,
    required this.precipitationSum,
    required this.windSpeedMax,
    required this.uvIndexMax,
    required this.sunrise,
    required this.sunset,
    this.hourly = const [],
    this.aqiUs,
    this.pm25,
    this.pollenGrass,
    this.pollenTree,
    this.pollenWeed,
  });

  /// Hour when temperature peaks
  HourlyWeather? get peakTempHour {
    if (hourly.isEmpty) return null;
    return hourly.reduce((a, b) => a.temperature > b.temperature ? a : b);
  }

  /// Hour when temperature is lowest
  HourlyWeather? get lowestTempHour {
    if (hourly.isEmpty) return null;
    return hourly.reduce((a, b) => a.temperature < b.temperature ? a : b);
  }

  /// Hour when UV peaks
  HourlyWeather? get peakUvHour {
    if (hourly.isEmpty) return null;
    return hourly.reduce((a, b) => a.uvIndex > b.uvIndex ? a : b);
  }

  /// Hour when UV is lowest
  HourlyWeather? get lowestUvHour {
    if (hourly.isEmpty) return null;
    return hourly.reduce((a, b) => a.uvIndex < b.uvIndex ? a : b);
  }

  bool get isGoodWeather {
    return weatherCode <= 2;
  }

  bool get isBadWeather {
    return (weatherCode >= 51 && weatherCode <= 55) || // drizzle
        (weatherCode >= 61 && weatherCode <= 67) || // rain
        (weatherCode >= 71 && weatherCode <= 77) || // snow
        (weatherCode >= 80 && weatherCode <= 82) || // showers
        weatherCode >= 95 || // thunderstorm
        weatherCode == 45 || weatherCode == 48; // fog
  }

  /// Laundry score 0–100. Higher = better day to dry clothes outside.
  /// Combines: no rain, moderate wind, high UV, low humidity from hourly data.
  int get laundryScore {
    // Rain is a hard disqualifier
    if (precipitationSum > 1.0) return 0;
    if (isBadWeather) return 0;

    int score = 50; // base

    // Rain probability boost/penalty (use hourly daytime hours 8–18)
    final daytime = hourly.where((h) => h.time.hour >= 8 && h.time.hour <= 18).toList();
    if (daytime.isNotEmpty) {
      final avgRainProb = daytime.map((h) => h.precipitationProbability).reduce((a, b) => a + b) / daytime.length;
      if (avgRainProb < 10) { score += 20; }
      else if (avgRainProb < 25) { score += 10; }
      else if (avgRainProb > 50) { score -= 20; }
      else if (avgRainProb > 70) { return 0; }
    }

    // UV boost (high UV = faster drying)
    if (uvIndexMax >= 7) { score += 15; }
    else if (uvIndexMax >= 4) { score += 8; }

    // Wind boost (10–30 km/h is ideal — not too calm, not too strong)
    if (windSpeedMax >= 10 && windSpeedMax <= 30) { score += 15; }
    else if (windSpeedMax > 30) { score += 5; } // windy but ok
    else { score += 0; } // too calm

    // Good weather bonus
    if (isGoodWeather) score += 10;

    return score.clamp(0, 100);
  }

  bool get isGoodLaundryDay => laundryScore >= 65;

  String get emoji {
    if (weatherCode == 0 || weatherCode == 1) return '☀️';
    if (weatherCode == 2) return '⛅';
    if (weatherCode == 3) return '☁️';
    if (weatherCode == 45 || weatherCode == 48) return '🌫️';
    if (weatherCode >= 51 && weatherCode <= 55) return '🌦️';
    if (weatherCode >= 61 && weatherCode <= 65) return '🌧️';
    if (weatherCode >= 66 && weatherCode <= 67) return '🌨️';
    if (weatherCode >= 71 && weatherCode <= 77) return '❄️';
    if (weatherCode >= 80 && weatherCode <= 82) return '🌧️';
    if (weatherCode >= 85 && weatherCode <= 86) return '🌨️';
    if (weatherCode >= 95) return '⛈️';
    return '🌤️';
  }

  String get description {
    const map = {
      0: 'Clear Sky', 1: 'Mainly Clear', 2: 'Partly Cloudy', 3: 'Overcast',
      45: 'Foggy', 48: 'Icy Fog',
      51: 'Light Drizzle', 53: 'Drizzle', 55: 'Heavy Drizzle',
      61: 'Light Rain', 63: 'Rain', 65: 'Heavy Rain',
      66: 'Freezing Rain', 67: 'Heavy Freezing Rain',
      71: 'Light Snow', 73: 'Snow', 75: 'Heavy Snow', 77: 'Snow Grains',
      80: 'Light Showers', 81: 'Showers', 82: 'Heavy Showers',
      85: 'Snow Showers', 86: 'Heavy Snow Showers',
      95: 'Thunderstorm', 96: 'Thunderstorm w/ Hail', 99: 'Severe Thunderstorm',
    };
    return map[weatherCode] ?? 'Unknown';
  }
}

class CurrentWeather {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int weatherCode;
  final double precipitation;
  final int uvIndex;
  final int visibility;
  final double? pressure;        // hPa surface pressure
  final double? pressureChange;  // hPa change over last 3 hours (negative = dropping)
  final double? aqiUs;           // US AQI
  final double? pm25;
  final double? pollenGrass;
  final double? pollenTree;
  final double? pollenWeed;

  CurrentWeather({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.precipitation,
    required this.uvIndex,
    required this.visibility,
    this.pressure,
    this.pressureChange,
    this.aqiUs,
    this.pm25,
    this.pollenGrass,
    this.pollenTree,
    this.pollenWeed,
  });

  /// True if pressure is dropping fast enough to potentially cause headaches
  bool get isPressureDropping {
    if (pressureChange == null) return false;
    return pressureChange! < -6.0; // drop of >6 hPa in 3h
  }

  /// AQI category label
  String get aqiLabel {
    if (aqiUs == null) return 'N/A';
    final v = aqiUs!;
    if (v <= 50) return 'Good';
    if (v <= 100) return 'Moderate';
    if (v <= 150) return 'Unhealthy for Sensitive';
    if (v <= 200) return 'Unhealthy';
    if (v <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  String get aqiEmoji {
    if (aqiUs == null) return '🌫️';
    final v = aqiUs!;
    if (v <= 50) return '😊';
    if (v <= 100) return '😐';
    if (v <= 150) return '😷';
    if (v <= 200) return '🤢';
    return '☠️';
  }

  /// Dominant pollen type and level (returns null if no data)
  ({String type, String level, String emoji})? get dominantPollen {
    final entries = <String, double>{};
    if ((pollenGrass ?? 0) > 0) entries['Grass'] = pollenGrass!;
    if ((pollenTree ?? 0) > 0) entries['Tree'] = pollenTree!;
    if ((pollenWeed ?? 0) > 0) entries['Weed'] = pollenWeed!;
    if (entries.isEmpty) return null;

    final top = entries.entries.reduce((a, b) => a.value > b.value ? a : b);
    final val = top.value;
    String level;
    String emoji;
    if (val < 10) { level = 'Low'; emoji = '🌿'; }
    else if (val < 30) { level = 'Moderate'; emoji = '🌼'; }
    else if (val < 80) { level = 'High'; emoji = '🤧'; }
    else { level = 'Very High'; emoji = '😤'; }

    return (type: top.key, level: level, emoji: emoji);
  }

  String get emoji {
    if (weatherCode == 0 || weatherCode == 1) { return '☀️'; }
    if (weatherCode == 2) { return '⛅'; }
    if (weatherCode == 3) { return '☁️'; }
    if (weatherCode == 45 || weatherCode == 48) { return '🌫️'; }
    if (weatherCode >= 51 && weatherCode <= 55) { return '🌦️'; }
    if (weatherCode >= 61 && weatherCode <= 65) { return '🌧️'; }
    if (weatherCode >= 71 && weatherCode <= 77) { return '❄️'; }
    if (weatherCode >= 80 && weatherCode <= 82) { return '🌧️'; }
    if (weatherCode >= 95) { return '⛈️'; }
    return '🌤️';
  }

  String get description {
    const map = {
      0: 'Clear Sky', 1: 'Mainly Clear', 2: 'Partly Cloudy', 3: 'Overcast',
      45: 'Foggy', 48: 'Icy Fog',
      51: 'Light Drizzle', 53: 'Drizzle', 55: 'Heavy Drizzle',
      61: 'Light Rain', 63: 'Rain', 65: 'Heavy Rain',
      71: 'Light Snow', 73: 'Snow', 75: 'Heavy Snow',
      80: 'Light Showers', 81: 'Showers', 82: 'Heavy Showers',
      95: 'Thunderstorm', 96: 'Thunderstorm w/ Hail',
    };
    return map[weatherCode] ?? 'Unknown';
  }
}

// ── Moon Phase (pure math, no API needed) ────────────────────────────────────

class MoonPhase {
  final double illumination; // 0.0 – 1.0
  final double age;          // days since new moon (0–29.53)

  const MoonPhase({required this.illumination, required this.age});

  static MoonPhase forDate(DateTime date) {
    // Known new moon reference: Jan 6, 2000
    final knownNewMoon = DateTime.utc(2000, 1, 6, 18, 14);
    final synodicMonth = 29.53058867;
    final diff = date.toUtc().difference(knownNewMoon).inSeconds / 86400.0;
    final age = diff % synodicMonth;
    final illumination = (1 - cos(2 * pi * age / synodicMonth)) / 2;
    return MoonPhase(illumination: illumination, age: age < 0 ? age + synodicMonth : age);
  }

  String get emoji {
    if (age < 1.85) return '🌑';
    if (age < 5.54) return '🌒';
    if (age < 9.22) return '🌓';
    if (age < 12.91) return '🌔';
    if (age < 16.61) return '🌕';
    if (age < 20.30) return '🌖';
    if (age < 23.99) return '🌗';
    if (age < 27.68) return '🌘';
    return '🌑';
  }

  String get name {
    if (age < 1.85) return 'New Moon';
    if (age < 5.54) return 'Waxing Crescent';
    if (age < 9.22) return 'First Quarter';
    if (age < 12.91) return 'Waxing Gibbous';
    if (age < 16.61) return 'Full Moon';
    if (age < 20.30) return 'Waning Gibbous';
    if (age < 23.99) return 'Last Quarter';
    if (age < 27.68) return 'Waning Crescent';
    return 'New Moon';
  }

  String get illuminationPercent => '${(illumination * 100).round()}%';

  /// Days until next full moon
  int get daysToFullMoon {
    const full = 14.765;
    final synodicMonth = 29.53058867;
    double diff = full - age;
    if (diff < 0) diff += synodicMonth;
    return diff.round();
  }

  /// Days until next new moon
  int get daysToNewMoon {
    const synodicMonth = 29.53058867;
    double diff = synodicMonth - age;
    if (diff < 0) diff += synodicMonth;
    return diff.round();
  }
}