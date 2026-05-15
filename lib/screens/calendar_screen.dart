import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../models/weather_model.dart';
import '../models/note_model.dart';
import 'day_detail_screen.dart';
import 'weather_today_screen.dart';
import 'notes_screen.dart';
import '../services/weather_service.dart' show TempUnit, WeatherService;

class CalendarScreen extends StatefulWidget {
  final AppState state;
  const CalendarScreen({super.key, required this.state});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with WidgetsBindingObserver {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  int _currentTab = 1;

  // Computed live so it's always correct even after midnight
  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  AppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Called when the app comes back from background.
  // If the date has changed since the last fetch (e.g. left open overnight),
  // silently re-fetch so the user never sees yesterday's forecast.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.state.refreshIfStale();
    }
  }

  void _onDaySelected(DateTime selected, DateTime focused) {
    HapticFeedback.selectionClick();
    // Only update selection — navigation happens via the preview card tap below.
    // This way an accidental tap doesn't immediately open a new screen.
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(c),
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: [
                  _buildCalendarTab(c),
                  WeatherTodayScreen(state: state),
                  NotesScreen(state: state),
                ],
              ),
            ),
            _buildBottomNav(c),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
          child: Row(
            children: [
              Text(
                _currentTab == 0
                    ? 'Planner'
                    : _currentTab == 1
                        ? 'Today'
                        : 'Notes',
                style: GoogleFonts.dmSans(
                  color: c.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              ListenableBuilder(
                listenable: state,
                builder: (_, __) => IconButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    state.toggleTheme();
                  },
                  tooltip: state.isDark
                      ? 'Switch to light mode'
                      : 'Switch to dark mode',
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, anim) => RotationTransition(
                      turns: Tween(begin: 0.75, end: 1.0).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: Icon(
                      state.isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      key: ValueKey(state.isDark),
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ),
              ListenableBuilder(
                listenable: state,
                builder: (_, __) => GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    state.toggleTempUnit();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                      color: c.surfaceSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.border),
                    ),
                    child: Text(
                      state.useFahrenheit ? '°F' : '°C',
                      style: GoogleFonts.dmSans(
                        color: c.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              ListenableBuilder(
                listenable: state,
                builder: (_, __) => IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showSearchSheet();
                  },
                  icon: Icon(Icons.search_rounded, color: c.textSecondary),
                ),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  state.refreshWeather();
                },
                icon: Icon(Icons.refresh_rounded, color: c.textSecondary),
              ),
            ],
          ),
        ),
        // Location chips row — below the title/action row, full width scrollable
        ListenableBuilder(
          listenable: state,
          builder: (_, __) {
            if (state.locations.length <= 1) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  state.cityName.isNotEmpty
                      ? '${state.cityName}, ${state.countryName}'
                      : 'Locating...',
                  style: GoogleFonts.dmSans(color: c.textMuted, fontSize: 13),
                ),
              );
            }
            return SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                itemCount: state.locations.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final loc = state.locations[i];
                  final active = i == state.activeLocationIndex;
                  return GestureDetector(
                    onTap: () {
                      if (!active) HapticFeedback.selectionClick();
                      state.switchToLocation(i);
                    },
                    onLongPress: i > 0
                        ? () {
                            HapticFeedback.mediumImpact();
                            _confirmRemoveLocation(i);
                          }
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: active ? c.accentSurface : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active ? c.accentBorder : c.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (i == 0)
                            Padding(
                              padding: const EdgeInsets.only(right: 3),
                              child: Icon(Icons.my_location_rounded,
                                  size: 9,
                                  color:
                                      active ? AppColors.accent : c.textFaint),
                            ),
                          Text(
                            loc.cityName,
                            style: GoogleFonts.dmSans(
                              color: active ? AppColors.accent : c.textFaint,
                              fontSize: 11,
                              fontWeight:
                                  active ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          if (loc.loading)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: SizedBox(
                                width: 8,
                                height: 8,
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5, color: c.textFaint),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCalendarTab(AppColors c) {
    return ListenableBuilder(
      listenable: state,
      builder: (_, __) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildCalendar(c),
              const SizedBox(height: 12),
              _buildLaundryLegend(c),
              const SizedBox(height: 8),
              _buildSelectedDayPreview(c),
              const SizedBox(height: 16),
              _buildUpcomingNotes(c),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  /// Small legend explaining the green laundry highlight
  Widget _buildLaundryLegend(AppColors c) {
    // Only show if any laundry day exists in forecast
    final hasLaundryDay = state.forecast.any((d) => d.isGoodLaundryDay);
    if (!hasLaundryDay) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFF69F0AE).withOpacity(0.7),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '👕 Good day to do laundry outside',
            style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(AppColors c) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.border),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: _onDaySelected,
        onPageChanged: (focused) => setState(() => _focusedDay = focused),
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        rowHeight: 58,
        sixWeekMonthsEnforced: false,
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: GoogleFonts.dmSans(
            color: c.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: c.textMuted),
          rightChevronIcon: Icon(Icons.chevron_right, color: c.textMuted),
          headerPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.dmSans(
              color: c.textFaint, fontSize: 12, fontWeight: FontWeight.w500),
          weekendStyle: GoogleFonts.dmSans(
              color: c.textUltraFaint,
              fontSize: 12,
              fontWeight: FontWeight.w500),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          defaultTextStyle:
              GoogleFonts.dmSans(color: c.textSecondary, fontSize: 13),
          weekendTextStyle:
              GoogleFonts.dmSans(color: c.textMuted, fontSize: 13),
          selectedDecoration: const BoxDecoration(color: Colors.transparent),
          todayDecoration: const BoxDecoration(color: Colors.transparent),
          todayTextStyle: GoogleFonts.dmSans(color: c.textPrimary),
          selectedTextStyle: GoogleFonts.dmSans(color: c.textPrimary),
          cellMargin: const EdgeInsets.all(4),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (ctx, day, _) =>
              _dayCell(day, isSelected: false, isToday: false, c: c),
          todayBuilder: (ctx, day, _) =>
              _dayCell(day, isSelected: false, isToday: true, c: c),
          selectedBuilder: (ctx, day, _) =>
              _dayCell(day, isSelected: true, isToday: false, c: c),
          outsideBuilder: (ctx, day, _) => const SizedBox(),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05);
  }

  Widget _dayCell(DateTime day,
      {required bool isSelected, required bool isToday, required AppColors c}) {
    final weather = state.weatherForDate(day);
    final note = state.noteForDate(day);
    final isPast = day.isBefore(_today);
    final isLaundryDay = weather != null && weather.isGoodLaundryDay && !isPast;

    // Laundry highlight color — soft green, dimmed for non-selected
    final laundryBg = isLaundryDay && !isSelected
        ? (c.isDark
            ? const Color(0xFF69F0AE).withOpacity(0.12)
            : const Color(0xFF2E7D32).withOpacity(0.08))
        : Colors.transparent;

    final laundryBorder = isLaundryDay && !isSelected
        ? (c.isDark
            ? const Color(0xFF69F0AE).withOpacity(0.30)
            : const Color(0xFF2E7D32).withOpacity(0.25))
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.all(5),
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.accent
            : isToday
                ? c.calendarTodayBg
                : laundryBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected || isToday ? Colors.transparent : laundryBorder,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: GoogleFonts.dmSans(
              color: isSelected
                  ? Colors.white
                  : isToday
                      ? c.dayNumberToday
                      : isPast
                          ? c.dayNumberPast
                          : c.dayNumberDefault,
              fontSize: 13,
              fontWeight:
                  isSelected || isToday ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          if (weather != null)
            Text(weather.emoji, style: TextStyle(fontSize: isPast ? 8 : 10))
          else if (note != null)
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(top: 1),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(height: 6),
          // Tiny camera dot if note has photo
          if (note != null && note.hasImage)
            Container(
              margin: const EdgeInsets.only(top: 1),
              child: Icon(Icons.camera_alt_rounded,
                  size: 7,
                  color: isSelected
                      ? Colors.white.withOpacity(0.8)
                      : c.textUltraFaint),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayPreview(AppColors c) {
    final weather = state.weatherForDate(_selectedDay);
    final note = state.noteForDate(_selectedDay);
    final isToday = isSameDay(_selectedDay, _today);
    final isFuture = _selectedDay.isAfter(_today);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DayDetailScreen(date: _selectedDay, state: state),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'Today' : DateFormat('EEEE').format(_selectedDay),
                  style: GoogleFonts.dmSans(
                    color: c.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  DateFormat('d MMMM yyyy').format(_selectedDay),
                  style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 13),
                ),
                // Laundry badge on selected day preview
                if (weather != null &&
                    weather.isGoodLaundryDay &&
                    !_selectedDay.isBefore(_today))
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF69F0AE).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF69F0AE).withOpacity(0.4)),
                    ),
                    child: Text(
                      '👕 Great laundry day',
                      style: GoogleFonts.dmSans(
                          color: const Color(0xFF69F0AE), fontSize: 11),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            if (weather != null) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(weather.emoji, style: const TextStyle(fontSize: 28)),
                  Text(
                    '${TempUnit.format(weather.tempMax, state.useFahrenheit)} / ${TempUnit.format(weather.tempMin, state.useFahrenheit)}',
                    style: GoogleFonts.dmSans(color: c.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ] else if (isFuture) ...[
              Text('🔮',
                  style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 22)),
            ],
            const SizedBox(width: 8),
            if (note != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.accentSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.accentBorder),
                    ),
                    child: Text(
                      '${note.category.emoji} Note',
                      style: GoogleFonts.dmSans(
                          color: AppColors.accent, fontSize: 12),
                    ),
                  ),
                  if (note.hasImage) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: c.surfaceSubtle,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.border),
                      ),
                      child: Icon(Icons.camera_alt_rounded,
                          size: 12, color: c.textMuted),
                    ),
                  ],
                ],
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: c.surfaceSubtle,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '+ Add note',
                  style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _upcomingExpanded = false;

  Widget _buildUpcomingNotes(AppColors c) {
    final upcoming = state.notes.values
        .where((n) => !n.date.isBefore(_today))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (upcoming.isEmpty) return const SizedBox();

    const collapsedCount = 5;
    final showAll = _upcomingExpanded || upcoming.length <= collapsedCount;
    final visible = showAll ? upcoming : upcoming.take(collapsedCount).toList();
    final hidden = upcoming.length - collapsedCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Text(
                'UPCOMING PLANS',
                style: GoogleFonts.dmSans(
                  color: c.textUltraFaint,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '${upcoming.length} plan${upcoming.length == 1 ? '' : 's'}',
                style:
                    GoogleFonts.dmSans(color: c.textUltraFaint, fontSize: 11),
              ),
            ],
          ),
        ),
        ...visible.map((note) {
          final weather = state.weatherForDate(note.date);
          return _upcomingNoteRow(note, weather, c);
        }),
        if (upcoming.length > collapsedCount)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _upcomingExpanded = !_upcomingExpanded);
            },
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: c.surfaceSubtle,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border),
              ),
              child: Center(
                child: Text(
                  _upcomingExpanded
                      ? 'Show less'
                      : 'Show $hidden more plan${hidden == 1 ? '' : 's'}',
                  style: GoogleFonts.dmSans(
                    color: c.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _upcomingNoteRow(DayNote note, DayWeather? weather, AppColors c) {
    final isToday = isSameDay(note.date, _today);
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
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: weather != null && weather.isBadWeather
                ? c.badWeatherBorder
                : c.border,
          ),
        ),
        child: Row(
          children: [
            // Date badge — always visible
            Container(
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isToday ? c.accentSurface : c.surfaceSubtle,
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
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            // Thumbnail — only shown if image exists
            if (note.hasImage &&
                note.imagePath != null &&
                File(note.imagePath!).existsSync()) ...[
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  File(note.imagePath!),
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(note.category.emoji,
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(note.category.label,
                          style: GoogleFonts.dmSans(
                              color: c.textFaint, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    note.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                        color: c.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (weather != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(weather.emoji, style: const TextStyle(fontSize: 18)),
                  Text(TempUnit.format(weather.tempMax, state.useFahrenheit),
                      style:
                          GoogleFonts.dmSans(color: c.textMuted, fontSize: 12)),
                ],
              )
            else
              const Text('🔮', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  // ── Search sheet — with add-location mode ─────────────

  void _showSearchSheet() {
    final c = AppColors.of(context);
    final canAddMore = state.locations.length < 5;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LocationSearchSheet(
        state: state,
        canAddLocation: canAddMore,
        onSetPrimary: (lat, lon, city, country) {
          state.setLocation(lat, lon, city, country);
          Navigator.pop(context);
        },
        onAddLocation: (lat, lon, city, country) {
          state.addLocation(lat, lon, city, country);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _confirmRemoveLocation(int index) {
    final c = AppColors.of(context);
    final loc = state.locations[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Remove location?',
            style: GoogleFonts.dmSans(
                color: c.textPrimary, fontWeight: FontWeight.w600)),
        content: Text('Remove ${loc.cityName} from your saved locations.',
            style: GoogleFonts.dmSans(color: c.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: GoogleFonts.dmSans(color: c.textMuted)),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx);
              state.removeLocation(index);
            },
            child: Text('Remove',
                style: GoogleFonts.dmSans(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(AppColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.calendar_month_rounded, 'Calendar', c),
          _navItem(1, Icons.wb_sunny_rounded, 'Weather', c),
          _navItem(2, Icons.book_rounded, 'Notes', c),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, AppColors c) {
    final active = _currentTab == index;
    return GestureDetector(
      onTap: () {
        if (!active) HapticFeedback.selectionClick();
        setState(() => _currentTab = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: active ? c.accentSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: active ? AppColors.accent : c.textUltraFaint, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: active ? AppColors.accent : c.textUltraFaint,
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Location Search Sheet ─────────────────────────────────────────────────────
// Replaces SearchSheet — supports both "set primary" and "add location" modes.

class _LocationSearchSheet extends StatefulWidget {
  final AppState state;
  final bool canAddLocation;
  final void Function(double, double, String, String) onSetPrimary;
  final void Function(double, double, String, String) onAddLocation;

  const _LocationSearchSheet({
    required this.state,
    required this.canAddLocation,
    required this.onSetPrimary,
    required this.onAddLocation,
  });

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final WeatherService _service = WeatherService();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  // null = not chosen yet, true = add, false = set primary
  bool? _addMode;

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

  void _onSelectResult(Map<String, dynamic> r) {
    final name = r['name'] ?? '';
    final country = r['country'] ?? '';
    final lat = (r['latitude'] as num).toDouble();
    final lon = (r['longitude'] as num).toDouble();

    final hasMultiple = widget.state.locations.length > 1;

    if (!hasMultiple && !widget.canAddLocation) {
      // Only one slot possible — just set primary
      widget.onSetPrimary(lat, lon, name, country);
      return;
    }

    if (!widget.canAddLocation) {
      widget.onSetPrimary(lat, lon, name, country);
      return;
    }

    // Ask user: set as primary or add as saved location
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
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('$name, $country',
                style: GoogleFonts.dmSans(
                    color: c.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('What would you like to do?',
                style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 13)),
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
                  Text(title,
                      style: GoogleFonts.dmSans(
                          color: c.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  Text(subtitle,
                      style:
                          GoogleFonts.dmSans(color: c.textFaint, fontSize: 12)),
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
                Text('Search City',
                    style: GoogleFonts.dmSans(
                        color: c.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
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
                        title: Text(name,
                            style: GoogleFonts.dmSans(
                                color: c.textPrimary, fontSize: 15)),
                        subtitle: Text('$admin, $country',
                            style: GoogleFonts.dmSans(
                                color: c.textFaint, fontSize: 12)),
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
