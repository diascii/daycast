import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'day_detail_screen.dart';

class NotesScreen extends StatefulWidget {
  final AppState state;
  const NotesScreen({super.key, required this.state});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  NoteCategory? _activeFilter; // null = show all

  AppState get state => widget.state;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // ── Filtered + sorted notes ───────────────────────────

  List<DayNote> get _allFiltered {
    var notes = state.notes.values.toList();

    // Category filter
    if (_activeFilter != null) {
      notes = notes.where((n) => n.category == _activeFilter).toList();
    }

    // Search filter — content + date string
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      notes = notes.where((n) {
        final contentMatch = n.content.toLowerCase().contains(q);
        final dateMatch = DateFormat('MMMM yyyy d EEEE')
            .format(n.date)
            .toLowerCase()
            .contains(q);
        return contentMatch || dateMatch;
      }).toList();
    }

    return notes;
  }

  List<DayNote> get _upcoming =>
      _allFiltered.where((n) => !n.date.isBefore(_today)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  List<DayNote> get _past =>
      _allFiltered.where((n) => n.date.isBefore(_today)).toList()
        ..sort((a, b) => b.date.compareTo(a.date)); // newest past first

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (_, __) {
        final upcoming = _upcoming;
        final past = _past;
        final total = state.notes.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Search bar ──
            _buildSearchBar(c),
            // ── Category filter chips ──
            _buildFilterChips(c),
            // ── Notes list ──
            Expanded(
              child: total == 0
                  ? _buildEmptyState(c, isEmpty: true)
                  : (upcoming.isEmpty && past.isEmpty)
                      ? _buildEmptyState(c, isEmpty: false)
                      : ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 80),
                          children: [
                            if (upcoming.isNotEmpty) ...[
                              _sectionHeader('UPCOMING', upcoming.length, c),
                              ...upcoming.map((n) => _noteCard(n, c)),
                            ],
                            if (past.isNotEmpty) ...[
                              _sectionHeader('PAST & JOURNAL', past.length, c),
                              ...past.map((n) => _noteCard(n, c)),
                            ],
                          ],
                        ),
            ),
          ],
        );
      },
    );
  }

  // ── Search bar ────────────────────────────────────────

  Widget _buildSearchBar(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceSubtle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: TextField(
          controller: _searchCtrl,
          style: GoogleFonts.dmSans(color: c.textPrimary, fontSize: 14),
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search notes, dates...',
            hintStyle:
                GoogleFonts.dmSans(color: c.textUltraFaint, fontSize: 14),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            prefixIcon:
                Icon(Icons.search_rounded, color: c.textFaint, size: 20),
            suffixIcon: _query.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                    child:
                        Icon(Icons.close_rounded, color: c.textFaint, size: 18),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  // ── Category filter chips ─────────────────────────────

  Widget _buildFilterChips(AppColors c) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        children: [
          // "All" chip
          _filterChip(null, 'All', '🗂️', c),
          const SizedBox(width: 8),
          ...NoteCategory.values.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _filterChip(cat, cat.label, cat.emoji, c),
              )),
        ],
      ),
    );
  }

  Widget _filterChip(
      NoteCategory? cat, String label, String emoji, AppColors c) {
    final active = _activeFilter == cat;
    return GestureDetector(
      onTap: () {
        if (!active) HapticFeedback.selectionClick();
        setState(() => _activeFilter = cat);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? c.accentSurface : c.surfaceSubtle,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? c.accentBorder : c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: active ? AppColors.accent : c.textFaint,
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section header ────────────────────────────────────

  Widget _sectionHeader(String title, int count, AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              color: c.textUltraFaint,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: c.surfaceSubtle,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.dmSans(
                  color: c.textFaint,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Note card ─────────────────────────────────────────

  Widget _noteCard(DayNote note, AppColors c) {
    final weather = state.weatherForDate(note.date);
    final isPast = note.date.isBefore(_today);
    final isToday = note.date.year == _today.year &&
        note.date.month == _today.month &&
        note.date.day == _today.day;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DayDetailScreen(date: note.date, state: state),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: weather != null && weather.isBadWeather && !isPast
                ? c.badWeatherBorder
                : c.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image — full width if present
            if (note.hasImage && note.imagePath != null)
              _buildCardImage(note.imagePath!, c),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date badge
                  Container(
                    width: 46,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isToday
                          ? c.accentSurface
                          : isPast
                              ? c.surfaceSubtle
                              : c.surfaceSubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('MMM').format(note.date).toUpperCase(),
                          style: GoogleFonts.dmSans(
                            color: isToday ? AppColors.accent : c.textFaint,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${note.date.day}',
                          style: GoogleFonts.dmSans(
                            color: isToday ? AppColors.accent : c.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          DateFormat('EEE').format(note.date),
                          style: GoogleFonts.dmSans(
                            color:
                                isToday ? AppColors.accent : c.textUltraFaint,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category + weather row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: c.surfaceSubtle,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(note.category.emoji,
                                      style: const TextStyle(fontSize: 11)),
                                  const SizedBox(width: 4),
                                  Text(note.category.label,
                                      style: GoogleFonts.dmSans(
                                          color: c.textFaint, fontSize: 11)),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (weather != null) ...[
                              Text(weather.emoji,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 4),
                              Text(
                                '${weather.tempMax.round()}°',
                                style: GoogleFonts.dmSans(
                                    color: c.textMuted, fontSize: 12),
                              ),
                            ] else if (!isPast)
                              const Text('🔮', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Note content — show up to 3 lines
                        Text(
                          note.content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            color: isPast ? c.textMuted : c.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Footer: updated time + weather warning
                        Row(
                          children: [
                            Text(
                              _timeAgo(note.updatedAt),
                              style: GoogleFonts.dmSans(
                                  color: c.textUltraFaint, fontSize: 11),
                            ),
                            if (weather != null &&
                                weather.isBadWeather &&
                                !isPast) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: c.badWeatherSurface,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '⚠️ Bad weather',
                                  style: GoogleFonts.dmSans(
                                      color: Colors.orange, fontSize: 10),
                                ),
                              ),
                            ],
                            if (note.hasImage) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.camera_alt_rounded,
                                  size: 11, color: c.textUltraFaint),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildCardImage(String path, AppColors c) {
    final file = File(path);
    if (!file.existsSync()) return const SizedBox();
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      child: Image.file(
        file,
        width: double.infinity,
        height: 160,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(),
      ),
    );
  }

  // ── Empty states ──────────────────────────────────────

  Widget _buildEmptyState(AppColors c, {required bool isEmpty}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            isEmpty ? '📝' : '🔍',
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            isEmpty ? 'No notes yet' : 'No results found',
            style: GoogleFonts.dmSans(
              color: c.textMuted,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEmpty
                ? 'Tap any day on the calendar\nto add your first note'
                : 'Try a different search or filter',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return DateFormat('d MMM yyyy').format(dt);
  }
}
