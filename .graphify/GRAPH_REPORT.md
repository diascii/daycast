# Graph Report - .  (2026-05-15)

## Corpus Check
- Corpus is ~30,543 words - fits in a single context window. You may not need a graph.

## Summary
- 448 nodes · 500 edges · 39 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.5)
- Token cost: 10,000 input · 10,000 output


## Input Scope
- Requested: all
- Resolved: all (source: configured-default)
- Included files: 66 · Candidates: recursive
- Excluded: 0 untracked · 0 ignored · 0 sensitive · 0 missing committed
## God Nodes (most connected - your core abstractions)
1. `flutter_assemble (CMake Target)` - 39 edges
2. `weather_planner (Project)` - 25 edges
3. `daycast (Application)` - 23 edges
4. `lib/README.md` - 17 edges
5. `linux/CMakeLists.txt` - 15 edges
6. `Weather Planner (Application)` - 14 edges
7. `windows/CMakeLists.txt` - 11 edges
8. `flutter (CMake Library)` - 11 edges
9. `linux/flutter/CMakeLists.txt` - 8 edges
10. `web/index.html` - 8 edges

## Surprising Connections (you probably didn't know these)
- `windows/flutter/CMakeLists.txt` --includes--> `generated_config.cmake`  [EXTRACTED]
  windows/flutter/CMakeLists.txt → linux/flutter/CMakeLists.txt
- `weather_planner (Project)` --builds_to_executable--> `daycast (Application)`  [INFERRED]
  lib/README.md → linux/CMakeLists.txt
- `weather_planner (Project)` --uses_sdk--> `Flutter`  [EXTRACTED]
  lib/README.md → analysis_options.yaml
- `weather_planner (Project)` --depends_on--> `timezone (Package)`  [EXTRACTED]
  lib/README.md → pubspec.yaml
- `weather_planner (Project)` --depends_on--> `image_picker (Package)`  [EXTRACTED]
  lib/README.md → pubspec.yaml

## Communities

### Community 0 - "Community 0"
Cohesion: 0.07
Nodes (39): AOT_LIBRARY (CMake Variable), CMake, com.example.daycast, daycast (Application), dwmapi.lib, favicon.png, FLUTTER_ASSET_DIR_NAME (CMake Variable), $FLUTTER_BASE_HREF (+31 more)

### Community 1 - "Community 1"
Cohesion: 0.07
Nodes (40): app.so (Windows), core_implementations.cc, flutter_assemble (CMake Target), flutter_engine.cc, flutter_export.h, flutter (CMake Library), flutter_linux.h, flutter_messenger.h (+32 more)

### Community 2 - "Community 2"
Cohesion: 0.11
Nodes (34): graphify ., Bash, .graphify/branch.json, git mv -f graphify-out .graphify, git rm --cached ..., git rm -r --cached ..., graphify migrate-state --dry-run, graphify portable-check .graphify (+26 more)

### Community 3 - "Community 3"
Cohesion: 0.07
Nodes (33): assets/app_icon.png, DM Sans typeface, Dynamic gradient, flutter_animate (Package), flutter_launcher_icons (Package), flutter_lints (Package), flutter_local_notifications (Package), flutter_map (Package) (+25 more)

### Community 4 - "Community 4"
Cohesion: 0.09
Nodes (2): AppState, LocationSlot

### Community 5 - "Community 5"
Cohesion: 0.17
Nodes (16): Create(), Destroy(), EnableFullDpiSupportIfAvailable(), GetClientArea(), GetThisFromHandle(), GetWindowClass(), MessageHandler(), OnCreate() (+8 more)

### Community 6 - "Community 6"
Cohesion: 0.1
Nodes (20): app_theme.dart, calendar_screen.dart, City search bottom sheet, CurrentWeather, Dark mode, day_detail_screen.dart, DayNote, DayWeather (+12 more)

### Community 7 - "Community 7"
Cohesion: 0.11
Nodes (7): _LightBackground, _LightBackgroundState, _Particle, _WeatherParticles, _WeatherParticlesPainter, _WeatherParticlesState, WeatherTodayScreen

### Community 8 - "Community 8"
Cohesion: 0.11
Nodes (19): app_state.dart, ChangeNotifier, Auto-location (Feature), Bad weather alerts (Feature), Calendar (Feature), City search (Feature), Good weather hype (Feature), Keyword detection (Feature) (+11 more)

### Community 9 - "Community 9"
Cohesion: 0.13
Nodes (1): NoteService

### Community 10 - "Community 10"
Cohesion: 0.13
Nodes (3): _AirQualityResult, TempUnit, WeatherService

### Community 11 - "Community 11"
Cohesion: 0.14
Nodes (4): CalendarScreen, _CalendarScreenState, _LocationSearchSheet, _LocationSearchSheetState

### Community 12 - "Community 12"
Cohesion: 0.14
Nodes (4): _Particle, WeatherParticles, _WeatherParticlesPainter, _WeatherParticlesState

### Community 13 - "Community 13"
Cohesion: 0.15
Nodes (3): DayDetailScreen, _DayDetailScreenState, _FullscreenImageViewer

### Community 14 - "Community 14"
Cohesion: 0.2
Nodes (2): WeatherMapScreen, _WeatherMapScreenState

### Community 16 - "Community 16"
Cohesion: 0.2
Nodes (9): analyzer, Dart, https://dart.dev/guides/language/analysis-options, https://dart.dev/tools#ides-and-editors, https://dart.dev/lints, flutter analyze, package:flutter_lints/flutter.yaml, avoid_print (+1 more)

