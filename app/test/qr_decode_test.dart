import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sora/src/ui/qr.dart';
import 'package:sora/l10n/strings.dart';
import 'package:sora/src/design/theme.dart';

/// The share screen draws a link with qr_flutter; the scan screen must read
/// the same code back from a screenshot of it.
void main() {
  testWidgets('a shared QR code reads back from a PNG', (tester) async {
    for (final link in [
      'https://sub.example.com/s/3f9a?name=Travel',
      'mieru://CjoKCUNvbW11bml0eRIZCgVhbGljZRIQcHJpdmF0ZS1wYXNzd29yZBoSCgkxMjcuMC4wLjEaBQi7AxAC',
      'mierus://alice:password@example.com?profile=Community&port=443&protocol=TCP',
      'naive+https://alice:password@example.com:443/#Community',
      'naive+quic://alice:password@example.com:443/#Community',
      'olcrtc://jitsi?datachannel@https://meet.example.org/myroom#'
          'd823fa01cb3e0609b67322f7cf984c4ee2e4ce2e294936fc24ef38c9e59f4799'
          r'$RU / olc free sub',
    ]) {
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
    }
  });

  for (final brightness in Brightness.values) {
    for (final length in [40, 600]) {
      testWidgets('$length character URL decodes from the real $brightness share widget', (tester) async {
        const prefix = 'https://sub.example.com/s/';
        final link = '$prefix${List.filled(length - prefix.length, 'x').join()}';
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
          return null;
        });
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null),
        );
        final capture = GlobalKey();
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(420, 800);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            theme: buildTheme(brightness),
            locale: const Locale('en'),
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: RepaintBoundary(
              key: capture,
              child: QrShareScreen(payload: link, title: 'Travel'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final code = find.byKey(const ValueKey('subscription-qr'));
        expect(tester.getSize(code).shortestSide, greaterThanOrEqualTo(280));
        final widget = tester.widget<QrImageView>(code);
        expect(tester.getSize(code), Size(widget.size!, widget.size!));
        expect(widget.errorCorrectionLevel, QrErrorCorrectLevel.M);
        final qr = QrCode.fromData(data: link, errorCorrectLevel: QrErrorCorrectLevel.M);
        expect(widget.padding.left / (widget.size! - widget.padding.horizontal) * qr.moduleCount, closeTo(4, 0.001));
        expect(widget.backgroundColor, brightness == Brightness.light ? Palette.light.surface : Palette.dark.surface);
        expect(find.text('Travel'), findsOneWidget);
        final boundary = capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final decoded = await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          try {
            final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
            return await decodeQrImage(bytes);
          } finally {
            image.dispose();
          }
        });
        expect(decoded, link);
        await tester.tap(find.text('Copy link'));
        await tester.pump();
        expect(copied, link);
        expect(find.text('Copied'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 1500));
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

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
