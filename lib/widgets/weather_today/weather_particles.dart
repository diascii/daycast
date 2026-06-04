import 'dart:math';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PARTICLE SYSTEM
// ─────────────────────────────────────────────────────────────────────────────

enum _ParticleType { rain, snow, fog, sunny, cloudy, thunder }

_ParticleType _particleTypeForCode(int code) {
  if (code >= 95) {
    return _ParticleType.thunder;
  }
  if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) {
    return _ParticleType.snow;
  }
  if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
    return _ParticleType.rain;
  }
  if (code == 45 || code == 48) {
    return _ParticleType.fog;
  }
  if (code == 0 || code == 1) {
    return _ParticleType.sunny;
  }
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
        Paint()..color = Colors.white.withValues(alpha: flash * 0.15),
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
                .withValues(alpha: p.opacity * 0.5)
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
            ..color = Colors.white.withValues(alpha: p.opacity * 0.8)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(Offset(px, py), p.size, paint);
          // Inner highlight
          paint.color = Colors.white.withValues(alpha: p.opacity * 0.3);
          canvas.drawCircle(Offset(px - p.size * 0.25, py - p.size * 0.25),
              p.size * 0.4, paint);
          break;

        case _ParticleType.fog:
          // Wispy, blurred horizontal bands
          paint
            ..color = (isDark ? Colors.white : Colors.blueGrey)
                .withValues(alpha: p.opacity * 0.12)
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
            ..color = Colors.amber.withValues(alpha: p.opacity * (isDark ? 0.055 : 0.08))
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
                .withValues(alpha: p.opacity * 0.1)
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

class WeatherParticles extends StatefulWidget {
  final int weatherCode;
  final bool isDark;
  const WeatherParticles({super.key, required this.weatherCode, required this.isDark});

  @override
  State<WeatherParticles> createState() => _WeatherParticlesState();
}

class _WeatherParticlesState extends State<WeatherParticles>
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
  void didUpdateWidget(WeatherParticles oldWidget) {
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
          if (p.y > 1.06) {
            p.y = -0.06;
            p.x = _rng.nextDouble();
          }
          break;
        case _ParticleType.snow:
          p.y += p.speed;
          p.x += sin(_time * 0.75 + p.phase) * 0.00075;
          if (p.y > 1.06) {
            p.y = -0.06;
            p.x = _rng.nextDouble();
          }
          break;
        case _ParticleType.fog:
          p.x += p.speed;
          if (p.x > 1.35) {
            p.x = -0.35;
          }
          break;
        case _ParticleType.sunny:
          p.phase += p.speed;
          break;
        case _ParticleType.cloudy:
          p.x += p.speed;
          if (p.x > 1.25) {
            p.x = -0.25;
          }
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
