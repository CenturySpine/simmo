// Regenerates the PWA icons and favicon (web/icons/*.png, web/favicon.png)
// from the in-app logo drawing (lib/shared/simmo_logo.dart).
//
// Run with: fvm flutter test tool/generate_icons.dart
// (a `flutter test` entry point because it needs dart:ui to paint and encode
// PNGs; it lives in tool/, not test/, so the regular test run skips it).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simmo/shared/simmo_logo.dart';

/// Full-bleed square (the platform applies its own mask), glyph at 60% of
/// the side -- inside the 80% safe zone maskable icons require.
Future<void> _render(String path, int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final side = size.toDouble();
  final rect = Rect.fromLTWH(0, 0, side, side);
  canvas.drawRect(rect, Paint()..shader = brandGradient.createShader(rect));
  final glyph = side * 0.6;
  canvas.save();
  canvas.translate((side - glyph) / 2, (side - glyph) / 2);
  SimmoLogoGlyphPainter().paint(canvas, Size(glyph, glyph));
  canvas.restore();

  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('generate PWA icons', (tester) async {
    await tester.runAsync(() async {
      await _render('web/icons/Icon-192.png', 192);
      await _render('web/icons/Icon-512.png', 512);
      await _render('web/icons/Icon-maskable-192.png', 192);
      await _render('web/icons/Icon-maskable-512.png', 512);
      await _render('web/favicon.png', 64);
    });
  });
}
