import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/app_state.dart';
import 'screens/calendar_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = AppState();
  await appState.init();

  runApp(WeatherPlannerApp(state: appState));
}

class WeatherPlannerApp extends StatelessWidget {
  final AppState state;
  const WeatherPlannerApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (_, __) {
        final isDark = state.isDark;

        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor:
              isDark ? const Color(0xFF13131f) : const Color(0xFFe8ecf4),
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ));

        return MaterialApp(
          title: 'Daycast',
          debugShowCheckedModeBanner: false,
          themeMode: state.themeMode,
          // ── Dark theme ──────────────────────────────────
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4f6ef7),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0d0d14),
            useMaterial3: true,
          ),
          // ── Light theme ─────────────────────────────────
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4f6ef7),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFf0f2f8),
            useMaterial3: true,
          ),
          home: CalendarScreen(state: state),
        );
      },
    );
  }
}