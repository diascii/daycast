import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../models/widget_theme.dart';

class SettingsSheet extends StatelessWidget {
  final AppState state;

  const SettingsSheet({super.key, required this.state});

  static void show(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsSheet(state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = state.isDark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: c.textUltraFaint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Settings',
            style: GoogleFonts.dmSans(
              color: c.textPrimary,
              fontSize: 22, // Elegant smaller size
              fontWeight: FontWeight.w600, // Refined weight
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 24),
          _buildSettingTile(
            context,
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            title: 'Dark Mode',
            subtitle: 'Toggle application theme',
            trailing: Switch(
              value: state.isDark,
              onChanged: (_) => state.toggleTheme(),
              activeThumbColor: const Color(0xFF4f6ef7),
            ),
          ),
          const Divider(height: 24, color: Colors.white10),
          _buildSettingTile(
            context,
            icon: Icons.thermostat_rounded,
            title: 'Temperature Unit',
            subtitle: 'Choose your preferred unit',
            trailing: Container(
              decoration: BoxDecoration(
                color: c.surfaceSubtle,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTempOption(context, '°C', !state.useFahrenheit),
                  _buildTempOption(context, '°F', state.useFahrenheit),
                ],
              ),
            ),
          ),
          const Divider(height: 24, color: Colors.white10),
          _buildSettingTile(
            context,
            icon: Icons.local_laundry_service_rounded,
            title: 'Laundry Outside',
            subtitle: 'Suggest drying days',
            trailing: Switch(
              value: state.isLaundryEnabled,
              onChanged: (_) => state.toggleLaundry(),
              activeThumbColor: const Color(0xFF4f6ef7),
            ),
          ),
          const Divider(height: 24, color: Colors.white10),
          _buildSettingTile(
            context,
            icon: Icons.notifications_active_rounded,
            title: 'Daily Summary',
            subtitle: 'Outlook for tomorrow',
            trailing: Switch(
              value: state.isDailySummaryEnabled,
              onChanged: (_) => state.toggleDailySummary(),
              activeThumbColor: const Color(0xFF4f6ef7),
            ),
          ),
          if (state.isDailySummaryEnabled)
            Padding(
              padding: const EdgeInsets.only(left: 68, top: 4),
              child: GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: state.dailySummaryTime,
                  );
                  if (picked != null) {
                    state.setDailySummaryTime(picked);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: c.surfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 14, color: c.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        state.dailySummaryTime.format(context),
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const Divider(height: 24, color: Colors.white10),
          _buildSettingTile(
            context,
            icon: Icons.palette_rounded,
            title: 'Widget Theme',
            subtitle: 'Glass background style',
            trailing: const SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 68, top: 8),
            child: Row(
              children: List.generate(WidgetTheme.themes.length, (i) {
                final theme = WidgetTheme.themes[i];
                final isSelected = state.widgetThemeIndex == i;
                return GestureDetector(
                  onTap: () => state.setWidgetTheme(i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.accentColor,
                          child: isSelected
                              ? const Icon(Icons.check, size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          theme.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: isSelected ? c.textPrimary : c.textFaint,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Daycast v1.0.0',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: c.textFaint,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildTempOption(BuildContext context, String label, bool active) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: () {
        if (!active) state.toggleTempUnit();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF4f6ef7) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            color: active ? Colors.white : c.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: c.accentSurface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.accent, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: c.textFaint,
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}
