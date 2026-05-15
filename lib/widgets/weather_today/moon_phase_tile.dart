import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

/// Moon phase display tile widget
class MoonPhaseTile extends StatelessWidget {
  final String emoji;
  final String name;
  final int illuminationPercent;
  final String fullMoonEmoji;
  final String fullMoonLabel;
  final int daysToFullMoon;
  final String newMoonEmoji;
  final String newMoonLabel;
  final int daysToNewMoon;

  const MoonPhaseTile({
    super.key,
    required this.emoji,
    required this.name,
    required this.illuminationPercent,
    required this.fullMoonEmoji,
    required this.fullMoonLabel,
    required this.daysToFullMoon,
    required this.newMoonEmoji,
    required this.newMoonLabel,
    required this.daysToNewMoon,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: c.surfaceSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 44)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('🌙', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Text('Moon Phase',
                  style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 12)),
            ]),
            const SizedBox(height: 4),
            Text(name,
                style: GoogleFonts.dmSans(
                    color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('$illuminationPercent illuminated',
                style: GoogleFonts.dmSans(color: c.textMuted, fontSize: 12)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _moonCountdown(fullMoonEmoji, fullMoonLabel, daysToFullMoon, c),
          const SizedBox(height: 6),
          _moonCountdown(newMoonEmoji, newMoonLabel, daysToNewMoon, c),
        ]),
      ]),
    );
  }

  Widget _moonCountdown(String emoji, String label, int days, AppColors c) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 4),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(label,
            style: GoogleFonts.dmSans(
                color: c.textUltraFaint, fontSize: 9,
                fontWeight: FontWeight.w700, letterSpacing: 0.5)),
        Text(days == 0 ? 'Tonight' : 'in ${days}d',
            style: GoogleFonts.dmSans(
                color: c.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ]);
  }
}
