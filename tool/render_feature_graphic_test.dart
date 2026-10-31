// Renders the Google Play feature graphic (1024 × 500):
// flutter test tool/render_feature_graphic_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'render_icon_test.dart' show drop;

const fontDir = '/System/Library/Fonts/Supplemental';

Future<void> loadFont(String family, String file) async {
  final bytes = File('$fontDir/$file').readAsBytesSync();
  await (FontLoader(family)..addFont(Future.value(ByteData.sublistView(bytes))))
      .load();
}

void paintText(Canvas canvas, String text, Offset at, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, at);
}

void main() {
  testWidgets('render feature graphic', (tester) async {
    await tester.runAsync(() async {
      await loadFont('Rounded', 'Arial Rounded Bold.ttf');
      await loadFont('Arial', 'Arial.ttf');
      const width = 1024.0, height = 500.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, width, height),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset.zero,
            const Offset(width, height),
            [const Color(0xFF0A9A90), const Color(0xFF065E59)],
          ),
      );
      // A winding road across the bottom.
      final road = Path()
        ..moveTo(-20, 470)
        ..cubicTo(260, 380, 520, 520, 1044, 400);
      canvas.drawPath(
        road,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 46,
      );
      canvas.drawPath(
        road,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      // The app's drop, as in the icon.
      canvas.save();
      canvas.translate(70, 60);
      canvas.drawPath(drop(330, 330), Paint()..color = Colors.white);
      canvas.restore();
      paintText(
        canvas,
        'i fillup',
        const Offset(430, 110),
        const TextStyle(fontFamily: 'Rounded', fontSize: 104, color: Colors.white),
      );
      paintText(
        canvas,
        'Fresh water for your campervan',
        const Offset(436, 250),
        const TextStyle(fontFamily: 'Arial', fontSize: 34, color: Colors.white),
      );
      paintText(
        canvas,
        'Near you · Along your route · From local hosts',
        const Offset(436, 300),
        TextStyle(
          fontFamily: 'Arial',
          fontSize: 24,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      );
      final image = await recorder.endRecording().toImage(
        width.toInt(),
        height.toInt(),
      );
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('store/feature-graphic.png').writeAsBytesSync(
        bytes!.buffer.asUint8List(),
      );
    });
  });
}
