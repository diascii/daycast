import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/weather_model.dart';
import '../../services/app_state.dart';
import '../../services/weather_service.dart' show TempUnit;

/// Hourly forecast strip showing next 6 hours
class HourlyForecastStrip extends StatelessWidget {
  final AppState state;

  const HourlyForecastStrip({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    
    if (state.forecast.isEmpty) return const SizedBox();
    final now = DateTime.now();
    final allHourly = <HourlyWeather>[];
    for (final day in state.forecast.take(4)) allHourly.addAll(day.hourly);
    if (allHourly.isEmpty) return const SizedBox();

    final lookback = now.subtract(const Duration(minutes: 5));
    final slots = (allHourly..sort((a, b) => a.time.compareTo(b.time)))
        .where((h) => !h.time.isBefore(lookback))
        .take(6)
        .toList();
    if (slots.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NEXT 6 HOURS',
            style: GoogleFonts.dmSans(
                color: c.textUltraFaint, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: c.surfaceSubtle,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: slots.asMap().entries.map((entry) {
                final i = entry.key;
                final h = entry.value;
                final isNow = i == 0;
                final rainPct = h.precipitationProbability.round();
                return Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isNow ? 'Now' : DateFormat('ha').format(h.time).toLowerCase(),
                        style: GoogleFonts.dmSans(
                          color: isNow ? AppColors.accent : c.textMuted,
                          fontSize: 11,
                          fontWeight: isNow ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(h.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 6),
                      Text(
                        TempUnit.format(h.temperature, state.useFahrenheit),
                        style: GoogleFonts.dmSans(
                          color: isNow ? c.textPrimary : c.textSecondary,
                          fontSize: 14,
                          fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (rainPct > 0)
                        Text('$rainPct%',
                            style: GoogleFonts.dmSans(
                                color: const Color(0xFF64b5f6),
                                fontSize: 10,
                                fontWeight: FontWeight.w600))
                      else
                        const SizedBox(height: 14),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

/// 7-day forecast list
class WeeklyForecastStrip extends StatelessWidget {
  final AppState state;

  const WeeklyForecastStrip({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    
    if (state.forecast.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('7-DAY FORECAST',
            style: GoogleFonts.dmSans(
                color: c.textUltraFaint, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: c.surfaceSubtle,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: state.forecast.length > 7 ? 7 : state.forecast.length,
            separatorBuilder: (_, __) =>
                Divider(color: c.divider, height: 1, indent: 16, endIndent: 16),
            itemBuilder: (ctx, i) {
              final d = state.forecast[i];
              final isToday = i == 0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      isToday ? 'Today' : DateFormat('EEE').format(d.date),
                      style: GoogleFonts.dmSans(
                          color: isToday ? c.textPrimary : c.textSecondary,
                          fontSize: 14,
                          fontWeight: isToday ? FontWeight.w600 : FontWeight.w400),
                    ),
                  ),
                  Text(d.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(d.description,
                          style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 13))),
                  if (d.isGoodLaundryDay)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Text('👕', style: TextStyle(fontSize: 14)),
                    ),
                  Text(TempUnit.format(d.tempMin, state.useFahrenheit),
                      style: GoogleFonts.dmSans(color: c.textUltraFaint, fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(TempUnit.format(d.tempMax, state.useFahrenheit),
                      style: GoogleFonts.dmSans(
                          color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
              );
            },
          ),
        ),
      ],
    );
  }
}
