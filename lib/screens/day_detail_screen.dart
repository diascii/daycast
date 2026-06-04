import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/note_model.dart';
import '../models/weather_model.dart';
import '../services/app_state.dart';
import '../services/note_image_service.dart';
import '../theme/app_theme.dart';

class DayDetailScreen extends StatefulWidget {
  final DateTime date;
  final AppState state;

  const DayDetailScreen({super.key, required this.date, required this.state});

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  final NoteImageService _imageService = NoteImageService();
  late TextEditingController _noteController;
  NoteCategory _selectedCategory = NoteCategory.plan;
  bool _editing = false;
  bool _saving = false;

  // Image state
  String? _pendingImagePath; // path chosen during edit, not yet saved
  bool _clearImage = false; // user pressed ✕ on existing image

  late final DateTime _now = DateTime.now();
  late final DateTime _today = DateTime(_now.year, _now.month, _now.day);

  AppState get state => widget.state;
  DateTime get date => widget.date;

  DayWeather? get weather => state.weatherForDate(date);
  DayNote? get existingNote => state.noteForDate(date);

  bool get isToday =>
      date.year == _today.year &&
      date.month == _today.month &&
      date.day == _today.day;

  bool get isPast => date.isBefore(_today);
  bool get isFuture => date.isAfter(_today);

  /// The image path to display: pending pick > existing saved > null
  String? get _displayImagePath {
    if (_clearImage) return null;
    if (_pendingImagePath != null) return _pendingImagePath;
    return existingNote?.imagePath;
  }

  @override
  void initState() {
    super.initState();
    final note = existingNote;
    _noteController = TextEditingController(text: note?.content ?? '');
    if (note != null) _selectedCategory = note.category;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ── Image picking ─────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final persistedPath = await _imageService.pickAndPersist(source);
    if (persistedPath == null) return;

    setState(() {
      _pendingImagePath = persistedPath;
      _clearImage = false;
    });
  }

