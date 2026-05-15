import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'weather_particles.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED BACKGROUND WITH ORBS AND PARTICLES
// ─────────────────────────────────────────────────────────────────────────────

class WeatherAnimatedBackground extends StatefulWidget {
  final int weatherCode;
  final bool isDark;
  final Widget child;

  const WeatherAnimatedBackground({
    super.key,
    required this.weatherCode,
    required this.isDark,
    required this.child,
  });

  @override
  State<WeatherAnimatedBackground> createState() => _WeatherAnimatedBackgroundState();
}

class _WeatherAnimatedBackgroundState extends State<WeatherAnimatedBackground>
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
  void didUpdateWidget(WeatherAnimatedBackground oldWidget) {
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
            child: WeatherParticles(
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
