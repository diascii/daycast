import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../models/weather_model.dart';
import '../theme/app_theme.dart';
import '../services/weather_service.dart' show TempUnit;
import '../widgets/weather_share_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PARTICLE SYSTEM
// ─────────────────────────────────────────────────────────────────────────────

enum _ParticleType { rain, snow, fog, sunny, cloudy, thunder }

_ParticleType _particleTypeForCode(int code) {
  if (code >= 95) return _ParticleType.thunder;
  if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86))
    return _ParticleType.snow;
  if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82))
    return _ParticleType.rain;
  if (code == 45 || code == 48) return _ParticleType.fog;
  if (code == 0 || code == 1) return _ParticleType.sunny;
  return _ParticleType.cloudy;
}

class _Particle {
  double x, y, speed, size, opacity, angle, phase;
  _Particle({
    required this.x, required this.y, required this.speed,
    required this.size, required this.opacity,
    required this.angle, required this.phase,
  });
}

class _WeatherParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final _ParticleType type;
  final double flash;
  final double time;
  final bool isDark;

  _WeatherParticlesPainter({
    required this.particles, required this.type,
    required this.flash, required this.time, required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Thunder screen flash
    if ((type == _ParticleType.thunder || type == _ParticleType.rain) &&
        flash > 0) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white.withOpacity(flash * 0.15),
      );
    }

    final paint = Paint()..isAntiAlias = true;

    for (final p in particles) {
      final px = p.x * size.width;
      final py = p.y * size.height;

      switch (type) {
        case _ParticleType.rain:
        case _ParticleType.thunder:
          // Slanted raindrop streak
          paint
            ..color = (isDark ? Colors.lightBlueAccent : Colors.blueAccent)
                .withOpacity(p.opacity * 0.5)
            ..strokeWidth = p.size
            ..style = PaintingStyle.stroke;
          canvas.drawLine(
            Offset(px, py),
            Offset(px + sin(p.angle) * p.size * 7,
                py + cos(p.angle) * p.size * 16),
            paint,
          );
          break;

        case _ParticleType.snow:
          // Soft circular snowflake
          paint
            ..color = Colors.white.withOpacity(p.opacity * 0.8)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(px, py), p.size, paint);
          // Inner highlight
          paint.color = Colors.white.withOpacity(p.opacity * 0.3);
          canvas.drawCircle(Offset(px - p.size * 0.25, py - p.size * 0.25),
              p.size * 0.4, paint);
          break;

        case _ParticleType.fog:
          // Wispy, blurred horizontal bands
          paint
            ..color = (isDark ? Colors.white : Colors.blueGrey)
                .withOpacity(p.opacity * 0.12)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 8)
            ..style = PaintingStyle.fill;
          
          final drift = sin(time * 0.5 + p.phase) * 15;
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(px, py + drift),
              width: p.size * 110,
              height: p.size * 22,
            ),
            paint,
          );
          break;

        case _ParticleType.sunny:
          // Rotating sun rays from top-center
          paint
            ..color = Colors.amber.withOpacity(p.opacity * (isDark ? 0.055 : 0.08))
            ..strokeWidth = p.size * 1.8
            ..style = PaintingStyle.stroke;
          final cx = size.width * 0.5;
          final cy = size.height * -0.04;
          final r1 = size.width * 0.20;
          final r2 = size.width * (0.30 + p.size * 0.28);
          canvas.drawLine(
            Offset(cx + cos(p.phase) * r1, cy + sin(p.phase) * r1),
            Offset(cx + cos(p.phase) * r2, cy + sin(p.phase) * r2),
            paint,
          );
          break;

        case _ParticleType.cloudy:
          // Billowy cloud groups made of overlapping circles
          paint
            ..color = (isDark ? Colors.white : Colors.blueGrey)
                .withOpacity(p.opacity * 0.1)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 5)
            ..style = PaintingStyle.fill;

          final cy = size.height * 0.35 * p.y;
          final drift = sin(time * 0.3 + p.phase) * 10;
          
          // Draw a cluster of circles to form a cloud-like shape
          void drawBlob(double dx, double dy, double scale) {
            canvas.drawCircle(Offset(px + dx * p.size, cy + dy * p.size + drift), p.size * 15 * scale, paint);
          }

          drawBlob(0, 0, 1.0);
          drawBlob(-12, 5, 0.7);
          drawBlob(12, 4, 0.8);
          drawBlob(5, -6, 0.6);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(_WeatherParticlesPainter old) => true;
}

