# Graph Report - .  (2026-05-16)

## Corpus Check
- Corpus is ~29,633 words - fits in a single context window. You may not need a graph.

## Summary
- 487 nodes · 533 edges · 44 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 1 edges (avg confidence: 0.5)
- Token cost: 0 input · 0 output


## Input Scope
- Requested: auto
- Resolved: committed (source: default-auto)
- Included files: 63 · Candidates: 252
- Excluded: 69 untracked · 18447 ignored · 0 sensitive · 1 missing committed
- Recommendation: Use --scope all or graphify.yaml inputs.corpus for a knowledge-base folder.

## Graph Freshness
- Built from Git commit: `a716640`
- Compare this hash to `git rev-parse HEAD` before trusting freshness-sensitive graph output.
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

### Community 26 - "Community 26"
Cohesion: 0.5
Nodes (1): WeatherPlannerApp

### Community 39 - "Community 39"
Cohesion: 1
Nodes (1): DayNote

### Community 21 - "Community 21"
Cohesion: 0.4
Nodes (4): HourlyWeather, DayWeather, CurrentWeather, MoonPhase

### Community 11 - "Community 11"
Cohesion: 0.14
Nodes (4): CalendarScreen, _CalendarScreenState, _LocationSearchSheet, _LocationSearchSheetState

### Community 13 - "Community 13"
Cohesion: 0.15
Nodes (3): DayDetailScreen, _DayDetailScreenState, _FullscreenImageViewer

### Community 22 - "Community 22"
Cohesion: 0.4
Nodes (2): NotesScreen, _NotesScreenState

### Community 14 - "Community 14"
Cohesion: 0.2
Nodes (2): WeatherMapScreen, _WeatherMapScreenState

### Community 27 - "Community 27"
Cohesion: 0.5
Nodes (1): WeatherTodayScreen

### Community 4 - "Community 4"
Cohesion: 0.07
Nodes (2): AppState, LocationSlot

### Community 5 - "Community 5"
Cohesion: 0.08
Nodes (1): NoteService

### Community 17 - "Community 17"
Cohesion: 0.22
Nodes (1): NotificationService

### Community 10 - "Community 10"
Cohesion: 0.13
Nodes (3): TempUnit, WeatherService, _AirQualityResult

### Community 40 - "Community 40"
Cohesion: 1
Nodes (1): AppColors

### Community 29 - "Community 29"
Cohesion: 0.5
Nodes (2): SearchSheet, _SearchSheetState

### Community 30 - "Community 30"
Cohesion: 0.5
Nodes (2): WeatherShareCard, ShareUtils

### Community 36 - "Community 36"
Cohesion: 0.67
Nodes (2): HourlyForecastStrip, WeeklyForecastStrip

### Community 41 - "Community 41"
Cohesion: 1
Nodes (1): MoonPhaseTile

### Community 19 - "Community 19"
Cohesion: 0.33
Nodes (2): WeatherAnimatedBackground, _WeatherAnimatedBackgroundState

### Community 12 - "Community 12"
Cohesion: 0.14
Nodes (4): _Particle, _WeatherParticlesPainter, WeatherParticles, _WeatherParticlesState

### Community 24 - "Community 24"
Cohesion: 0.4
Nodes (4): WeatherStatTile, PressureTile, AqiTile, PollenTile

### Community 20 - "Community 20"
Cohesion: 0.33
Nodes (1): FlutterWindow()

### Community 31 - "Community 31"
Cohesion: 0.67
Nodes (2): GetCommandLineArguments(), Utf8FromUtf16()

### Community 6 - "Community 6"
Cohesion: 0.17
Nodes (16): Scale(), EnableFullDpiSupportIfAvailable(), WindowClassRegistrar, GetWindowClass(), UnregisterWindowClass(), Win32Window(), Create(), Win32Window::WndProc() (+8 more)

### Community 32 - "Community 32"
Cohesion: 0.67
Nodes (1): GeneratedPluginRegistrant

