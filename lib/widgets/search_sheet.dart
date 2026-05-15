import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_state.dart';
import '../services/weather_service.dart';
import '../theme/app_theme.dart';

class SearchSheet extends StatefulWidget {
  final AppState state;
  const SearchSheet({super.key, required this.state});

  @override
  State<SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<SearchSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final WeatherService _service = WeatherService();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;

  Future<void> _onSearch(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    final results = await _service.searchCity(q);
    setState(() {
      _results = results;
      _searching = false;
    });
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
            child: Text(
              'Search City',
              style: GoogleFonts.dmSans(
                  color: c.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
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
                  hintStyle: GoogleFonts.dmSans(color: c.textUltraFaint, fontSize: 14),
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
                                strokeWidth: 2, color: c.textFaint),
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
                      style: GoogleFonts.dmSans(color: c.textUltraFaint, fontSize: 14),
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
                      final lat = (r['latitude'] as num).toDouble();
                      final lon = (r['longitude'] as num).toDouble();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.location_on_outlined,
                            color: AppColors.accent, size: 20),
                        title: Text(name,
                            style: GoogleFonts.dmSans(
                                color: c.textPrimary, fontSize: 15)),
                        subtitle: Text('$admin, $country',
                            style: GoogleFonts.dmSans(
                                color: c.textFaint, fontSize: 12)),
                        onTap: () {
                          widget.state.setLocation(lat, lon, name, country);
                          Navigator.pop(context);
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