class _WeatherParticles extends StatefulWidget {
  final int weatherCode;
  final bool isDark;
  const _WeatherParticles({required this.weatherCode, required this.isDark});

  @override
  State<_WeatherParticles> createState() => _WeatherParticlesState();
}

class _WeatherParticlesState extends State<_WeatherParticles>
    with TickerProviderStateMixin {
  late AnimationController _ticker;
  final Random _rng = Random();
  late List<_Particle> _particles;
  late _ParticleType _type;
  double _flash = 0.0;
  double _time = 0.0;

  @override
  void initState() {
    super.initState();
    _type = _particleTypeForCode(widget.weatherCode);
    _particles = _buildParticles();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )
      ..addListener(_tick)
      ..repeat();

    if (_type == _ParticleType.thunder) _scheduleFlash();
  }

  @override
  void didUpdateWidget(_WeatherParticles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weatherCode != widget.weatherCode || oldWidget.isDark != widget.isDark) {
      _type = _particleTypeForCode(widget.weatherCode);
      _particles = _buildParticles();
      _time = 0.0;
      if (_type == _ParticleType.thunder) _scheduleFlash();
    }
  }

  List<_Particle> _buildParticles() {
    switch (_type) {
      case _ParticleType.rain:
      case _ParticleType.thunder:
        return List.generate(
          40,
          (_) => _Particle(
            x: _rng.nextDouble(),
            y: _rng.nextDouble(),
            speed: 0.006 + _rng.nextDouble() * 0.006,
            size: 0.55 + _rng.nextDouble() * 0.75,
            opacity: 0.35 + _rng.nextDouble() * 0.5,
            angle: -0.28 + _rng.nextDouble() * 0.18,
            phase: 0,
          ),
        );
      case _ParticleType.snow:
        return List.generate(
          30,
          (_) => _Particle(
            x: _rng.nextDouble(),
            y: _rng.nextDouble(),
            speed: 0.0012 + _rng.nextDouble() * 0.0018,
            size: 1.4 + _rng.nextDouble() * 2.8,
            opacity: 0.45 + _rng.nextDouble() * 0.45,
            angle: 0,
            phase: _rng.nextDouble() * pi * 2,
          ),
        );
      case _ParticleType.fog:
        return List.generate(
          16,
          (_) => _Particle(
            x: _rng.nextDouble(),
            y: 0.15 + _rng.nextDouble() * 0.70,
            speed: 0.0003 + _rng.nextDouble() * 0.0005,
            size: 1.2 + _rng.nextDouble() * 2.5,
            opacity: 0.4 + _rng.nextDouble() * 0.6,
            angle: 0,
            phase: _rng.nextDouble() * pi * 2,
          ),
        );
      case _ParticleType.sunny:
        // 12 evenly-spaced rays
        return List.generate(
          12,
          (i) => _Particle(
            x: 0.5, y: 0,
            speed: 0.00018,
            size: 0.75 + _rng.nextDouble() * 0.55,
            opacity: 0.45 + _rng.nextDouble() * 0.45,
            angle: 0,
            phase: (i / 12) * pi * 2,
          ),
        );
      case _ParticleType.cloudy:
        return List.generate(
          10,
          (_) => _Particle(
            x: _rng.nextDouble(),
            y: _rng.nextDouble(),
            speed: 0.00015 + _rng.nextDouble() * 0.0002,
            size: 1.0 + _rng.nextDouble() * 1.8,
            opacity: 0.5 + _rng.nextDouble() * 0.5,
            angle: 0,
            phase: _rng.nextDouble() * pi * 2,
          ),
        );
    }
  }

  void _tick() {
    _time += 0.016;
    for (final p in _particles) {
      switch (_type) {
        case _ParticleType.rain:
        case _ParticleType.thunder:
          p.y += p.speed;
          p.x += sin(p.angle) * p.speed * 0.35;
          if (p.y > 1.06) { p.y = -0.06; p.x = _rng.nextDouble(); }
          break;
        case _ParticleType.snow:
          p.y += p.speed;
          p.x += sin(_time * 0.75 + p.phase) * 0.00075;
          if (p.y > 1.06) { p.y = -0.06; p.x = _rng.nextDouble(); }
          break;
        case _ParticleType.fog:
          p.x += p.speed;
          if (p.x > 1.35) p.x = -0.35;
          break;
        case _ParticleType.sunny:
          p.phase += p.speed;
          break;
        case _ParticleType.cloudy:
          p.x += p.speed;
          if (p.x > 1.25) p.x = -0.25;
          break;
      }
    }
    setState(() {});
  }

  void _scheduleFlash() async {
    while (mounted) {
      await Future.delayed(Duration(milliseconds: 5000 + _rng.nextInt(9000)));
      if (!mounted) break;
      await _doFlash();
      // Occasional double flash
      if (_rng.nextBool() && mounted) {
        await Future.delayed(const Duration(milliseconds: 90));
        await _doFlash();
      }
    }
  }

  Future<void> _doFlash() async {
    if (!mounted) return;
    setState(() => _flash = 0.75 + _rng.nextDouble() * 0.25);
    await Future.delayed(const Duration(milliseconds: 55));
    if (mounted) setState(() => _flash = 0.0);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _WeatherParticlesPainter(
          particles: _particles,
          type: _type,
          flash: _flash,
          time: _time,
          isDark: widget.isDark,
        ),
        size: Size.infinite,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED BACKGROUND
// ─────────────────────────────────────────────────────────────────────────────

class _LightBackground extends StatefulWidget {
  final int weatherCode;
  final bool isDark;
  final Widget child;

  const _LightBackground({
    required this.weatherCode,
    required this.isDark,
    required this.child,
  });

  @override
  State<_LightBackground> createState() => _LightBackgroundState();
}

class _LightBackgroundState extends State<_LightBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _orb1X, _orb1Y, _orb2X, _orb2Y;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 18));
    _orb1X = Tween<double>(begin: -0.08, end: 0.08)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _orb1Y = Tween<double>(begin: -0.06, end: 0.06)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _orb2X = Tween<double>(begin: 0.06, end: -0.06)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _orb2Y = Tween<double>(begin: 0.05, end: -0.05)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void didUpdateWidget(_LightBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger rebuild when weatherCode or isDark changes so gradient and orb colors update
    if (oldWidget.weatherCode != widget.weatherCode || oldWidget.isDark != widget.isDark) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final gradient = c.weatherBgGradient(widget.weatherCode);
    final orbs = c.weatherOrbColors(widget.weatherCode);
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient,
        ),
      ),
      child: Stack(
        children: [
          // Orb layer
          Opacity(
            opacity: 0.5,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, child) => Positioned(
                    left: size.width * (-0.25 + _orb1X.value),
                    top: size.height * (-0.10 + _orb1Y.value),
                    child: child!,
                  ),
                  child: Container(
                    width: size.width * 0.75,
                    height: size.width * 0.75,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: orbs[0]),
                  ),
                ),
                AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, child) => Positioned(
                    right: size.width * (-0.20 + _orb2X.value),
                    bottom: size.height * (-0.05 + _orb2Y.value),
                    child: child!,
                  ),
                  child: Container(
                    width: size.width * 0.60,
                    height: size.width * 0.60,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: orbs[1]),
                  ),
                ),
              ],
            ),
          ),
          // Particle layer — above orbs, below content, non-interactive
          Positioned.fill(
            child: _WeatherParticles(
              weatherCode: widget.weatherCode,
              isDark: widget.isDark,
            ),
          ),
          // Content
          widget.child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WeatherTodayScreen