### Community 25 - "Community 25"
Cohesion: 0.5
Nodes (2): handle_new_rx_page(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.

### Community 33 - "Community 33"
Cohesion: 0.67
Nodes (2): GeneratedPluginRegistrant, -registerWithRegistry

### Community 34 - "Community 34"
Cohesion: 0.67
Nodes (1): LocationSlot

### Community 35 - "Community 35"
Cohesion: 0.67
Nodes (1): HomeWidgetService

### Community 28 - "Community 28"
Cohesion: 0.5
Nodes (1): NoteImageService

### Community 23 - "Community 23"
Cohesion: 0.4
Nodes (1): NotificationMessageBuilder

### Community 18 - "Community 18"
Cohesion: 0.29
Nodes (2): LocationSearchSheet, _LocationSearchSheetState

### Community 8 - "Community 8"
Cohesion: 0.11
Nodes (7): _Particle, _WeatherParticlesPainter, _WeatherParticles, _WeatherParticlesState, _LightBackground, _LightBackgroundState, WeatherTodayScreen

### Community 2 - "Community 2"
Cohesion: 0.11
Nodes (34): graphify, .graphify/, .graphify/GRAPH_REPORT.md, .graphify/wiki/index.md, $graphify ..., /graphify ... (Codex), graphify ., .graphify/.graphify_runtime.json (+26 more)

### Community 16 - "Community 16"
Cohesion: 0.2
Nodes (9): analyzer, Dart, flutter analyze, package:flutter_lints/flutter.yaml, avoid_print, prefer_single_quotes, https://dart.dev/tools#ides-and-editors, https://dart.dev/lints (+1 more)

### Community 3 - "Community 3"
Cohesion: 0.07
Nodes (33): lib/README.md, weather_planner (Project), note_service.dart, http (Package), geolocator (Package), geocoding (Package), flutter_local_notifications (Package), shared_preferences (Package) (+25 more)

### Community 0 - "Community 0"
Cohesion: 0.07
Nodes (39): linux/CMakeLists.txt, linux/flutter/CMakeLists.txt, linux/runner/CMakeLists.txt, web/index.html, windows/CMakeLists.txt, windows/runner/CMakeLists.txt, Flutter, CMake (+31 more)

### Community 1 - "Community 1"
Cohesion: 0.07
Nodes (40): windows/flutter/CMakeLists.txt, flutter_assemble (CMake Target), flutter (CMake Library), libflutter_linux_gtk.so, icudtl.dat, libapp.so (Linux), fl_basic_message_channel.h, fl_binary_codec.h (+32 more)

### Community 53 - "Community 53"
Cohesion: 1
Nodes (1): linter

### Community 9 - "Community 9"
Cohesion: 0.11
Nodes (19): Weather Planner (Application), Open-Meteo, Calendar (Feature), Weather badges (Feature), Notes (Feature), Smart notifications (Feature), Bad weather alerts (Feature), Good weather hype (Feature) (+11 more)

### Community 7 - "Community 7"
Cohesion: 0.1
Nodes (20): lib/, main.dart, models/, weather_model.dart, DayWeather, CurrentWeather, note_model.dart, DayNote (+12 more)

### Community 50 - "Community 50"
Cohesion: 1
Nodes (1): CMAKE_INSTALL_PREFIX (CMake Variable)

### Community 49 - "Community 49"
Cohesion: 1
Nodes (1): BUILD_BUNDLE_DIR (CMake Variable)

### Community 52 - "Community 52"
Cohesion: 1
Nodes (1): EPHEMERAL_DIR (CMake Variable)

### Community 51 - "Community 51"
Cohesion: 1
Nodes (1): cpp_client_wrapper

## Knowledge Gaps
- **165 isolated node(s):** `WeatherPlannerApp`, `DayNote`, `HourlyWeather`, `DayWeather`, `CurrentWeather` (+160 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 26`** (1 nodes): `WeatherPlannerApp`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 39`** (1 nodes): `DayNote`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 22`** (2 nodes): `NotesScreen`, `_NotesScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 14`** (2 nodes): `WeatherMapScreen`, `_WeatherMapScreenState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 27`** (1 nodes): `WeatherTodayScreen`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 4`** (2 nodes): `AppState`, `LocationSlot`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 5`** (1 nodes): `NoteService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 17`** (1 nodes): `NotificationService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 40`** (1 nodes): `AppColors`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 29`** (2 nodes): `SearchSheet`, `_SearchSheetState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 30`** (2 nodes): `WeatherShareCard`, `ShareUtils`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 36`** (2 nodes): `HourlyForecastStrip`, `WeeklyForecastStrip`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 41`** (1 nodes): `MoonPhaseTile`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 19`** (2 nodes): `WeatherAnimatedBackground`, `_WeatherAnimatedBackgroundState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 20`** (1 nodes): `FlutterWindow()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 31`** (2 nodes): `GetCommandLineArguments()`, `Utf8FromUtf16()`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 32`** (1 nodes): `GeneratedPluginRegistrant`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 25`** (2 nodes): `handle_new_rx_page()`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 33`** (2 nodes): `GeneratedPluginRegistrant`, `-registerWithRegistry`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 34`** (1 nodes): `LocationSlot`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 35`** (1 nodes): `HomeWidgetService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 28`** (1 nodes): `NoteImageService`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 23`** (1 nodes): `NotificationMessageBuilder`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 18`** (2 nodes): `LocationSearchSheet`, `_LocationSearchSheetState`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 53`** (1 nodes): `linter`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 50`** (1 nodes): `CMAKE_INSTALL_PREFIX (CMake Variable)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 49`** (1 nodes): `BUILD_BUNDLE_DIR (CMake Variable)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 52`** (1 nodes): `EPHEMERAL_DIR (CMake Variable)`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 51`** (1 nodes): `cpp_client_wrapper`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `weather_planner (Project)` connect `Community 3` to `Community 0`?**
  _High betweenness centrality (0.064) - this node is a cross-community bridge._
- **Why does `daycast (Application)` connect `Community 0` to `Community 1`, `Community 3`?**
  _High betweenness centrality (0.059) - this node is a cross-community bridge._
- **Why does `lib/README.md` connect `Community 3` to `Community 9`, `Community 7`?**
  _High betweenness centrality (0.044) - this node is a cross-community bridge._
- **What connects `WeatherPlannerApp`, `DayNote`, `HourlyWeather` to the rest of the system?**
  _165 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 11` be split into smaller, more focused modules?**
  _Cohesion score 0.14 - nodes in this community are weakly interconnected._
- **Should `Community 4` be split into smaller, more focused modules?**
  _Cohesion score 0.07 - nodes in this community are weakly interconnected._
- **Should `Community 5` be split into smaller, more focused modules?**
  _Cohesion score 0.08 - nodes in this community are weakly interconnected._