  void _showImageSourceSheet() {
    HapticFeedback.lightImpact();
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
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: c.textUltraFaint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _sourceOption(
              icon: Icons.photo_library_rounded,
              label: 'Choose from Gallery',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
              c: c,
            ),
            const SizedBox(height: 10),
            _sourceOption(
              icon: Icons.camera_alt_rounded,
              label: 'Take a Photo',
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
              c: c,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required AppColors c,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: c.surfaceSubtle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 22),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.dmSans(
                    color: c.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // ── Fullscreen image viewer ───────────────────────────────────────────────

  void _openFullscreen(String imagePath) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenImageViewer(imagePath: imagePath),
      ),
    );
  }

  // ── Save / delete ─────────────────────────────────────────────────────────

  Future<void> _saveNote() async {
    if (_noteController.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final existing = existingNote;

    // If user cleared the image, delete the old file
    if (_clearImage && existing?.imagePath != null) {
      await _imageService.deleteIfPresent(existing!.imagePath);
    }

    final note = DayNote(
      id: existing?.id ?? const Uuid().v4(),
      date: date,
      content: _noteController.text.trim(),
      category: _selectedCategory,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      imagePath:
          _clearImage ? null : (_pendingImagePath ?? existing?.imagePath),
    );

    await state.saveNote(note);
    HapticFeedback.lightImpact();
    setState(() {
      _saving = false;
      _editing = false;
      _pendingImagePath = null;
      _clearImage = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Note saved! ✓',
              style: GoogleFonts.dmSans(color: Colors.white)),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteNote() async {
    final c = AppColors.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete note?',
            style: GoogleFonts.dmSans(
                color: c.textPrimary, fontWeight: FontWeight.w600)),
        content: Text('This note will be permanently deleted.',
            style: GoogleFonts.dmSans(color: c.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text('Cancel', style: GoogleFonts.dmSans(color: c.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete',
                style: GoogleFonts.dmSans(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      HapticFeedback.mediumImpact();
      if (existingNote?.imagePath != null) {
        await _imageService.deleteIfPresent(existingNote!.imagePath);
      }
      await state.deleteNote(date);
      _noteController.clear();
      setState(() {
        _pendingImagePath = null;
        _clearImage = false;
      });
    }
  }

  // ── Background gradient ───────────────────────────────────────────────────

  LinearGradient _bgGradient(bool isDark) {
    final code = weather?.weatherCode;
    if (isDark) {
      if (code == null) {
        return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0d0d14), Color(0xFF16162a)]);
      }
      if (code == 0 || code == 1) {
        return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0d1b3e), Color(0xFF0d0d14)]);
      }
      if (code >= 61 && code <= 82) {
        return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0d1b2a), Color(0xFF0d0d14)]);
      }
      if (code >= 71 && code <= 77) {
        return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a2030), Color(0xFF0d0d14)]);
      }
      if (code >= 95) {
        return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a0d2e), Color(0xFF0d0d14)]);
      }
      return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16162a), Color(0xFF0d0d14)]);
    } else {
      if (code == null) {
        return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFf0f2f8), Color(0xFFe8ecf4)]);
      }
      if (code == 0 || code == 1) {
        return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFd8eeff), Color(0xFFf0f2f8)]);
      }
      if (code >= 61 && code <= 82) {
        return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFcfdaea), Color(0xFFf0f2f8)]);
      }
      if (code >= 71 && code <= 77) {
        return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFdde4f4), Color(0xFFf0f2f8)]);
      }
      if (code >= 95) {
        return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFd0d4e8), Color(0xFFf0f2f8)]);
      }
      return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFe4e8f4), Color(0xFFf0f2f8)]);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ListenableBuilder(
      listenable: state,
      builder: (_, __) {
        return Scaffold(
          backgroundColor: c.scaffoldBg,
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            decoration: BoxDecoration(gradient: _bgGradient(c.isDark)),
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(c),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _buildDateHeader(c),
                          const SizedBox(height: 20),
                          if (weather != null) ...[
                            _buildWeatherCard(c),
                            const SizedBox(height: 20),
                            _buildPeakLowCards(c),
                            const SizedBox(height: 20),
                            if (weather!.hourly.isNotEmpty) ...[
                              _buildHourlyChart(c),
                              const SizedBox(height: 20),
                            ],
                            _buildWeatherDetails(c),
                            const SizedBox(height: 24),
                          ] else if (isFuture) ...[
                            _buildNoForecastCard(c),
                            const SizedBox(height: 24),
                          ],
                          _buildNoteSection(c),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(AppColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: c.textSecondary, size: 20),
          ),
          const Spacer(),
          if (existingNote != null) ...[
            IconButton(
              onPressed: () => setState(() {
                HapticFeedback.selectionClick();
                _editing = !_editing;
                if (!_editing) {
                  // Cancel edit — discard pending image changes
                  _pendingImagePath = null;
                  _clearImage = false;
                }
              }),
              icon: Icon(
                _editing ? Icons.close_rounded : Icons.edit_rounded,
                color: c.textMuted,
                size: 20,
              ),
            ),
            IconButton(
              onPressed: _deleteNote,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateHeader(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isToday ? 'Today' : DateFormat('EEEE').format(date),
          style: GoogleFonts.dmSans(
            color: c.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        Text(
          DateFormat('d MMMM yyyy').format(date),
          style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 15),
        ),
        if (isPast)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: c.surfaceSubtle,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Past date',
                style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 12)),
          ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.05);
  }

  Widget _buildWeatherCard(AppColors c) {
    final w = weather!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surfaceSubtle,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: w.isBadWeather ? c.badWeatherBorder : c.border,
          width: w.isBadWeather ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(w.emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.description,
                    style: GoogleFonts.dmSans(
                        color: c.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('${w.tempMax.round()}°',
                        style: GoogleFonts.dmSans(
                            color: c.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w300)),
                    const SizedBox(width: 6),
                    Text('/ ${w.tempMin.round()}°',
                        style: GoogleFonts.dmSans(
                            color: c.textFaint,
                            fontSize: 18,
                            fontWeight: FontWeight.w300)),
                  ],
                ),
                if (w.isBadWeather)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: c.badWeatherSurface,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('⚠️ Bad weather expected',
                        style: GoogleFonts.dmSans(
                            color: Colors.orange, fontSize: 12)),
                  )
                else if (w.isGoodWeather)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: c.goodWeatherSurface,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text('✓ Great weather!',
                        style: GoogleFonts.dmSans(
                            color: Colors.green, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  Widget _buildPeakLowCards(AppColors c) {
    final w = weather!;
    final peakTemp = w.peakTempHour;
    final lowTemp = w.lowestTempHour;
    final peakUv = w.peakUvHour;
    final lowUv = w.lowestUvHour;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PEAK & LOW',
            style: GoogleFonts.dmSans(
                color: c.textUltraFaint,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _peakLowCard(c, '🌡️', 'Temperature',
                  peakVal: peakTemp != null
                      ? '${peakTemp.temperature.round()}°'
                      : '${w.tempMax.round()}°',
                  peakTime: peakTemp != null
                      ? DateFormat('h a').format(peakTemp.time)
                      : null,
                  lowVal: lowTemp != null
                      ? '${lowTemp.temperature.round()}°'
                      : '${w.tempMin.round()}°',
                  lowTime: lowTemp != null
                      ? DateFormat('h a').format(lowTemp.time)
                      : null),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _peakLowCard(c, '☀️', 'UV Index',
                  peakVal: peakUv != null
                      ? peakUv.uvIndex.round().toString()
                      : w.uvIndexMax.round().toString(),
                  peakTime: peakUv != null
                      ? DateFormat('h a').format(peakUv.time)
                      : null,
                  lowVal:
                      lowUv != null ? lowUv.uvIndex.round().toString() : '0',
                  lowTime: lowUv != null
                      ? DateFormat('h a').format(lowUv.time)
                      : null),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 120.ms);
  }

  Widget _peakLowCard(AppColors c, String emoji, String label,
      {required String peakVal,
      String? peakTime,
      required String lowVal,
      String? lowTime}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceSubtle,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 12)),
          ]),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PEAK',
                      style: GoogleFonts.dmSans(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  Text(peakVal,
                      style: GoogleFonts.dmSans(
                          color: c.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w600)),
                  if (peakTime != null)
                    Text(peakTime,
                        style: GoogleFonts.dmSans(
                            color: c.textFaint, fontSize: 11)),
                ],
              ),
              Container(width: 1, height: 36, color: c.border),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('LOW',
                      style: GoogleFonts.dmSans(
                          color: const Color(0xFF64b5f6),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  Text(lowVal,
                      style: GoogleFonts.dmSans(
                          color: c.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w600)),
                  if (lowTime != null)
                    Text(lowTime,
                        style: GoogleFonts.dmSans(
                            color: c.textFaint, fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyChart(AppColors c) {
    final w = weather!;
    final hourly = w.hourly;
    if (hourly.isEmpty) return const SizedBox();

    final filtered = <HourlyWeather>[];
    for (int i = 0; i < hourly.length; i++) {
      if (hourly[i].time.hour % 3 == 0) filtered.add(hourly[i]);
    }

    final temps = filtered.map((h) => h.temperature).toList();
    final maxTemp = temps.reduce((a, b) => a > b ? a : b);
    final minTemp = temps.reduce((a, b) => a < b ? a : b);
    final range = (maxTemp - minTemp).clamp(1.0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HOURLY TEMPERATURE',
            style: GoogleFonts.dmSans(
                color: c.textUltraFaint,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          decoration: BoxDecoration(
            color: c.surfaceSubtle,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: filtered.asMap().entries.map((entry) {
                    final h = entry.value;
                    final normalised =
                        ((h.temperature - minTemp) / range).clamp(0.15, 1.0);
                    final isPeak = h == w.peakTempHour;
                    final isLow = h == w.lowestTempHour;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${h.temperature.round()}°',
                              style: GoogleFonts.dmSans(
                                color: isPeak
                                    ? Colors.orange
                                    : isLow
                                        ? const Color(0xFF64b5f6)
                                        : c.textMuted,
                                fontSize: 9,
                                fontWeight: isPeak || isLow
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 3),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 600),
                              height: 70 * normalised,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: isPeak
                                      ? [
                                          Colors.orange,
                                          Colors.orange.withValues(alpha: 0.4)
                                        ]
                                      : isLow
                                          ? [
                                              const Color(0xFF64b5f6),
                                              const Color(0xFF64b5f6)
                                                  .withValues(alpha: 0.4)
                                            ]
                                          : [
                                              AppColors.accent,
                                              AppColors.accent
                                                  .withValues(alpha: 0.3)
                                            ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: filtered.map((h) {
                  return Expanded(
                    child: Column(
                      children: [
                        Text(h.emoji, style: const TextStyle(fontSize: 10)),
                        Text(
                          DateFormat('ha').format(h.time).toLowerCase(),
                          style: GoogleFonts.dmSans(
                              color: c.textUltraFaint, fontSize: 9),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 140.ms);
  }

  Widget _buildWeatherDetails(AppColors c) {
    final w = weather!;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.2,
      children: [
        _detailTile('🌧️', 'Rain', '${w.precipitationSum.round()}mm', c),
        _detailTile('💨', 'Wind', '${w.windSpeedMax.round()} km/h', c),
        _detailTile('🌡️', 'UV', '${w.uvIndexMax.round()}', c),
        _detailTile('🌅', 'Sunrise', DateFormat('h:mm a').format(w.sunrise), c),
        _detailTile('🌇', 'Sunset', DateFormat('h:mm a').format(w.sunset), c),
        _detailTile('📅', 'Day', DateFormat('EEE').format(w.date), c),
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 150.ms);
  }

  Widget _detailTile(String emoji, String label, String value, AppColors c) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.surfaceSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.dmSans(
                  color: c.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          Text(label,
              style: GoogleFonts.dmSans(color: c.textUltraFaint, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildNoForecastCard(AppColors c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surfaceSubtle,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          const Text('🔮', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Forecast not yet available',
                    style: GoogleFonts.dmSans(
                        color: c.textMuted,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  "We'll notify you when weather data arrives for this date.",
                  style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ── Note section ──────────────────────────────────────────────────────────

  Widget _buildNoteSection(AppColors c) {
    final existing = existingNote;
    final showEditor = existing == null || _editing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('NOTE',
                style: GoogleFonts.dmSans(
                    color: c.textUltraFaint,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5)),
            const Spacer(),
            if (existing != null && !_editing)
              Text('Updated ${_timeAgo(existing.updatedAt)}',
                  style: GoogleFonts.dmSans(
                      color: c.textUltraFaint, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 12),

        // ── Image — full width, above text ──
        if (_displayImagePath != null) ...[
          _buildImagePreview(_displayImagePath!, showEditor, c),
          const SizedBox(height: 12),
        ],

        if (showEditor) ...[
          // Category chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: NoteCategory.values.map((cat) {
                final selected = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () {
                    if (!selected) HapticFeedback.selectionClick();
                    setState(() => _selectedCategory = cat);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? c.accentSurface : c.surfaceSubtle,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected ? c.accentBorder : c.border),
                    ),
                    child: Text(
                      '${cat.emoji} ${cat.label}',
                      style: GoogleFonts.dmSans(
                        color: selected ? AppColors.accent : c.textFaint,
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (!showEditor)
          // View mode
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.surfaceSubtle,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(existing.category.emoji,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(existing.category.label,
                      style:
                          GoogleFonts.dmSans(color: c.textFaint, fontSize: 12)),
                ]),
                const SizedBox(height: 8),
                Text(existing.content,
                    style: GoogleFonts.dmSans(
                        color: c.textSecondary, fontSize: 15, height: 1.5)),
              ],
            ),
          )
        else ...[
          // Edit mode — text field
          Container(
            decoration: BoxDecoration(
              color: c.surfaceSubtle,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.borderStrong),
            ),
            child: TextField(
              controller: _noteController,
              maxLines: 6,
              autofocus: existing == null && _displayImagePath == null,
              style: GoogleFonts.dmSans(
                  color: c.textSecondary, fontSize: 15, height: 1.5),
              decoration: InputDecoration(
                hintText: isPast
                    ? 'Write a journal entry for this day...'
                    : 'What are your plans for this day?',
                hintStyle:
                    GoogleFonts.dmSans(color: c.textUltraFaint, fontSize: 15),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Add/change photo button
          GestureDetector(
            onTap: _showImageSourceSheet,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: c.surfaceSubtle,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      color: c.textMuted, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _displayImagePath != null ? 'Change photo' : 'Add a photo',
                    style: GoogleFonts.dmSans(
                        color: c.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveNote,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      existing != null ? 'Update Note' : 'Save Note',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
            ),
          ),
        ],
      ],
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  // ── Image preview widget ──────────────────────────────────────────────────

  Widget _buildImagePreview(String path, bool showEditor, AppColors c) {
    final file = File(path);
    if (!file.existsSync()) return const SizedBox();

    return GestureDetector(
      onTap: showEditor ? null : () => _openFullscreen(path),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.file(
              file,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 220,
                decoration: BoxDecoration(
                  color: c.surfaceSubtle,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.border),
                ),
                child: Center(
                  child: Text('Image not found',
                      style: GoogleFonts.dmSans(color: c.textFaint)),
                ),
              ),
            ),
          ),
          // Tap-to-view hint in view mode
          if (!showEditor)
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.fullscreen_rounded,
                        color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text('View',
                        style: GoogleFonts.dmSans(
                            color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            ),
          // Remove button in edit mode
          if (showEditor)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _pendingImagePath = null;
                    _clearImage = true;
                  });
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Fullscreen image viewer ───────────────────────────────────────────────────

class _FullscreenImageViewer extends StatelessWidget {
  final String imagePath;
  const _FullscreenImageViewer({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('Image not available',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
