import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sora/src/ui/qr.dart';

/// The share screen draws a link with qr_flutter; the scan screen must read
/// the same code back from a screenshot of it.
void main() {
  testWidgets('a shared QR code reads back from a PNG', (tester) async {
    const link = 'https://sub.example.com/s/3f9a?name=Travel';
    final text = await tester.runAsync(() async {
      final painter = QrPainter(data: link, version: QrVersions.auto, gapless: true);
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..drawRect(const Rect.fromLTWH(0, 0, 360, 360), Paint()..color = Colors.white);
      canvas.translate(30, 30);
      painter.paint(canvas, const Size(300, 300));
      final image = await recorder.endRecording().toImage(360, 360);
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      image.dispose();
      return decodeQrImage(png);
    });
    expect(text, link);
  });

  testWidgets('an image without a code yields null', (tester) async {
    final text = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 64, 64), Paint()..color = Colors.white);
      final image = await recorder.endRecording().toImage(64, 64);
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
      image.dispose();
      return decodeQrImage(png);
    });
    expect(text, isNull);
  });
}
