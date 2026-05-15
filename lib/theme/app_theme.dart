import 'package:flutter/material.dart';

class AppColors {
  final bool isDark;

  const AppColors._(this.isDark);

  factory AppColors.of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return AppColors._(brightness == Brightness.dark);
  }

  Color get scaffoldBg =>
      isDark ? const Color(0xFF0d0d14) : const Color(0xFFf0f2f8);

  Color get surface =>
      isDark ? const Color(0xFF16162a) : const Color(0xFFffffff);

  Color get surfaceElevated =>
      isDark ? const Color(0xFF13131f) : const Color(0xFFe8ecf4);

  Color get surfaceSubtle =>
      isDark ? const Color(0x0Dffffff) : const Color(0x14000000);

  Color get border =>
      isDark ? const Color(0x12ffffff) : const Color(0x28000000);

  Color get borderStrong =>
      isDark ? const Color(0x20ffffff) : const Color(0x38000000);

  // ── Text ─────────────────────────────────────────────────────────────────
  // Light mode values boosted significantly for readability:
  //   textSecondary : 80% black  (was 60%)
  //   textMuted     : 60% black  (was 38%)
  //   textFaint     : 50% black  (was 24%)
  //   textUltraFaint: 40% black  (was 15%)

  Color get textPrimary =>
      isDark ? const Color(0xFFffffff) : const Color(0xFF0d0d20);

  Color get textSecondary =>
      isDark ? const Color(0x99ffffff) : const Color(0xCC000000);

  Color get textMuted =>
      isDark ? const Color(0x61ffffff) : const Color(0x99000000);

  Color get textFaint =>
      isDark ? const Color(0x3Dffffff) : const Color(0x80000000);

  Color get textUltraFaint =>
      isDark ? const Color(0x26ffffff) : const Color(0x66000000);

  static const Color accent = Color(0xFF4f6ef7);

  Color get accentSurface =>
      isDark ? const Color(0x264f6ef7) : const Color(0x1A4f6ef7);

  Color get accentBorder =>
      isDark ? const Color(0x664f6ef7) : const Color(0x994f6ef7);

  Color get badWeatherSurface =>
      isDark ? const Color(0x26FF9800) : const Color(0x1AFF9800);

  Color get badWeatherBorder =>
      isDark ? const Color(0x4DFF9800) : const Color(0x66FF9800);

  Color get goodWeatherSurface =>
      isDark ? const Color(0x2269F0AE) : const Color(0x1A69F0AE);

  Color get calendarTodayBg =>
      isDark ? const Color(0x1Affffff) : const Color(0x1A4f6ef7);

  Color get dayNumberDefault =>
      isDark ? const Color(0xB3ffffff) : const Color(0xFF2a2a3a);

  // Light: 50% black — past days dimmed but legible (was 30%)
  Color get dayNumberPast =>
      isDark ? const Color(0x4Dffffff) : const Color(0x80000000);

  Color get dayNumberToday =>
      isDark ? const Color(0xFFffffff) : const Color(0xFF4f6ef7);

  // Slightly more visible divider in light mode (was 0x0F = 6%)
  Color get divider =>
      isDark ? const Color(0x0Dffffff) : const Color(0x1A000000);

  Color get systemNavBar =>
      isDark ? const Color(0xFF13131f) : const Color(0xFFe8ecf4);

  Brightness get statusBarIconBrightness =>
      isDark ? Brightness.light : Brightness.dark;

  List<Color> weatherBgGradient(int code) {
    if (isDark) {
      if (code <= 1) return [const Color(0xFF0a1628), const Color(0xFF0d0e1a)];
      if (code <= 3) return [const Color(0xFF111827), const Color(0xFF0d0d14)];
      if (code == 45 || code == 48) return [const Color(0xFF1a1f2e), const Color(0xFF0d0d14)];
      if (code >= 51 && code <= 55) return [const Color(0xFF0d1520), const Color(0xFF0d0d14)];
      if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) return [const Color(0xFF080f1a), const Color(0xFF0a0d12)];
      if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) return [const Color(0xFF141a2e), const Color(0xFF0f1020)];
      if (code >= 95) return [const Color(0xFF060510), const Color(0xFF0a0814)];
      return [const Color(0xFF111520), const Color(0xFF0d0d14)];
    } else {
      if (code <= 1) return [const Color(0xFFdeeeff), const Color(0xFFf0f2f8)];
      if (code <= 3) return [const Color(0xFFdde3ee), const Color(0xFFf0f2f8)];
      if (code == 45 || code == 48) return [const Color(0xFFe0e4ee), const Color(0xFFf0f2f8)];
      if (code >= 51 && code <= 55) return [const Color(0xFFd8e6f0), const Color(0xFFf0f2f8)];
      if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) return [const Color(0xFFcfdaea), const Color(0xFFf0f2f8)];
      if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) return [const Color(0xFFdde4f4), const Color(0xFFf0f2f8)];
      if (code >= 95) return [const Color(0xFFccd0e0), const Color(0xFFf0f2f8)];
      return [const Color(0xFFdde3ee), const Color(0xFFf0f2f8)];
    }
  }

  List<Color> weatherOrbColors(int code) {
    if (isDark) {
      if (code <= 1) return [const Color(0x2E3d6ee8), const Color(0x1A1e3a7a)];
      if (code <= 3) return [const Color(0x111a2535), const Color(0x0A151a2a)];
      if (code == 45 || code == 48) return [const Color(0x11aab4c8), const Color(0x0B8090a8)];
      if (code >= 51 && code <= 55) return [const Color(0x0F2a4a6e), const Color(0x0A1a3a58)];
      if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) return [const Color(0x0D1a3050), const Color(0x09102240)];
      if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) return [const Color(0x10c8d8f0), const Color(0x0Ba0b8d8)];
      if (code >= 95) return [const Color(0x0D2a1a50), const Color(0x113c2880)];
      return [const Color(0x0D2a3a5a), const Color(0x091a2a48)];
    } else {
      if (code <= 1) return [const Color(0x2A4f8ef7), const Color(0x1A2a6ad8)];
      if (code <= 3) return [const Color(0x1A8090b0), const Color(0x10607090)];
      if (code == 45 || code == 48) return [const Color(0x1Ab0b8c8), const Color(0x109098a8)];
      if (code >= 51 && code <= 55) return [const Color(0x185a7898), const Color(0x10405868)];
      if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) return [const Color(0x142a5878), const Color(0x0E1a3858)];
      if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) return [const Color(0x1A88aad0), const Color(0x1268869c)];
      if (code >= 95) return [const Color(0x16503870), const Color(0x12382060)];
      return [const Color(0x144a5878), const Color(0x0E304058)];
    }
  }
}