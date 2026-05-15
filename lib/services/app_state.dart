import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/weather_model.dart';
import '../models/note_model.dart';
import '../services/weather_service.dart';
import '../services/note_service.dart';
import '../services/notification_service.dart';
import 'package:home_widget/home_widget.dart';

// ── A single saved location with its fetched weather data ────────────────────

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

// ── AppState ──────────────────────────────────────────────────────────────────

class AppState extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final NoteService _noteService = NoteService();
  final NotificationService _notificationService = NotificationService();

  // ── Multi-location ─────────────────────────────────────
  // Index 0 is always the primary/GPS location.
  // Saved locations start at index 1.
  final List<LocationSlot> _locations = [];
  int _activeLocationIndex = 0;

  void updateWidget() {
    final weather = activeLocation?.currentWeather;
    final note = noteForDate(DateTime.now());
    
    HomeWidget.saveWidgetData<String>('widget_city', cityName);
    HomeWidget.saveWidgetData<String>('widget_temp', weather != null ? '${TempUnit.convert(weather.temperature, useFahrenheit).round()}°' : '--°');
    HomeWidget.saveWidgetData<String>('widget_emoji', weather?.emoji ?? '🌤️');
    HomeWidget.saveWidgetData<String>('widget_note', note?.content ?? 'No plans for today');
    
    HomeWidget.updateWidget(
      name: 'WeatherWidgetProvider',
      androidName: 'WeatherWidgetProvider',
    );
  }

  List<LocationSlot> get locations => List.unmodifiable(_locations);
  int get activeLocationIndex => _activeLocationIndex;

  LocationSlot? get activeLocation =>
      _locations.isEmpty ? null : _locations[_activeLocationIndex];

  // Convenience getters that proxy the active location
  CurrentWeather? get currentWeather => activeLocation?.currentWeather;
  List<DayWeather> get forecast => activeLocation?.forecast ?? [];
  String get cityName => activeLocation?.cityName ?? '';
  String get countryName => activeLocation?.countryName ?? '';
  bool get loadingWeather => activeLocation?.loading ?? true;
  String? get weatherError => activeLocation?.error;
  bool get hasWeather => activeLocation?.hasWeather ?? false;

  DayWeather? get todayForecast => activeLocation?.todayForecast;
  DayWeather? weatherForDate(DateTime date) =>
      activeLocation?.weatherForDate(date);

  // ── Notes ──────────────────────────────────────────────
  Map<String, DayNote> notes = {};
  DayNote? noteForDate(DateTime date) => notes[_dateKey(date)];

  // ── Theme ──────────────────────────────────────────────
  bool _isDark = true;
  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDark = !_isDark;
    _noteService.saveTheme(_isDark);
    notifyListeners();
  }

  // ── Temperature unit ───────────────────────────────────
  bool _useFahrenheit = false;
  bool get useFahrenheit => _useFahrenheit;

  void toggleTempUnit() {
    _useFahrenheit = !_useFahrenheit;
    _noteService.saveTempUnit(_useFahrenheit);
    notifyListeners();
  }

  // ── Midnight timer ─────────────────────────────────────
  Timer? _midnightTimer;
  bool _disposed = false;

  // ── Init ───────────────────────────────────────────────

  Future<void> init() async {
    _isDark = await _noteService.loadTheme();
    _useFahrenheit = await _noteService.loadTempUnit();

    await _notificationService.init();
    await _notificationService.requestPermissions();
    notes = await _noteService.loadAllNotes();

    // Load primary location from cache for fast startup
    final cached = await _noteService.loadLocation();
    if (cached != null) {
      _locations.add(LocationSlot(
        lat: (cached['lat'] as num).toDouble(),
        lon: (cached['lon'] as num).toDouble(),
        cityName: cached['city'] ?? '',
        countryName: cached['country'] ?? '',
        loading: true,
      ));
      notifyListeners();
      await _fetchWeatherForSlot(0);
    }

    // Load saved secondary locations
    final saved = await _noteService.loadSavedLocations();
    for (final loc in saved) {
      if (_locations.isNotEmpty &&
          _locations[0].cityName == (loc['city'] ?? '') &&
          _locations[0].countryName == (loc['country'] ?? '')) {
        continue;
      }

      _locations.add(LocationSlot(
        lat: (loc['lat'] as num).toDouble(),
        lon: (loc['lon'] as num).toDouble(),
        cityName: loc['city'] ?? '',
        countryName: loc['country'] ?? '',
        loading: true,
      ));
    }

    if (_locations.length > 1) {
      notifyListeners();
      await Future.wait([
        for (int i = 1; i < _locations.length; i++) _fetchWeatherForSlot(i)
      ]);
    }

    await _detectLocation();
    _scheduleMidnightRefresh();
  }

  @override
  void dispose() {
    _disposed = true;
    _midnightTimer?.cancel();
    super.dispose();
  }

  // ── Location switching ─────────────────────────────────

  void switchToLocation(int index) {
    if (index < 0 || index >= _locations.length) return;
    _activeLocationIndex = index;
    notifyListeners();
  }

  // ── Add saved location ─────────────────────────────────

  Future<void> addLocation(
      double lat, double lon, String city, String country) async {
    final existingIdx = _locations
        .indexWhere((l) => l.cityName == city && l.countryName == country);
    if (existingIdx >= 0) {
      switchToLocation(existingIdx);
      return;
    }

    final slot = LocationSlot(
      lat: lat,
      lon: lon,
      cityName: city,
      countryName: country,
      loading: true,
    );
    _locations.add(slot);
    await _noteService.addSavedLocation(lat, lon, city, country);
    notifyListeners();

    final idx = _locations.length - 1;
    await _fetchWeatherForSlot(idx);
    _activeLocationIndex = idx;
    notifyListeners();
  }

  // ── Remove saved location ──────────────────────────────

  Future<void> removeLocation(int index) async {
    if (index == 0 || index >= _locations.length) return;
    final slot = _locations[index];
    _locations.removeAt(index);
    await _noteService.removeSavedLocation(slot.cityName, slot.countryName);
    if (_activeLocationIndex >= _locations.length) {
      _activeLocationIndex = 0;
    }
    notifyListeners();
  }

  // ── Fetch weather for a slot ───────────────────────────

  Future<void> _fetchWeatherForSlot(int index) async {
    if (index >= _locations.length) return;
    final slot = _locations[index];
    slot.loading = true;
    slot.error = null;
    notifyListeners();

    try {
      final result = await _weatherService.fetchWeather(slot.lat, slot.lon);
      slot.currentWeather = result.current;
      slot.forecast = result.daily;
      final now = DateTime.now();
      slot.lastFetchDate = DateTime(now.year, now.month, now.day);
      slot.loading = false;
      notifyListeners();

      if (index == _activeLocationIndex) {
        updateWidget();
      }

      if (index == 0) {
        await _notificationService.checkAndNotify(slot.forecast, _noteService);
      }
    } catch (e) {
      debugPrint(
          'Weather fetch failed for ${slot.cityName}, ${slot.countryName}: $e');
      slot.error = 'Could not load weather.';
      slot.loading = false;
      notifyListeners();
    }
  }

  // ── Refresh ────────────────────────────────────────────

  Future<void> refreshWeather() async {
    await _fetchWeatherForSlot(_activeLocationIndex);
  }

  Future<void> refreshAllWeather({bool onlyStale = false}) async {
    if (_locations.isEmpty) {
      await _detectLocation();
      return;
    }

    final indexes = <int>[
      for (int i = 0; i < _locations.length; i++)
        if (!onlyStale || _locations[i].isStale) i,
    ];

    if (indexes.isEmpty) return;

    await Future.wait([
      for (final index in indexes) _fetchWeatherForSlot(index),
    ]);
  }

  Future<void> refreshIfStale() async {
    await refreshAllWeather(onlyStale: true);
  }

  bool get isForecastStale => activeLocation?.isStale ?? true;

  // ── GPS detection ──────────────────────────────────────

  Future<void> _detectLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        if (_locations.isEmpty) await _setDefaultCity();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );

      List<Placemark> placemarks = [];
      try {
        placemarks =
            await placemarkFromCoordinates(pos.latitude, pos.longitude);
      } catch (_) {}

      final place = placemarks.isNotEmpty ? placemarks.first : null;
      final city =
          place?.locality ?? place?.administrativeArea ?? 'My Location';
      final country = place?.isoCountryCode ?? '';

      await setPrimaryLocation(pos.latitude, pos.longitude, city, country);
    } catch (_) {
      if (_locations.isEmpty) await _setDefaultCity();
    }
  }

  Future<void> _setDefaultCity() async {
    await setPrimaryLocation(51.5074, -0.1278, 'London', 'GB');
  }

  Future<void> setPrimaryLocation(
      double newLat, double newLon, String city, String country) async {
    await _noteService.saveLocation(newLat, newLon, city, country);

    final updated = LocationSlot(
      lat: newLat,
      lon: newLon,
      cityName: city,
      countryName: country,
      loading: true,
    );

    if (_locations.isEmpty) {
      _locations.add(updated);
    } else {
      _locations[0] = updated;
    }
    notifyListeners();
    await _fetchWeatherForSlot(0);
  }

  /// Used by SearchSheet for primary location changes
  Future<void> setLocation(
      double newLat, double newLon, String city, String country) async {
    await setPrimaryLocation(newLat, newLon, city, country);
  }

  // ── Midnight refresh ───────────────────────────────────

  void _scheduleMidnightRefresh() {
    if (_disposed) return;

    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now) + const Duration(seconds: 30);

    _midnightTimer = Timer(delay, () async {
      try {
        await refreshAllWeather();
      } finally {
        if (!_disposed) _scheduleMidnightRefresh();
      }
    });
  }

  // ── Notes ──────────────────────────────────────────────

  Future<void> saveNote(DayNote note) async {
    await _noteService.saveNote(note);
    notes = await _noteService.loadAllNotes();
    
    final today = DateTime.now();
    if (note.date.year == today.year && note.date.month == today.month && note.date.day == today.day) {
      updateWidget();
    }
    
    notifyListeners();
  }

  Future<void> deleteNote(DateTime date) async {
    await _noteService.deleteNote(date);
    notes = await _noteService.loadAllNotes();
    
    final today = DateTime.now();
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      updateWidget();
    }
    
    notifyListeners();
  }

  List<DateTime> get datesWithNotes => notes.values.map((n) => n.date).toList();

  /// All notes sorted: upcoming first (asc), then past (desc)
  List<DayNote> get allNotesSorted {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = notes.values.where((n) => !n.date.isBefore(today)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final past = notes.values.where((n) => n.date.isBefore(today)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return [...upcoming, ...past];
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
