// Renders the app icon PNGs: flutter test tool/render_icon_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const teal = Color(0xFF087F78);

/// A water drop filling [height] of a [size] square, centred.
Path drop(double size, double height) {
  final r = height * 0.36;
  final cx = size / 2;
  final top = (size - height) / 2;
  final cy = top + height - r;
  return Path()
    ..moveTo(cx, top)
    ..cubicTo(cx + r * 0.35, top + height * 0.3, cx + r, cy - r * 0.55, cx + r, cy)
    ..arcToPoint(Offset(cx - r, cy), radius: Radius.circular(r))
    ..cubicTo(cx - r, cy - r * 0.55, cx - r * 0.35, top + height * 0.3, cx, top)
    ..close();
}

Future<void> render(String path, {required bool background, required double dropHeight}) async {
  const size = 1024.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  if (background) canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), Paint()..color = teal);
  final shape = drop(size, dropHeight);
  canvas.drawPath(shape, Paint()..color = Colors.white);
  // A soft highlight on the left of the drop.
  final r = dropHeight * 0.36;
  final cy = (size - dropHeight) / 2 + dropHeight - r;
  canvas.drawArc(
    Rect.fromCircle(center: Offset(size / 2, cy), radius: r * 0.62),
    2.2,
    1.1,
    false,
    Paint()
      ..color = teal.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.13
      ..strokeCap = StrokeCap.round,
  );
  final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('render icon', (tester) async {
    await tester.runAsync(() async {
      await render('assets/icon/icon.png', background: true, dropHeight: 640);
      // flutter_launcher_icons insets the adaptive foreground by 16 %, which
      // already keeps it inside the circle or squircle mask.
      await render('assets/icon/foreground.png', background: false, dropHeight: 820);
    });
  });
}
