import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../models/weather_model.dart';
import '../theme/app_theme.dart';
import '../services/weather_service.dart' show TempUnit;
import '../widgets/weather_share_card.dart';
import 'weather_map_screen.dart';
import '../widgets/weather_today/weather_animated_background.dart';
import '../widgets/weather_today/forecast_strips.dart';
import '../widgets/weather_today/moon_phase_tile.dart';
import '../widgets/weather_today/weather_stat_tiles.dart';

/// Refactored Weather Today Screen - now under 300 lines
class WeatherTodayScreen extends StatelessWidget {
  final AppState state;
  const WeatherTodayScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (_, __) {
        final c = AppColors.of(context);
        final weatherCode = state.currentWeather?.weatherCode ?? 3;

        if (state.loadingWeather && state.currentWeather == null) {
          return _buildLoadingState(c);
        }

        if (state.weatherError != null && state.currentWeather == null) {
          return _buildErrorState(c);
        }

        final current = state.currentWeather!;
        final today = state.todayForecast;

        return WeatherAnimatedBackground(
          weatherCode: weatherCode,
          isDark: c.isDark,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WeatherMapScreen(state: state),
                          ),
                        );
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: c.surfaceSubtle,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.map_rounded, color: c.textPrimary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _showShareDialog(context, state, c),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: c.surfaceSubtle,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.share_rounded, color: c.textPrimary, size: 20),
                      ),
                    ),
                  ],
                ),
                _buildCurrentWeather(context, current, today, c),
                const SizedBox(height: 24),
                HourlyForecastStrip(state: state).animate().fadeIn(duration: 500.ms, delay: 100.ms),
                const SizedBox(height: 24),
                WeeklyForecastStrip(state: state).animate().fadeIn(duration: 500.ms, delay: 200.ms),
                const SizedBox(height: 24),
                _buildCurrentDetails(context, current, today, c).animate().fadeIn(duration: 500.ms, delay: 300.ms),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(AppColors c) {
    return WeatherAnimatedBackground(
      weatherCode: 3,
      isDark: c.isDark,
      child: Center(
        child: CircularProgressIndicator(color: c.textMuted, strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorState(AppColors c) {
    return WeatherAnimatedBackground(
      weatherCode: 3,
      isDark: c.isDark,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(state.weatherError!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(color: c.textMuted, fontSize: 15)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: state.refreshWeather,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Retry', style: GoogleFonts.dmSans()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentWeather(BuildContext context, CurrentWeather current,
      DayWeather? today, AppColors c) {
    return Builder(
      builder: (context) => Column(
        children: [
          Text(current.emoji, style: const TextStyle(fontSize: 80))
              .animate(onPlay: (ctrl) => ctrl.repeat())
              .shimmer(duration: 3000.ms, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${TempUnit.convert(current.temperature, state.useFahrenheit).round()}',
                style: GoogleFonts.dmSans(
                    color: c.textPrimary, fontSize: 80,
                    fontWeight: FontWeight.w200, height: 1),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(TempUnit.symbol(state.useFahrenheit),
                    style: GoogleFonts.dmSans(
                        color: c.textFaint, fontSize: 28, fontWeight: FontWeight.w300)),
              ),
            ],
          ),
          Text(current.description,
              style: GoogleFonts.dmSans(
                  color: c.textSecondary, fontSize: 18, fontWeight: FontWeight.w400)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Feels like ${TempUnit.format(current.feelsLike, state.useFahrenheit)}',
                  style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 13)),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showFeelsLikeInfo(context, current, c);
                },
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: c.textFaint, width: 1)),
                  child: Center(
                    child: Text('?',
                        style: GoogleFonts.dmSans(
                            color: c.textFaint, fontSize: 9,
                            fontWeight: FontWeight.w700, height: 1)),
                  ),
                ),
              ),
              if (today != null) ...[
                const SizedBox(width: 12),
                Container(width: 1, height: 10, color: c.border),
                const SizedBox(width: 12),
                Text(
                  '${TempUnit.format(today.tempMin, state.useFahrenheit)} / ${TempUnit.format(today.tempMax, state.useFahrenheit)}',
                  style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 13),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: GoogleFonts.dmSans(color: c.textUltraFaint, fontSize: 12)),
        ],
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05),
    );
  }

  void _showFeelsLikeInfo(BuildContext context, CurrentWeather current, AppColors c) {
    final feelsConverted = TempUnit.convert(current.feelsLike, state.useFahrenheit);
    final actualConverted = TempUnit.convert(current.temperature, state.useFahrenheit);
    final diff = (feelsConverted - actualConverted).round();
    final absDiff = diff.abs();
    final unitSymbol = TempUnit.symbol(state.useFahrenheit);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: c.textUltraFaint, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: c.accentSurface, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('🌡️', style: TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Feels Like Temperature',
                    style: GoogleFonts.dmSans(
                        color: c.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
                Text('Also called Apparent Temperature',
                    style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 12)),
              ]),
            ]),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: c.surfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border)),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Actual', style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 12)),
                  Text(TempUnit.format(current.temperature, state.useFahrenheit),
                      style: GoogleFonts.dmSans(
                          color: c.textPrimary, fontSize: 22, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(width: 24),
                Container(width: 1, height: 36, color: c.border),
                const SizedBox(width: 24),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Feels Like', style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 12)),
                  Text(TempUnit.format(current.feelsLike, state.useFahrenheit),
                      style: GoogleFonts.dmSans(
                          color: AppColors.accent, fontSize: 22, fontWeight: FontWeight.w600)),
                ]),
                if (absDiff > 0) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: diff < 0
                          ? const Color(0xFF64b5f6).withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${diff > 0 ? '+' : '-'}$absDiff$unitSymbol',
                      style: GoogleFonts.dmSans(
                          color: diff < 0 ? const Color(0xFF64b5f6) : Colors.orange,
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            Text('What is it?',
                style: GoogleFonts.dmSans(
                    color: c.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Apparent temperature is how hot or cold it actually feels on your skin — not just what the thermometer reads. It combines the real air temperature with wind speed and humidity to give you a more accurate sense of comfort.',
              style: GoogleFonts.dmSans(color: c.textMuted, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 14),
            Text('Why does it differ?',
                style: GoogleFonts.dmSans(
                    color: c.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              absDiff == 0
                  ? 'Right now they match — calm winds and moderate humidity mean the air temperature is a perfect reflection of how it feels outside.'
                  : diff < 0
                      ? 'Right now it feels $absDiff$unitSymbol cooler than the actual temperature. This is likely due to wind chill — moving air carries heat away from your body faster, making it feel colder.'
                      : 'Right now it feels $absDiff$unitSymbol warmer than the actual temperature. High humidity is likely the cause — when air is humid, sweat evaporates more slowly, so your body can\'t cool itself as well.',
              style: GoogleFonts.dmSans(color: c.textMuted, fontSize: 13, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentDetails(BuildContext context, CurrentWeather current,
      DayWeather? today, AppColors c) {
    final moon = MoonPhase.forDate(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CURRENT CONDITIONS',
            style: GoogleFonts.dmSans(
                color: c.textUltraFaint, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        MoonPhaseTile(
          emoji: moon.emoji,
          name: moon.name,
          illuminationPercent: (moon.illumination * 100).round(),
          fullMoonEmoji: '🌕',
          fullMoonLabel: 'Full',
          daysToFullMoon: moon.daysToFullMoon,
          newMoonEmoji: '🌑',
          newMoonLabel: 'New',
          daysToNewMoon: moon.daysToNewMoon,
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            WeatherStatTile(emoji: '💧', label: 'Humidity', value: '${current.humidity}%'),
            WeatherStatTile(emoji: '💨', label: 'Wind', value: '${current.windSpeed.round()} km/h'),
            WeatherStatTile(emoji: '🌡️', label: 'UV Index', value: '${current.uvIndex}'),
            WeatherStatTile(emoji: '👁️', label: 'Visibility', value: '${current.visibility} km'),
            if (today != null) ...[
              WeatherStatTile(emoji: '🌅', label: 'Sunrise', value: DateFormat('h:mm a').format(today.sunrise)),
              WeatherStatTile(emoji: '🌇', label: 'Sunset', value: DateFormat('h:mm a').format(today.sunset)),
            ],
            PressureTile(pressure: current.pressure, change: current.pressureChange, isDropping: current.isPressureDropping),
            if (current.aqiUs != null) AqiTile(aqi: current.aqiUs!.round(), label: current.aqiLabel, emoji: current.aqiEmoji),
            if (current.dominantPollen != null) PollenTile(level: current.dominantPollen!.level, type: current.dominantPollen!.type, emoji: current.dominantPollen!.emoji),
          ],
        ),
      ],
    );
  }

  void _showShareDialog(BuildContext context, AppState state, AppColors c) {
    final shareKey = GlobalKey();
    final weather = state.currentWeather;
    if (weather == null) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: RepaintBoundary(
                key: shareKey,
                child: WeatherShareCard(
                  cityName: state.cityName,
                  weather: weather,
                  note: state.noteForDate(DateTime.now()),
                  useFahrenheit: state.useFahrenheit,
                  isDark: state.isDark,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    await ShareUtils.captureAndShare(shareKey, state.cityName);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  icon: const Icon(Icons.send_rounded),
                  label: Text('Share Now', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
