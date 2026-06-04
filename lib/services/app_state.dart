import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/location_slot.dart';
import '../models/weather_model.dart';
import '../models/note_model.dart';
import '../services/home_widget_service.dart';
import '../services/weather_service.dart';
import '../services/note_service.dart';
import '../services/notification_service.dart';

// ── AppState ──────────────────────────────────────────────────────────────────

class AppState extends ChangeNotifier {
  final WeatherService _weatherService = WeatherService();
  final NoteService _noteService = NoteService();
  final NotificationService _notificationService = NotificationService();
  final HomeWidgetService _homeWidgetService = HomeWidgetService();

  // ── Multi-location ─────────────────────────────────────
  final List<LocationSlot> _locations = [];
  int _activeLocationIndex = 0;

  List<LocationSlot> get locations => List.unmodifiable(_locations);
  int get activeLocationIndex => _activeLocationIndex;
  LocationSlot? get activeLocation => _locations.isEmpty ? null : _locations[_activeLocationIndex];

  // Convenience getters
  CurrentWeather? get currentWeather => activeLocation?.currentWeather;
  List<DayWeather> get forecast => activeLocation?.forecast ?? [];
  String get cityName => activeLocation?.cityName ?? '';
  String get countryName => activeLocation?.countryName ?? '';
  bool get loadingWeather => activeLocation?.loading ?? true;
  String? get weatherError => activeLocation?.error;
  bool get hasWeather => activeLocation?.hasWeather ?? false;

