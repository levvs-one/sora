import 'dart:async';
import 'dart:ui' as ui;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:zxing2/qrcode.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../desktop/links.dart';
import 'kit.dart';
import 'subscription_sheet.dart';

/// Shows a scannable QR code for [payload] (a subscription or import link).
/// The raw link stays hidden by default: links may carry credentials.
class QrShareScreen extends StatefulWidget {
  const QrShareScreen({super.key, required this.payload, required this.title});

  final String payload;
  final String title;

  @override
  State<QrShareScreen> createState() => _QrShareScreenState();
}

class _QrShareScreenState extends State<QrShareScreen> {
  bool _copied = false;
  int _copiedStamp = 0;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.payload));
    final stamp = ++_copiedStamp;
    if (mounted) setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted && stamp == _copiedStamp) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    final qr = QrCode.fromData(data: widget.payload, errorCorrectLevel: QrErrorCorrectLevel.M);
    // Prefer whole modules, fitting dense codes into the content width so
    // Flutter cannot constrain only one side and distort the quiet zone.
    final moduleSize = (280 / qr.moduleCount).ceilToDouble().clamp(0.0, 360 / (qr.moduleCount + 8));
    final qrSize = (qr.moduleCount + 8) * moduleSize;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: RoundButton(
                  icon: Symbols.chevron_left_rounded,
                  label: MaterialLocalizations.of(context).backButtonTooltip,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
                        child: SizedBox(
                          width: 360,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                style: Styles.bodyStrong.copyWith(fontSize: 17, color: palette.ink),
                              ),
                              const SizedBox(height: 24),
                              Center(
                                child: ExcludeSemantics(
                                  child: QrImageView.withQr(
                                    key: const ValueKey('subscription-qr'),
                                    qr: qr,
                                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                                    size: qrSize,
                                    padding: EdgeInsets.all(4 * moduleSize),
                                    backgroundColor: palette.surface,
                                    eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: palette.ink),
                                    dataModuleStyle: QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: palette.ink,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              PrimaryButton(label: _copied ? s.copied : s.qrCopyLink, onTap: _copy),
                              const SizedBox(height: 12),
                              Text(
                                s.qrWarning,
                                textAlign: TextAlign.center,
                                style: Styles.secondary.copyWith(color: palette.ink2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reads the text of the first QR code in an encoded image (PNG, JPEG, BMP,
/// GIF or WebP), or null when the image holds none.
///
/// Desktop Linux and Windows have no camera plugin worth relying on, and
/// links usually arrive as screenshots from a phone or a messenger, so the
/// scanner works on image files.
Future<String?> decodeQrImage(Uint8List encoded) async {
  final codec = await ui.instantiateImageCodec(encoded);
  final frame = await codec.getNextFrame();
  codec.dispose();
  final image = frame.image;
  final rgba = await image.toByteData();
  final width = image.width, height = image.height;
  image.dispose();
  if (rgba == null) return null;
  // RGBLuminanceSource weighs red and blue equally, so the RGBA byte order
  // read as little-endian words gives the same luminance as ARGB.
  final source = RGBLuminanceSource(width, height, rgba.buffer.asInt32List(rgba.offsetInBytes, width * height));
  for (final bitmap in [
    BinaryBitmap(HybridBinarizer(source)),
    BinaryBitmap(GlobalHistogramBinarizer(source)),
    // Shared codes use the theme's ink and surface, including light ink
    // on dark surfaces. ZXing needs an inverted source for those images.
    BinaryBitmap(HybridBinarizer(source.invert())),
    BinaryBitmap(GlobalHistogramBinarizer(source.invert())),
  ]) {
    try {
      final text = QRCodeReader().decode(bitmap, hints: DecodeHints()..put(DecodeHintType.tryHarder)).text.trim();
      if (text.isNotEmpty) return text;
    } on ReaderException {
      continue;
    } on ArgumentError {
      // ZXing can infer version zero from inverted finder patterns. Try
      // the remaining binarizers rather than abandoning a valid dark QR.
      continue;
    }
  }
  return null;
}

/// Reads a QR code from an image file or accepts a link from the clipboard.
/// The link flows into the existing import pipeline; nothing new is parsed
/// here.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key, this.onScanned});

  /// When set, the raw scanned value is returned through [Navigator.pop]
  /// instead of running the subscription import flow (used by device
  /// pairing).
  final ValueChanged<String>? onScanned;

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _fromImage() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'images', extensions: ['png', 'jpg', 'jpeg', 'bmp', 'gif', 'webp']),
      ],
    );
    if (file == null || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    String? text;
    try {
      text = await decodeQrImage(await file.readAsBytes());
    } on Exception {
      text = null;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (text == null) {
      setState(() => _error = S.of(context).qrNoCode);
      return;
    }
    await _accept(text);
  }

  Future<void> _paste() async {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clip?.text?.trim() ?? '';
    if (text.isEmpty || !mounted) return;
    await _accept(text);
  }

  Future<void> _accept(String raw) async {
    final onScanned = widget.onScanned;
    if (onScanned != null) {
      Navigator.of(context).pop();
      // Let the scan route finish popping before the caller opens sheets.
      unawaited(Future.microtask(() => onScanned(raw)));
      return;
    }
    await _import(raw);
  }

  /// Routes a scanned or pasted link through the standard import flow.
  Future<void> _import(String raw) async {
    final navigator = Navigator.of(context);
    final link = parseImportLink(raw);
    if (link == null) {
      // The share screen encodes the bare subscription URL, so a plain
      // single-line https link is a subscription too.
      if (!raw.contains('\n') &&
          (raw.toLowerCase().startsWith('olcrtc://') ||
              raw.startsWith('https://') && Uri.tryParse(raw)?.host.isNotEmpty == true)) {
        navigator.pop();
        await showSubscriptionSheet(navigator.context, link: raw);
        return;
      }
      if (mounted) setState(() => _error = S.of(context).qrInvalid);
      return;
    }
    switch (link) {
      case AddSubscription(:final url, :final name):
        navigator.pop();
        await showSubscriptionSheet(navigator.context, link: url.toString(), name: name);
      case SealedForHapp():
        navigator.pop();
        final ctx = navigator.context;
        if (ctx.mounted) {
          final s = S.of(ctx);
          await confirm(ctx, question: s.importSealed, action: s.understood, destructive: false, cancellable: false);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    final error = _error;
    return Screen(
      title: s.qrScanTitle,
      children: [
        const SizedBox(height: 24),
        Center(child: Icon(Symbols.qr_code_scanner_rounded, size: 64, color: palette.ink3)),
        const SizedBox(height: 16),
        Text(
          s.qrScanHint,
          textAlign: TextAlign.center,
          style: Styles.body.copyWith(color: palette.ink2),
        ),
        const SizedBox(height: 24),
        PrimaryButton(label: s.qrFromImage, busy: _busy, onTap: _busy ? null : _fromImage),
        const SizedBox(height: 8),
        TextButton(onPressed: _busy ? null : _paste, child: Text(s.qrFromClipboard)),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: Styles.secondary.copyWith(color: palette.ink2),
            ),
          ),
      ],
    );
  }
}