// ─────────────────────────────────────────────────────────────────────────────

class WeatherTodayScreen extends StatelessWidget {
  final AppState state;
  const WeatherTodayScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (_, __) {
        final c = AppColors.of(context);
        final weatherCode = state.currentWeather?.weatherCode ?? 3;

        if (state.loadingWeather && state.currentWeather == null) {
          return _LightBackground(
            weatherCode: 3,
            isDark: c.isDark,
            child: Center(
              child: CircularProgressIndicator(color: c.textMuted, strokeWidth: 2),
            ),
          );
        }

        if (state.weatherError != null && state.currentWeather == null) {
          return _LightBackground(
            weatherCode: 3,
            isDark: c.isDark,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('😕', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text(state.weatherError!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(color: c.textMuted, fontSize: 15)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: state.refreshWeather,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Retry', style: GoogleFonts.dmSans()),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final current = state.currentWeather!;
        final today = state.todayForecast;

        return _LightBackground(
          weatherCode: weatherCode,
          isDark: c.isDark,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () => _showShareDialog(context, state, c),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: c.surfaceSubtle,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.share_rounded, color: c.textPrimary, size: 20),
                      ),
                    ),
                  ],
                ),
                _buildCurrentWeather(context, current, today, c, state.useFahrenheit),
                const SizedBox(height: 24),
                _buildHourlyStrip(context, state, c),
                const SizedBox(height: 24),
                _buildWeekStrip(context, state, c),
                const SizedBox(height: 24),
                _buildCurrentDetails(context, current, today, c, state.useFahrenheit),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Hourly strip ──────────────────────────────────────────────────────────

  Widget _buildHourlyStrip(BuildContext context, AppState state, AppColors c) {
    if (state.forecast.isEmpty) return const SizedBox();
    final now = DateTime.now();
    final allHourly = <HourlyWeather>[];
    for (final day in state.forecast.take(4)) allHourly.addAll(day.hourly);
    if (allHourly.isEmpty) return const SizedBox();

    final lookback = now.subtract(const Duration(minutes: 5));
    final slots = (allHourly..sort((a, b) => a.time.compareTo(b.time)))
        .where((h) => !h.time.isBefore(lookback))
        .take(6)
        .toList();
    if (slots.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('NEXT 6 HOURS',
            style: GoogleFonts.dmSans(
                color: c.textUltraFaint, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: c.surfaceSubtle,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: slots.asMap().entries.map((entry) {
                final i = entry.key;
                final h = entry.value;
                final isNow = i == 0;
                final rainPct = h.precipitationProbability.round();
                return Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isNow ? 'Now' : DateFormat('ha').format(h.time).toLowerCase(),
                        style: GoogleFonts.dmSans(
                          color: isNow ? AppColors.accent : c.textMuted,
                          fontSize: 11,
                          fontWeight: isNow ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(h.emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 6),
                      Text(
                        TempUnit.format(h.temperature, state.useFahrenheit),
                        style: GoogleFonts.dmSans(
                          color: isNow ? c.textPrimary : c.textSecondary,
                          fontSize: 14,
                          fontWeight: isNow ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (rainPct > 0)
                        Text('$rainPct%',
                            style: GoogleFonts.dmSans(
                                color: const Color(0xFF64b5f6),
                                fontSize: 10,
                                fontWeight: FontWeight.w600))
                      else
                        const SizedBox(height: 14),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms);
  }

  // ── Current weather hero ──────────────────────────────────────────────────

  Widget _buildCurrentWeather(BuildContext context, CurrentWeather current,
      DayWeather? today, AppColors c, bool useFahrenheit) {
    return Builder(
      builder: (context) => Column(
        children: [
          Text(current.emoji, style: const TextStyle(fontSize: 80))
              .animate(onPlay: (ctrl) => ctrl.repeat())
              .shimmer(duration: 3000.ms, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${TempUnit.convert(current.temperature, useFahrenheit).round()}',
                style: GoogleFonts.dmSans(
                    color: c.textPrimary, fontSize: 80,
                    fontWeight: FontWeight.w200, height: 1),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(TempUnit.symbol(useFahrenheit),
                    style: GoogleFonts.dmSans(
                        color: c.textFaint, fontSize: 28, fontWeight: FontWeight.w300)),
              ),
            ],
          ),
          Text(current.description,
              style: GoogleFonts.dmSans(
                  color: c.textSecondary, fontSize: 18, fontWeight: FontWeight.w400)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Feels like ${TempUnit.format(current.feelsLike, useFahrenheit)}',
                  style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 13)),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showFeelsLikeInfo(context, current, c, useFahrenheit);
                },
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: c.textFaint, width: 1)),
                  child: Center(
                    child: Text('?',
                        style: GoogleFonts.dmSans(
                            color: c.textFaint, fontSize: 9,
                            fontWeight: FontWeight.w700, height: 1)),
                  ),
                ),
              ),
              if (today != null) ...[
                const SizedBox(width: 12),
                Container(width: 1, height: 10, color: c.border),
                const SizedBox(width: 12),
                Text(
                  '${TempUnit.format(today.tempMin, useFahrenheit)} / ${TempUnit.format(today.tempMax, useFahrenheit)}',
                  style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 13),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(DateFormat('EEEE, MMMM d').format(DateTime.now()),
              style: GoogleFonts.dmSans(color: c.textUltraFaint, fontSize: 12)),
        ],
      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05),
    );
  }

  void _showFeelsLikeInfo(BuildContext context, CurrentWeather current,
      AppColors c, bool useFahrenheit) {
    final feelsConverted = TempUnit.convert(current.feelsLike, useFahrenheit);
    final actualConverted = TempUnit.convert(current.temperature, useFahrenheit);
    final diff = (feelsConverted - actualConverted).round();
    final absDiff = diff.abs();
    final unitSymbol = TempUnit.symbol(useFahrenheit);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: c.textUltraFaint, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: c.accentSurface, borderRadius: BorderRadius.circular(12)),
                child: const Center(child: Text('🌡️', style: TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Feels Like Temperature',
                    style: GoogleFonts.dmSans(
                        color: c.textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
                Text('Also called Apparent Temperature',
                    style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 12)),
              ]),
            ]),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: c.surfaceSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border)),
              child: Row(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Actual', style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 12)),
                  Text(TempUnit.format(current.temperature, useFahrenheit),
                      style: GoogleFonts.dmSans(
                          color: c.textPrimary, fontSize: 22, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(width: 24),
                Container(width: 1, height: 36, color: c.border),
                const SizedBox(width: 24),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Feels Like', style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 12)),
                  Text(TempUnit.format(current.feelsLike, useFahrenheit),
                      style: GoogleFonts.dmSans(
                          color: AppColors.accent, fontSize: 22, fontWeight: FontWeight.w600)),
                ]),
                if (absDiff > 0) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: diff < 0
                          ? const Color(0xFF64b5f6).withValues(alpha: 0.15)
                          : Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${diff > 0 ? '+' : '-'}${absDiff}$unitSymbol',
                      style: GoogleFonts.dmSans(
                          color: diff < 0 ? const Color(0xFF64b5f6) : Colors.orange,
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            Text('What is it?',
                style: GoogleFonts.dmSans(
                    color: c.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              'Apparent temperature is how hot or cold it actually feels on your skin — not just what the thermometer reads. It combines the real air temperature with wind speed and humidity to give you a more accurate sense of comfort.',
              style: GoogleFonts.dmSans(color: c.textMuted, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 14),
            Text('Why does it differ?',
                style: GoogleFonts.dmSans(
                    color: c.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              absDiff == 0
                  ? 'Right now they match — calm winds and moderate humidity mean the air temperature is a perfect reflection of how it feels outside.'
                  : diff < 0
                      ? 'Right now it feels ${absDiff}$unitSymbol cooler than the actual temperature. This is likely due to wind chill — moving air carries heat away from your body faster, making it feel colder.'
                      : 'Right now it feels ${absDiff}$unitSymbol warmer than the actual temperature. High humidity is likely the cause — when air is humid, sweat evaporates more slowly, so your body can\'t cool itself as well.',
              style: GoogleFonts.dmSans(color: c.textMuted, fontSize: 13, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  // ── 7-day strip ───────────────────────────────────────────────────────────

  Widget _buildWeekStrip(BuildContext context, AppState state, AppColors c) {
    if (state.forecast.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('7-DAY FORECAST',
            style: GoogleFonts.dmSans(
                color: c.textUltraFaint, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: c.surfaceSubtle,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemCount: state.forecast.length > 7 ? 7 : state.forecast.length,
            separatorBuilder: (_, __) =>
                Divider(color: c.divider, height: 1, indent: 16, endIndent: 16),
            itemBuilder: (ctx, i) {
              final d = state.forecast[i];
              final isToday = i == 0;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(children: [
                  SizedBox(
                    width: 52,
                    child: Text(
                      isToday ? 'Today' : DateFormat('EEE').format(d.date),
                      style: GoogleFonts.dmSans(
                          color: isToday ? c.textPrimary : c.textSecondary,
                          fontSize: 14,
                          fontWeight: isToday ? FontWeight.w600 : FontWeight.w400),
                    ),
                  ),
                  Text(d.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(d.description,
                          style: GoogleFonts.dmSans(color: c.textFaint, fontSize: 13))),
                  if (d.isGoodLaundryDay)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Text('👕', style: TextStyle(fontSize: 14)),
                    ),
                  Text(TempUnit.format(d.tempMin, state.useFahrenheit),
                      style: GoogleFonts.dmSans(color: c.textUltraFaint, fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(TempUnit.format(d.tempMax, state.useFahrenheit),
                      style: GoogleFonts.dmSans(
                          color: c.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 200.ms);
  }

  // ── Current Conditions ────────────────────────────────────────────────────

  Widget _buildCurrentDetails(BuildContext context, CurrentWeather current,
      DayWeather? today, AppColors c, bool useFahrenheit) {
    final moon = MoonPhase.forDate(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CURRENT CONDITIONS',
            style: GoogleFonts.dmSans(
                color: c.textUltraFaint, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 10),
        _buildMoonPhaseTile(moon, c),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _statTile('💧', 'Humidity', '${current.humidity}%', c),
            _statTile('💨', 'Wind', '${current.windSpeed.round()} km/h', c),
            _statTile('🌡️', 'UV Index', '${current.uvIndex}', c),
            _statTile('👁️', 'Visibility', '${current.visibility} km', c),
            if (today != null) ...[
              _statTile('🌅', 'Sunrise', DateFormat('h:mm a').format(today.sunrise), c),
              _statTile('🌇', 'Sunset', DateFormat('h:mm a').format(today.sunset), c),
            ],
            _buildPressureTile(current, c),
            if (current.aqiUs != null) _buildAqiTile(current, c),
            if (current.dominantPollen != null) _buildPollenTile(current, c),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms);
  }

  Widget _buildMoonPhaseTile(MoonPhase moon, AppColors c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: c.surfaceSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Row(children: [
        Text(moon.emoji, style: const TextStyle(fontSize: 44)),
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
            Text(moon.name,
                style: GoogleFonts.dmSans(
                    color: c.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('${moon.illuminationPercent} illuminated',
                style: GoogleFonts.dmSans(color: c.textMuted, fontSize: 12)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          _moonCountdown('🌕', 'Full', moon.daysToFullMoon, c),
          const SizedBox(height: 6),
          _moonCountdown('🌑', 'New', moon.daysToNewMoon, c),
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

  Widget _buildPressureTile(CurrentWeather current, AppColors c) {
    final pressure = current.pressure;
    final change = current.pressureChange;
    final isDropping = current.isPressureDropping;
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
            Text(pressure != null ? '${pressure.round()} hPa' : 'N/A',
                style: GoogleFonts.dmSans(
                    color: c.textPrimary, fontSize: 20, fontWeight: FontWeight.w600)),
            if (change != null)
              Text(
                '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)} hPa / 3h',
                style: GoogleFonts.dmSans(
                    color: change < 0 ? Colors.orange : const Color(0xFF69F0AE),
                    fontSize: 10),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _buildAqiTile(CurrentWeather current, AppColors c) {
    final aqi = current.aqiUs!;
    final Color aqiColor;
    if (aqi <= 50) aqiColor = const Color(0xFF69F0AE);
    else if (aqi <= 100) aqiColor = Colors.yellow;
    else if (aqi <= 150) aqiColor = Colors.orange;
    else if (aqi <= 200) aqiColor = Colors.red;
    else aqiColor = Colors.purple;

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
            Text(current.aqiEmoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text('Air Quality',
                style: GoogleFonts.dmSans(color: c.textUltraFaint, fontSize: 12)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(current.aqiLabel,
                style: GoogleFonts.dmSans(
                    color: aqiColor, fontSize: 16, fontWeight: FontWeight.w700)),
            Text('AQI ${aqi.round()}',
                style: GoogleFonts.dmSans(color: c.textMuted, fontSize: 11)),
          ]),
        ],
      ),
    );
  }

  Widget _buildPollenTile(CurrentWeather current, AppColors c) {
    final pollen = current.dominantPollen!;
    final Color pollenColor;
    switch (pollen.level) {
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
            Text(pollen.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text('Pollen',
                style: GoogleFonts.dmSans(color: c.textUltraFaint, fontSize: 12)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(pollen.level,
                style: GoogleFonts.dmSans(
                    color: pollenColor, fontSize: 16, fontWeight: FontWeight.w700)),
            Text('${pollen.type} pollen',
                style: GoogleFonts.dmSans(color: c.textMuted, fontSize: 11)),
          ]),
        ],
      ),
    );
  }

  Widget _statTile(String emoji, String label, String value, AppColors c) {
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

  void _showShareDialog(BuildContext context, AppState state, AppColors c) {
    final shareKey = GlobalKey();
    final weather = state.currentWeather;
    if (weather == null) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: RepaintBoundary(
                key: shareKey,
                child: WeatherShareCard(
                  cityName: state.cityName,
                  weather: weather,
                  note: state.noteForDate(DateTime.now()),
                  useFahrenheit: state.useFahrenheit,
                  isDark: state.isDark,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    await ShareUtils.captureAndShare(shareKey, state.cityName);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  icon: const Icon(Icons.send_rounded),
                  label: Text('Share Now', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}