  DayWeather? get todayForecast => activeLocation?.todayForecast;
  DayWeather? weatherForDate(DateTime date) => activeLocation?.weatherForDate(date);

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
    updateWidget();
    notifyListeners();
  }

  // ── Laundry toggle ─────────────────────────────────────
  bool _isLaundryEnabled = true;
  bool get isLaundryEnabled => _isLaundryEnabled;

  void toggleLaundry() {
    _isLaundryEnabled = !_isLaundryEnabled;
    _noteService.saveLaundryEnabled(_isLaundryEnabled);
    notifyListeners();
  }

  // ── Daily Summary ──────────────────────────────────────
  bool _isDailySummaryEnabled = false;
  TimeOfDay _dailySummaryTime = const TimeOfDay(hour: 19, minute: 0);

  bool get isDailySummaryEnabled => _isDailySummaryEnabled;
  TimeOfDay get dailySummaryTime => _dailySummaryTime;

  void toggleDailySummary() {
    _isDailySummaryEnabled = !_isDailySummaryEnabled;
    _noteService.saveDailySummaryEnabled(_isDailySummaryEnabled);
    if (_isDailySummaryEnabled) {
      _notificationService.scheduleDailySummary(_dailySummaryTime.hour, _dailySummaryTime.minute);
    } else {
      _notificationService.cancelDailySummary();
    }
    notifyListeners();
  }

  void setDailySummaryTime(TimeOfDay time) {
    _dailySummaryTime = time;
    _noteService.saveDailySummaryTime(time);
    if (_isDailySummaryEnabled) {
      _notificationService.scheduleDailySummary(time.hour, time.minute);
    }
    notifyListeners();
  }

  // ── Widget Theme ────────────────────────────────────────
  int _widgetThemeIndex = 0;
  int get widgetThemeIndex => _widgetThemeIndex;

  void setWidgetTheme(int index) {
    _widgetThemeIndex = index;
    _noteService.saveWidgetTheme(index);
    updateWidget();
    notifyListeners();
  }

  // ── Midnight timer ─────────────────────────────────────
  Timer? _midnightTimer;
  bool _disposed = false;

  // ── Init ───────────────────────────────────────────────

  Future<void> init() async {
    _isDark = await _noteService.loadTheme();
    _useFahrenheit = await _noteService.loadTempUnit();
    _isLaundryEnabled = await _noteService.loadLaundryEnabled();
    _isDailySummaryEnabled = await _noteService.loadDailySummaryEnabled();
    _dailySummaryTime = await _noteService.loadDailySummaryTime();
    _widgetThemeIndex = await _noteService.loadWidgetTheme();

    await _notificationService.init();
    await _notificationService.requestPermissions();

    if (_isDailySummaryEnabled) {
      _notificationService.scheduleDailySummary(_dailySummaryTime.hour, _dailySummaryTime.minute);
    }

    notes = await _noteService.loadAllNotes();

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
      await Future.wait([for (int i = 1; i < _locations.length; i++) _fetchWeatherForSlot(i)]);
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

  // ── Logic ──────────────────────────────────────────────

  void switchToLocation(int index) {
    if (index < 0 || index >= _locations.length) return;
    _activeLocationIndex = index;
    notifyListeners();
  }

  Future<void> addLocation(double lat, double lon, String city, String country) async {
    final existingIdx = _locations.indexWhere((l) => l.cityName == city && l.countryName == country);
    if (existingIdx >= 0) {
      switchToLocation(existingIdx);
      return;
    }
    final slot = LocationSlot(lat: lat, lon: lon, cityName: city, countryName: country, loading: true);
    _locations.add(slot);
    await _noteService.addSavedLocation(lat, lon, city, country);
    notifyListeners();
    final idx = _locations.length - 1;
    await _fetchWeatherForSlot(idx);
    _activeLocationIndex = idx;
    notifyListeners();
  }

  Future<void> removeLocation(int index) async {
    if (index == 0 || index >= _locations.length) return;
    final slot = _locations[index];
    _locations.removeAt(index);
    await _noteService.removeSavedLocation(slot.cityName, slot.countryName);
    if (_activeLocationIndex >= _locations.length) _activeLocationIndex = 0;
    notifyListeners();
  }

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
      if (index == _activeLocationIndex) await updateWidget();
      if (index == 0) await _notificationService.checkAndNotify(slot.forecast, _noteService);
    } catch (e) {
      slot.error = 'Could not load weather.';
      slot.loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshWeather() async => await _fetchWeatherForSlot(_activeLocationIndex);

  Future<void> refreshIfStale() async {
    if (activeLocation == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (activeLocation!.lastFetchDate == null || activeLocation!.lastFetchDate!.isBefore(today)) {
      await refreshWeather();
    }
  }

  Future<void> setLocation(double lat, double lon, String city, String country) async =>
      await setPrimaryLocation(lat, lon, city, country);

  Future<void> updateWidget() async {
    final weather = activeLocation?.currentWeather;
    final note = noteForDate(DateTime.now());

    final allHourly = <HourlyWeather>[];
    for (final day in forecast.take(3)) {
      allHourly.addAll(day.hourly);
    }
    allHourly.sort((a, b) => a.time.compareTo(b.time));
    final nextHours = allHourly.where((h) => h.time.isAfter(DateTime.now())).take(6).toList();

    await _homeWidgetService.update(
      cityName: cityName,
      useFahrenheit: useFahrenheit,
      weather: weather,
      note: note,
      nextHours: nextHours.isNotEmpty ? nextHours : null,
      widgetThemeIndex: _widgetThemeIndex,
    );
  }

  Future<void> _detectLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        if (_locations.isEmpty) await _setDefaultCity();
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low, timeLimit: const Duration(seconds: 10));
      List<Placemark> placemarks = [];
      try { placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude); } catch (_) {}
      final place = placemarks.isNotEmpty ? placemarks.first : null;
      final city = place?.locality ?? place?.administrativeArea ?? 'My Location';
      final country = place?.isoCountryCode ?? '';
      await setPrimaryLocation(pos.latitude, pos.longitude, city, country);
    } catch (_) { if (_locations.isEmpty) await _setDefaultCity(); }
  }

  Future<void> _setDefaultCity() async => await setPrimaryLocation(51.5074, -0.1278, 'London', 'GB');

  Future<void> setPrimaryLocation(double newLat, double newLon, String city, String country) async {
    await _noteService.saveLocation(newLat, newLon, city, country);
    final updated = LocationSlot(lat: newLat, lon: newLon, cityName: city, countryName: country, loading: true);
    if (_locations.isEmpty) { _locations.add(updated); } else { _locations[0] = updated; }
    notifyListeners();
    await _fetchWeatherForSlot(0);
  }

  void _scheduleMidnightRefresh() {
    if (_disposed) return;
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final delay = nextMidnight.difference(now) + const Duration(seconds: 30);
    _midnightTimer = Timer(delay, () async {
      try { await _fetchWeatherForSlot(0); } finally { if (!_disposed) _scheduleMidnightRefresh(); }
    });
  }

  Future<void> saveNote(DayNote note) async {
    await _noteService.saveNote(note);
    notes = await _noteService.loadAllNotes();
    final today = DateTime.now();
    if (note.date.year == today.year && note.date.month == today.month && note.date.day == today.day) await updateWidget();
    notifyListeners();
  }

  Future<void> deleteNote(DateTime date) async {
    await _noteService.deleteNote(date);
    notes = await _noteService.loadAllNotes();
    final today = DateTime.now();
    if (date.year == today.year && date.month == today.month && date.day == today.day) await updateWidget();
    notifyListeners();
  }

  String _dateKey(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
