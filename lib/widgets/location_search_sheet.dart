import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/app_state.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';

class LocationSearchSheet extends StatefulWidget {
  final AppState state;
  final bool canAddLocation;
  final void Function(double, double, String, String) onSetPrimary;
  final void Function(double, double, String, String) onAddLocation;

  const LocationSearchSheet({
    super.key,
    required this.state,
    required this.canAddLocation,
    required this.onSetPrimary,
    required this.onAddLocation,
  });

  @override
  State<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<LocationSearchSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final WeatherService _service = WeatherService();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onSearch(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    final results = await _service.searchCity(q);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  void _onSelectResult(Map<String, dynamic> r) {
    final name = r['name'] ?? '';
    final country = r['country'] ?? '';
    final lat = (r['latitude'] as num).toDouble();
    final lon = (r['longitude'] as num).toDouble();

    if (!widget.canAddLocation) {
      widget.onSetPrimary(lat, lon, name, country);
      return;
    }

    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
        decoration: BoxDecoration(
          color: c.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.textUltraFaint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              '$name, $country',
              style: GoogleFonts.dmSans(
                color: c.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'What would you like to do?',
              style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _actionTile(
              icon: Icons.my_location_rounded,
              title: 'Set as my location',
              subtitle: 'Replaces your current primary location',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                widget.onSetPrimary(lat, lon, name, country);
              },
              c: c,
            ),
            const SizedBox(height: 10),
            _actionTile(
              icon: Icons.add_location_alt_rounded,
              title: 'Add as saved location',
              subtitle: 'View its forecast alongside your primary',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                widget.onAddLocation(lat, lon, name, country);
              },
              c: c,
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required AppColors c,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surfaceSubtle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: c.accentSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      color: c.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: c.textUltraFaint),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.textUltraFaint,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Search City',
                  style: GoogleFonts.dmSans(
                    color: c.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (widget.canAddLocation && widget.state.locations.length > 1)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.accentSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.accentBorder),
                    ),
                    child: Text(
                      '${widget.state.locations.length}/5 locations',
                      style: GoogleFonts.dmSans(
                          color: AppColors.accent, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: c.surfaceSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border),
              ),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                style: GoogleFonts.dmSans(color: c.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. Tokyo, Paris, New York...',
                  hintStyle:
                      GoogleFonts.dmSans(color: c.textUltraFaint, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  prefixIcon: _searching
                      ? Padding(
                          padding: const EdgeInsets.all(14),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.textFaint,
                            ),
                          ),
                        )
                      : Icon(Icons.search_rounded, color: c.textFaint),
                ),
                onChanged: _onSearch,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(
                      _ctrl.text.isEmpty
                          ? 'Start typing to search'
                          : 'No results found',
                      style: GoogleFonts.dmSans(
                          color: c.textUltraFaint, fontSize: 14),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _results.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: c.divider, height: 1),
                    itemBuilder: (ctx, i) {
                      final r = _results[i];
                      final name = r['name'] ?? '';
                      final admin = r['admin1'] ?? '';
                      final country = r['country'] ?? '';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.location_on_outlined,
                            color: AppColors.accent, size: 20),
                        title: Text(
                          name,
                          style: GoogleFonts.dmSans(
                              color: c.textPrimary, fontSize: 15),
                        ),
                        subtitle: Text(
                          '$admin, $country',
                          style: GoogleFonts.dmSans(
                              color: c.textFaint, fontSize: 12),
                        ),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _onSelectResult(r);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
