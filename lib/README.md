# 🌤️ Weather Planner

A weather-aware calendar planner. Every day on the calendar shows the forecast emoji + temp. Tap any day to see the full weather and write notes/plans. When a future date with a note enters the 16-day forecast window, you get a smart notification.

**No API key needed.** Uses Open-Meteo (free & open-source).

---

## ✨ Features

| Feature | Details |
|---|---|
| 📅 Calendar | Month grid with weather emoji on each forecasted day |
| 🌤️ Weather badges | Each day cell shows emoji + temp (up to 16 days ahead) |
| 📝 Notes | Add notes to any day — Plan, Reminder, Journal, or Event |
| 🔮 Future dates | Beyond forecast window show 🔮 — no fake data |
| 🔔 Smart notifications | Fires when a noted date enters the forecast window |
| ⚠️ Bad weather alerts | Warns about rain/storms on your planned days |
| ☀️ Good weather hype | Motivates you when the forecast looks great |
| 🧠 Keyword detection | Note says "picnic"? Gets a tailored message, not generic one |
| 📍 Auto-location | GPS on launch, falls back to London if denied |
| 🔍 City search | Search any city worldwide |
| 🗂️ Upcoming plans | List of future notes with weather below the calendar |

---

## 🚀 Setup

```bash
# 1. Create a new Flutter project (gets you android/ ios/ scaffolding)
flutter create weather_planner
cd weather_planner

# 2. Replace lib/ with these files
# 3. Replace pubspec.yaml with the provided one
# 4. Merge AndroidManifest.xml and Info.plist

# 5. Install dependencies
flutter pub get

# 6. Run
flutter run
```

---

## 📁 File Structure

```
lib/
├── main.dart
├── models/
│   ├── weather_model.dart       # DayWeather, CurrentWeather
│   └── note_model.dart          # DayNote, NoteCategory
├── services/
│   ├── app_state.dart           # Central state (ChangeNotifier)
│   ├── weather_service.dart     # Open-Meteo API + notification messages
│   ├── note_service.dart        # shared_preferences storage
│   └── notification_service.dart
├── screens/
│   ├── calendar_screen.dart     # Main calendar + bottom nav
│   ├── day_detail_screen.dart   # Per-day weather + note editor
│   └── weather_today_screen.dart
├── theme/
│   └── app_theme.dart           # Light/Dark mode
└── widgets/
    └── search_sheet.dart        # City search bottom sheet
```

---

## 🔔 Notification Logic

```
App opens / refreshes weather
    ↓
Fetch 16-day forecast from Open-Meteo
    ↓
For each note with a future date:
    Is it in the forecast window? → No  → skip (🔮, no data yet)
                                 → Yes → Has it been notified already?
                                             → Yes → skip (no duplicate)
                                             → No  → Check weather code
                                                        Bad weather → ⚠️ warn
                                                        Good weather → ☀️ hype
                                                        Neutral → 📅 soft reminder
                                                      Fire notification
                                                      Mark as notified
```

Notification keys include the weather code, so if conditions change dramatically (e.g. sunny → stormy), a new notification fires.

---

## 📦 Dependencies

| Package | Purpose |
|---|---|
| `http` | API calls |
| `geolocator` | GPS |
| `geocoding` | Coords → city name |
| `flutter_local_notifications` | Push notifications |
| `shared_preferences` | Local note storage |
| `table_calendar` | Calendar widget |
| `flutter_animate` | Animations |
| `google_fonts` | DM Sans typography |
| `uuid` | Unique note IDs |
| `intl` | Date formatting |

---

## 🌐 APIs

- **Weather**: `https://api.open-meteo.com/v1/forecast` (16-day daily + current)
- **City search**: `https://geocoding-api.open-meteo.com/v1/search`
- Both are 100% free, no signup, no key

---

## 🎨 Design

- Deep navy dark background `#0d0d14`
- Indigo accent `#4f6ef7`
- DM Sans typeface
- Glassmorphism cards with subtle borders
- Dynamic gradient on day detail screen based on weather condition
- Bad weather notes highlighted with orange border in upcoming list
