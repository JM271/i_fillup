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

/// A schematic campervan with a water-wave stripe, for the home header.
class CampervanPicture extends StatelessWidget {
  const CampervanPicture({super.key, this.width = 220});
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: width * _CampervanPainter.height / _CampervanPainter.width,
    child: const CustomPaint(painter: _CampervanPainter()),
  );
}

/// Draws on a 200 × 110 grid, scaled to the given size.
class _CampervanPainter extends CustomPainter {
  const _CampervanPainter();

  static const width = 200.0;
  static const height = 110.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / width, size.height / height);

    // Dashed road under the wheels.
    final road = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var x = 4.0; x < width; x += 22) {
      canvas.drawLine(Offset(x, 104), Offset(x + 10, 104), road);
    }

    // Pop-top roof.
    canvas.drawRRect(
      RRect.fromLTRBR(40, 10, 112, 22, const Radius.circular(5)),
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );

    // Body: boxy at the back, sloped windscreen and short bonnet in front.
    final body = Path()
      ..moveTo(24, 86)
      ..quadraticBezierTo(14, 86, 14, 76)
      ..lineTo(14, 30)
      ..quadraticBezierTo(14, 20, 24, 20)
      ..lineTo(140, 20)
      ..quadraticBezierTo(150, 20, 155, 28)
      ..lineTo(172, 54)
      ..quadraticBezierTo(188, 56, 188, 68)
      ..lineTo(188, 78)
      ..quadraticBezierTo(188, 86, 180, 86)
      ..close();
    canvas.drawShadow(body, deep, 6, false);
    canvas.drawPath(body, Paint()..color = Colors.white);

    // Water-wave stripe along the side.
    canvas.save();
    canvas.clipPath(body);
    final wave = Path()..moveTo(0, 62);
    for (var x = 0.0; x < width; x += 40) {
      wave
        ..quadraticBezierTo(x + 10, 56, x + 20, 62)
        ..quadraticBezierTo(x + 30, 68, x + 40, 62);
    }
    wave
      ..lineTo(width, 72)
      ..lineTo(0, 72)
      ..close();
    canvas.drawPath(wave, Paint()..color = teal);
    canvas.restore();

    // Windows, windscreen and the sliding door's seam.
    final glass = Paint()..color = sky.withValues(alpha: 0.75);
    for (final left in [26.0, 72.0]) {
      canvas.drawRRect(
        RRect.fromLTRBR(left, 30, left + 36, 50, const Radius.circular(5)),
        glass,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(124, 30)
        ..lineTo(149, 30)
        ..lineTo(163, 50)
        ..lineTo(124, 50)
        ..close(),
      glass,
    );
    canvas.drawLine(
      const Offset(118, 28),
      const Offset(118, 82),
      Paint()
        ..color = deep.withValues(alpha: 0.25)
        ..strokeWidth = 1.5,
    );

    // Headlight.
    canvas.drawCircle(const Offset(182, 64), 3.5, Paint()..color = foam);
    canvas.drawCircle(
      const Offset(182, 64),
      3.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = deep.withValues(alpha: 0.4),
    );

    // Wheels.
    for (final x in [50.0, 156.0]) {
      canvas.drawCircle(Offset(x, 88), 14, Paint()..color = ink);
      canvas.drawCircle(Offset(x, 88), 6, Paint()..color = foam);
    }
  }

  @override
  bool shouldRepaint(_CampervanPainter oldDelegate) => false;
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
