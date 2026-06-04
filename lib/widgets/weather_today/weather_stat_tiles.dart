import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

/// Generic statistics tile for weather details grid
class WeatherStatTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;

  const WeatherStatTile({
    super.key,
    required this.emoji,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.surfaceSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.dmSans(color: c.textUltraFaint, fontSize: 12)),
          ]),
          Text(value,
              style: GoogleFonts.dmSans(
                  color: c.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Pressure tile with warning indicator for rapid drops
class PressureTile extends StatelessWidget {
  final double? pressure;
  final double? change;
  final bool isDropping;

  const PressureTile({
    super.key,
    required this.pressure,
    required this.change,
    required this.isDropping,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDropping
            ? (c.isDark ? const Color(0x1AFF9800) : const Color(0x14FF6F00))
            : c.surfaceSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDropping ? c.badWeatherBorder : c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            const Text('🌬️', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text('Pressure',
                style: GoogleFonts.dmSans(color: c.textUltraFaint, fontSize: 12)),
            if (isDropping) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('⚠️ Rapid drop',
                    style: GoogleFonts.dmSans(
                        color: Colors.orange, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ],
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pressure != null ? '${pressure!.round()} hPa' : 'N/A',
                style: GoogleFonts.dmSans(
                    color: c.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
            if (change != null)
              Text(
                '${change! > 0 ? '+' : ''}${change!.toStringAsFixed(1)} hPa / 3h',
                style: GoogleFonts.dmSans(
                    color: change! < 0 ? Colors.orange : const Color(0xFF69F0AE),
                    fontSize: 10),
              ),
          ]),
        ],
      ),
    );
  }
}

/// Air Quality Index tile with color-coded status
class AqiTile extends StatelessWidget {
  final int aqi;
  final String label;
  final String emoji;

  const AqiTile({
    super.key,
    required this.aqi,
    required this.label,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    
    final Color aqiColor;
    if (aqi <= 50) {
      aqiColor = const Color(0xFF69F0AE);
    } else if (aqi <= 100) {
      aqiColor = Colors.yellow;
    } else if (aqi <= 150) {
      aqiColor = Colors.orange;
    } else if (aqi <= 200) {
      aqiColor = Colors.red;
    } else {
      aqiColor = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.surfaceSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text('Air Quality',
                style: GoogleFonts.dmSans(color: c.textUltraFaint, fontSize: 12)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: GoogleFonts.dmSans(
                    color: aqiColor, fontSize: 16, fontWeight: FontWeight.w700)),
            Text('AQI ${aqi.round()}',
                style: GoogleFonts.dmSans(color: c.textMuted, fontSize: 11)),
          ]),
        ],
      ),
    );
  }
}

/// Pollen count tile with level-based coloring
class PollenTile extends StatelessWidget {
  final String level;
  final String type;
  final String emoji;

  const PollenTile({
    super.key,
    required this.level,
    required this.type,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    
    final Color pollenColor;
    switch (level) {
      case 'Low': pollenColor = const Color(0xFF69F0AE); break;
      case 'Moderate': pollenColor = Colors.yellow; break;
      case 'High': pollenColor = Colors.orange; break;
      default: pollenColor = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.surfaceSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text('Pollen',
                style: GoogleFonts.dmSans(color: c.textUltraFaint, fontSize: 12)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(level,
                style: GoogleFonts.dmSans(
                    color: pollenColor, fontSize: 16, fontWeight: FontWeight.w700)),
            Text('$type pollen',
                style: GoogleFonts.dmSans(color: c.textMuted, fontSize: 11)),
          ]),
        ],
      ),
    );
  }
}
