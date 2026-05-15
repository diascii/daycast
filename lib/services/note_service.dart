import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';

class NoteService {
  static const String _notesKey = 'weather_planner_notes';
  static const String _locationKey = 'weather_planner_location';
  static const String _savedLocationsKey = 'weather_planner_saved_locations';
  static const String _notifiedKey = 'weather_planner_notified';
  static const String _themeKey = 'weather_planner_dark_mode';
  static const String _tempUnitKey = 'weather_planner_fahrenheit';

  // ── Notes ──────────────────────────────────────────────

  Future<Map<String, DayNote>> loadAllNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notesKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, DayNote.fromJson(v)));
  }

  Future<void> saveNote(DayNote note) async {
    final all = await loadAllNotes();
    all[_dateKey(note.date)] = note;
    await _persist(all);
  }

  Future<void> deleteNote(DateTime date) async {
    final all = await loadAllNotes();
    all.remove(_dateKey(date));
    await _persist(all);
  }

  Future<DayNote?> getNoteForDate(DateTime date) async {
    final all = await loadAllNotes();
    return all[_dateKey(date)];
  }

  Future<void> _persist(Map<String, DayNote> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(notes.map((k, v) => MapEntry(k, v.toJson())));
    await prefs.setString(_notesKey, raw);
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  // ── Location ───────────────────────────────────────────

  Future<void> saveLocation(double lat, double lon, String city, String country) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _locationKey, jsonEncode({'lat': lat, 'lon': lon, 'city': city, 'country': country}));
  }

  Future<Map<String, dynamic>?> loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_locationKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Saved locations (multi-location) ──────────────────

  Future<List<Map<String, dynamic>>> loadSavedLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedLocationsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> addSavedLocation(double lat, double lon, String city, String country) async {
    final all = await loadSavedLocations();
    // Avoid duplicates by city name
    all.removeWhere((l) => l['city'] == city && l['country'] == country);
    all.add({'lat': lat, 'lon': lon, 'city': city, 'country': country});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedLocationsKey, jsonEncode(all));
  }

  Future<void> removeSavedLocation(String city, String country) async {
    final all = await loadSavedLocations();
    all.removeWhere((l) => l['city'] == city && l['country'] == country);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedLocationsKey, jsonEncode(all));
  }

  // ── Theme ──────────────────────────────────────────────

  Future<void> saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  /// Returns true (dark) by default if never set
  Future<bool> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? true;
  }

  // ── Temperature unit ───────────────────────────────────

  Future<void> saveTempUnit(bool useFahrenheit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tempUnitKey, useFahrenheit);
  }

  /// Returns false (Celsius) by default if never set
  Future<bool> loadTempUnit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tempUnitKey) ?? false;
  }

  // ── Notified tracking (avoid duplicate notifications) ──

  Future<Set<String>> loadNotifiedKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_notifiedKey) ?? [];
    return list.toSet();
  }

  Future<void> markNotified(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_notifiedKey) ?? [];
    if (!existing.contains(key)) {
      existing.add(key);
      await prefs.setStringList(_notifiedKey, existing);
    }
  }

  // Clean up old notified keys (older than 30 days)
  Future<void> pruneOldNotified() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_notifiedKey) ?? [];
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final pruned = existing.where((k) {
      try {
        final d = DateTime.parse(k.split('_').first);
        return d.isAfter(cutoff);
      } catch (_) {
        return false;
      }
    }).toList();
    await prefs.setStringList(_notifiedKey, pruned);
  }
}