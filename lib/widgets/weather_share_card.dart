import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/weather_model.dart';
import '../models/note_model.dart';
import '../theme/app_theme.dart';
import '../services/weather_service.dart' show TempUnit;

class WeatherShareCard extends StatelessWidget {
  final String cityName;
  final CurrentWeather weather;
  final DayNote? note;
  final bool useFahrenheit;
  final bool isDark;

  const WeatherShareCard({
    super.key,
    required this.cityName,
    required this.weather,
    required this.note,
    required this.useFahrenheit,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final gradient = colors.weatherBgGradient(weather.weatherCode);
    
    return Container(
      width: 1080 / 3, // Target 1080px width, scaled down for preview
      height: 1920 / 3, // Target 1920px height
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient,
        ),
      ),
      child: Stack(
        children: [
          // Background orbs decoration (simpler version of the app one)
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  cityName.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                Text(
                  DateFormat('EEEE, MMM d').format(DateTime.now()),
                  style: GoogleFonts.dmSans(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                Center(
                  child: Column(
                    children: [
                      Text(
                        weather.emoji,
                        style: const TextStyle(fontSize: 100),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${TempUnit.convert(weather.temperature, useFahrenheit).round()}',
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 90,
                              fontWeight: FontWeight.w200,
                              height: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              TempUnit.symbol(useFahrenheit),
                              style: GoogleFonts.dmSans(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 32,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        weather.description.toUpperCase(),
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (note != null && note!.content.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(note!.category.emoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              note!.category.label.toUpperCase(),
                              style: GoogleFonts.dmSans(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          note!.content,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 2,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'DAYCAST WEATHER PLANNER',
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShareUtils {
  static Future<void> captureAndShare(GlobalKey key, String cityName) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Increase pixelRatio for better quality (3.0 = high res)
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final buffer = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/daycast_share.png').create();
      await file.writeAsBytes(buffer);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Checking the weather in $cityName with Daycast! 🌦️',
      );
    } catch (e) {
      debugPrint('Error sharing: $e');
    }
  }
}
