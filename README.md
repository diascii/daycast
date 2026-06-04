# Daycast

A weather-aware calendar planner app that helps you plan your days with confidence. Combines weather forecasts, daily notes, and a smart laundry-day indicator into one clean interface.

## Features

- **Weather + Calendar** — see the 7-day forecast alongside your daily plans on one screen
- **Daily Notes** — jot down plans for any day; shown on your home screen widget
- **Hourly Forecast** — detailed 6-hour breakdown with temperature, conditions, UV index, and precipitation probability
- **Interactive Charts** — temperature and condition charts for any forecast day
- **Multi-Location** — save and switch between multiple cities
- **Weather Map** — OpenWeatherMap layer overlay
- **Laundry Day AI** — automatically highlights days with optimal drying conditions (clear sky, low wind, low humidity)
- **Home Screen Widget** — 3x1 (expandable to 5x2) with live time, weather, today's note, and 6-hour forecast strip
- **Daily Summary Notifications** — get a morning push with the day's weather and your top plan
- **Background Updates** — weather refreshes every 3 hours via WorkManager
- **Dark/Light Theme** — follows system preference
- **Share Cards** — export a beautiful weather snapshot as an image

## Screens

| Screen | Description |
|--------|-------------|
| **Calendar** | Monthly calendar with weather indicators, daily notes, and laundry-day highlights |
| **Today** | Scrollable weather briefing: current conditions, hourly strip, 7-day forecast |
| **Day Detail** | Deep-dive into any day: 3-hourly chart, air quality, wind, UV, precipitation |
| **Notes** | Browse and manage all saved daily notes |
| **Weather Map** | Interactive map with weather layer overlay |

## Tech Stack

- **Framework**: Flutter (multi-platform)
- **Weather API**: Open-Meteo (free, no API key needed)
- **State Management**: ChangeNotifier + Provider
- **Background Tasks**: WorkManager
- **Home Widget**: home_widget plugin (Android 12+, Kotlin RemoteViews)
- **Maps**: flutter_map + OpenWeatherMap tiles
- **Notifications**: flutter_local_notifications

## Widget

A home screen widget shows at a glance:

**3x1 default**: Time · temperature · weather emoji · city · today's note
**5x2 expanded**: Adds a 6-hour forecast strip with time, condition, and temperature

The widget features a frosted-glass background with dynamic transparency, warm-amber temperature accent, and auto-updates whenever weather or notes change in the app.

## Building

```bash
# Install dependencies
flutter pub get

# Build for Android (split per ABI)
flutter build apk --split-per-abi

# Install on connected device
adb install -r build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
```

## Project Structure

```
lib/
├── main.dart                    # App entry, WorkManager init
├── models/
│   ├── weather_model.dart       # CurrentWeather, DayWeather, HourlyWeather
│   ├── note_model.dart          # DayNote model
│   └── location_slot.dart       # Location + forecast storage
├── services/
│   ├── app_state.dart           # Global state, weather fetching, widget updates
│   ├── weather_service.dart     # Open-Meteo API client
│   ├── note_service.dart        # Note persistence
│   ├── notification_service.dart # Push notifications
│   ├── background_service.dart  # Background weather check
│   └── home_widget_service.dart # Widget data bridge
├── screens/
│   ├── calendar_screen.dart     # Main calendar view
│   ├── weather_today_screen.dart # Today's weather briefing
│   ├── day_detail_screen.dart   # Per-day forecast detail
│   ├── notes_screen.dart        # Note management
│   └── weather_map_screen.dart  # Weather map
├── widgets/
│   ├── weather_today/           # Hourly/weekly forecast strips
│   ├── settings_sheet.dart
│   ├── location_search_sheet.dart
│   ├── search_sheet.dart
│   └── weather_share_card.dart
└── theme/
    └── app_theme.dart           # Dark/light color schemes
```

## Credits

Powered by [Open-Meteo](https://open-meteo.com/) — free and open-source weather API.
