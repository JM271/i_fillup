import 'dart:math' as math;

import 'package:flutter/material.dart';

// Water palette: from deep lake to shallow, sunlit water.
const ink = Color(0xFF0E3446);
const deep = Color(0xFF0B4F6C);
const teal = Color(0xFF0A8EA0);
const sky = Color(0xFF49C6E5);
const foam = Color(0xFFE3F5F9);
const mist = Color(0xFFF2F9FB);
const muted = Color(0xFF5B7884);

const waterGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [deep, teal, sky],
);

/// Gradient panel whose bottom edge is a wave; used as a screen header.
class WaveHeader extends StatelessWidget {
  const WaveHeader({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipPath(
    clipper: const _WaveClipper(),
    child: DecoratedBox(
      decoration: const BoxDecoration(gradient: waterGradient),
      child: CustomPaint(
        painter: const _RipplePainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 56),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: IconTheme.merge(
              data: const IconThemeData(color: Colors.white),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Rounded gradient card with soft ripples, for the top of a list.
class WaterBanner extends StatelessWidget {
  const WaterBanner({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: DecoratedBox(
      decoration: const BoxDecoration(gradient: waterGradient),
      child: CustomPaint(
        painter: const _RipplePainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineLarge
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.88)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The app's drop mark: a white drop on a glassy circle.
class DropBadge extends StatelessWidget {
  const DropBadge({super.key, this.size = 72});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: 0.18),
      border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
    ),
    child: Icon(Icons.water_drop, size: size * 0.55, color: Colors.white),
  );
}

/// Small gradient circle holding an icon, used on choice cards.
class WaterIcon extends StatelessWidget {
  const WaterIcon(this.icon, {super.key, this.size = 48});
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: waterGradient,
      boxShadow: [
        BoxShadow(
          color: teal.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Icon(icon, color: Colors.white, size: size * 0.5),
  );
}

class _WaveClipper extends CustomClipper<Path> {
  const _WaveClipper();

  @override
  Path getClip(Size size) {
    final h = size.height;
    final w = size.width;
    return Path()
      ..lineTo(0, h - 28)
      ..cubicTo(w * 0.25, h, w * 0.45, h - 48, w * 0.7, h - 22)
      ..cubicTo(w * 0.85, h - 8, w * 0.95, h - 20, w, h - 32)
      ..lineTo(w, 0)
      ..close();
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) => false;
}

/// Faint concentric rings, like a drop landing on still water.
class _RipplePainter extends CustomPainter {
  const _RipplePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.12);
    final center = Offset(size.width * 0.9, size.height * 0.15);
    final maxRadius = math.max(size.width, size.height) * 0.6;
    for (var r = 30.0; r < maxRadius; r += 28) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) => false;
}

final waterTheme = () {
  final scheme = ColorScheme.fromSeed(
    seedColor: teal,
    primary: teal,
    secondary: deep,
    surface: mist,
  );
  final rounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  );
  return ThemeData(
    useMaterial3: true,
    visualDensity: VisualDensity.compact,
    colorScheme: scheme,
    scaffoldBackgroundColor: mist,
    appBarTheme: const AppBarTheme(
      backgroundColor: mist,
      surfaceTintColor: Colors.transparent,
      foregroundColor: ink,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: ink,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: rounded.copyWith(side: const BorderSide(color: foam, width: 1.5)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 44),
        shape: const StadiumBorder(),
        side: const BorderSide(color: teal, width: 1.5),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: foam, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: foam, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: teal, width: 2),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        side: const BorderSide(color: teal),
        selectedBackgroundColor: foam,
        selectedForegroundColor: deep,
      ),
    ),
    chipTheme: const ChipThemeData(
      shape: StadiumBorder(),
      side: BorderSide(color: foam),
      backgroundColor: Colors.white,
      selectedColor: foam,
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: foam,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? teal : muted,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(shape: rounded),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: ink,
        height: 1.12,
      ),
      headlineSmall: TextStyle(fontWeight: FontWeight.w800, color: ink),
      titleLarge: TextStyle(fontWeight: FontWeight.w700, color: ink),
    ),
  );
}();