### Community 17 - "Community 17"
Cohesion: 0.29
Nodes (1): NotificationService

### Community 18 - "Community 18"
Cohesion: 0.33
Nodes (2): WeatherAnimatedBackground, _WeatherAnimatedBackgroundState

### Community 19 - "Community 19"
Cohesion: 0.33
Nodes (1): FlutterWindow()

### Community 20 - "Community 20"
Cohesion: 0.4
Nodes (4): CurrentWeather, DayWeather, HourlyWeather, MoonPhase

### Community 21 - "Community 21"
Cohesion: 0.4
Nodes (2): NotesScreen, _NotesScreenState

### Community 22 - "Community 22"
Cohesion: 0.4
Nodes (4): AqiTile, PollenTile, PressureTile, WeatherStatTile

### Community 23 - "Community 23"
Cohesion: 0.5
Nodes (2): handle_new_rx_page(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.

### Community 24 - "Community 24"
Cohesion: 0.5
Nodes (1): WeatherTodayScreen

### Community 25 - "Community 25"
Cohesion: 0.5
Nodes (2): SearchSheet, _SearchSheetState

### Community 26 - "Community 26"
Cohesion: 0.5
Nodes (2): ShareUtils, WeatherShareCard

### Community 27 - "Community 27"
Cohesion: 0.67
Nodes (2): GetCommandLineArguments(), Utf8FromUtf16()

### Community 28 - "Community 28"
Cohesion: 0.67
Nodes (1): GeneratedPluginRegistrant

### Community 29 - "Community 29"
Cohesion: 0.67
Nodes (2): GeneratedPluginRegistrant, -registerWithRegistry

### Community 30 - "Community 30"
Cohesion: 0.67
Nodes (1): WeatherPlannerApp

### Community 31 - "Community 31"
Cohesion: 0.67
Nodes (2): HourlyForecastStrip, WeeklyForecastStrip

### Community 34 - "Community 34"
Cohesion: 1
Nodes (1): DayNote

### Community 35 - "Community 35"
Cohesion: 1
Nodes (1): AppColors

### Community 36 - "Community 36"
Cohesion: 1
Nodes (1): MoonPhaseTile

### Community 43 - "Community 43"
Cohesion: 1
Nodes (1): BUILD_BUNDLE_DIR (CMake Variable)

### Community 44 - "Community 44"
Cohesion: 1
Nodes (1): CMAKE_INSTALL_PREFIX (CMake Variable)

### Community 45 - "Community 45"
Cohesion: 1
Nodes (1): cpp_client_wrapper

### Community 46 - "Community 46"
Cohesion: 1
Nodes (1): EPHEMERAL_DIR (CMake Variable)

### Community 47 - "Community 47"
Cohesion: 1
Nodes (1): linter

## Knowledge Gaps
- **159 isolated node(s):** `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `-registerWithRegistry`, `WeatherPlannerApp`, `DayNote`, `HourlyWeather` (+154 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 4`** (2 nodes): `AppState`, `LocationSlot`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 9`** (1 nodes): `NoteService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 14`** (2 nodes): `WeatherMapScreen`, `_WeatherMapScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 17`** (1 nodes): `NotificationService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 18`** (2 nodes): `WeatherAnimatedBackground`, `_WeatherAnimatedBackgroundState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 19`** (1 nodes): `FlutterWindow()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 21`** (2 nodes): `NotesScreen`, `_NotesScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 23`** (2 nodes): `handle_new_rx_page()`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 24`** (1 nodes): `WeatherTodayScreen`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 25`** (2 nodes): `SearchSheet`, `_SearchSheetState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 26`** (2 nodes): `ShareUtils`, `WeatherShareCard`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 27`** (2 nodes): `GetCommandLineArguments()`, `Utf8FromUtf16()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 28`** (1 nodes): `GeneratedPluginRegistrant`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 29`** (2 nodes): `GeneratedPluginRegistrant`, `-registerWithRegistry`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 30`** (1 nodes): `WeatherPlannerApp`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 31`** (2 nodes): `HourlyForecastStrip`, `WeeklyForecastStrip`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 34`** (1 nodes): `DayNote`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 35`** (1 nodes): `AppColors`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 36`** (1 nodes): `MoonPhaseTile`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 43`** (1 nodes): `BUILD_BUNDLE_DIR (CMake Variable)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 44`** (1 nodes): `CMAKE_INSTALL_PREFIX (CMake Variable)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 45`** (1 nodes): `cpp_client_wrapper`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 46`** (1 nodes): `EPHEMERAL_DIR (CMake Variable)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 47`** (1 nodes): `linter`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `weather_planner (Project)` connect `Community 3` to `Community 0`?**
  _High betweenness centrality (0.075) - this node is a cross-community bridge._
- **Why does `daycast (Application)` connect `Community 0` to `Community 1`, `Community 3`?**
  _High betweenness centrality (0.069) - this node is a cross-community bridge._
- **Why does `lib/README.md` connect `Community 3` to `Community 8`, `Community 6`?**
  _High betweenness centrality (0.052) - this node is a cross-community bridge._
- **What connects `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `-registerWithRegistry`, `WeatherPlannerApp` to the rest of the system?**
  _159 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.07 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.07 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.11 - nodes in this community are weakly interconnected._