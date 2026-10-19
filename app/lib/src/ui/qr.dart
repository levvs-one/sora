import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../desktop/links.dart';
import '../sora.dart';
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
  bool _linkVisible = false;
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
    return Screen(
      title: widget.title,
      children: [
        const SizedBox(height: 8),
        Center(
          child: DecoratedBox(
            // White quiet zone keeps the code scannable in both themes.
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: QrImageView(
                data: widget.payload,
                version: QrVersions.auto,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
                size: 260,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Symbols.warning_rounded, size: 18, color: palette.ink2),
            const SizedBox(width: 10),
            Expanded(
              child: Text(s.qrWarning, style: Styles.secondary.copyWith(color: palette.ink2)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PrimaryButton(label: _copied ? s.copied : s.qrCopyLink, onTap: _copy),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _linkVisible = !_linkVisible),
            child: Text(
              _linkVisible ? s.qrHideLink : s.qrShowLink,
              style: Styles.secondary.copyWith(color: palette.ink2),
            ),
          ),
        ),
        if (_linkVisible)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: DecoratedBox(
              decoration: BoxDecoration(color: palette.field, borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  widget.payload,
                  style: Styles.caption.copyWith(color: palette.ink2),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Scans a QR code with the camera, or accepts a link from the clipboard.
/// A scanned link flows into the existing import pipeline; nothing new is
/// parsed here. Without a camera the screen degrades to clipboard import.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final _controller = MobileScannerController();
  bool _handled = false;
  bool _torchOn = false;
  bool _noCamera = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcodes = capture.barcodes;
    final raw = barcodes.isEmpty ? null : barcodes.first.rawValue?.trim();
    if (raw == null || raw.isEmpty) return;
    _handled = true;
    unawaited(_import(raw));
  }

  Future<void> _paste() async {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clip?.text?.trim() ?? '';
    if (text.isEmpty || !mounted) return;
    _handled = true;
    await _import(text);
  }

  /// Routes a scanned or pasted link through the standard import flow.
  Future<void> _import(String raw) async {
    final link = parseImportLink(raw);
    if (link == null) {
      if (mounted) {
        setState(() {
          _error = S.of(context).qrInvalid;
          _handled = false;
        });
      }
      return;
    }
    final navigator = Navigator.of(context);
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

  Future<void> _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (_) {
      // Torch is best-effort; absence is not an error worth surfacing.
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    if (_noCamera) return _fallback(context);
    return Screen(
      title: s.qrScanTitle,
      actions: [
        RoundButton(
          icon: Symbols.flashlight_on_rounded,
          label: s.qrTorch,
          onTap: _toggleTorch,
        ),
      ],
      fill: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
                errorBuilder: (context, error) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_noCamera) setState(() => _noCamera = true);
                  });
                  return _cameraPlaceholder(context);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            s.qrScanHint,
            textAlign: TextAlign.center,
            style: Styles.secondary.copyWith(color: palette.ink2),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Symbols.info_rounded, size: 16, color: palette.ink2),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: Styles.secondary.copyWith(color: palette.ink2),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          PrimaryButton(label: s.qrFromClipboard, onTap: _paste),
          const SizedBox(height: 16),
        ],
      ),
      children: const [],
    );
  }

  Widget _cameraPlaceholder(BuildContext context) {
    final palette = Palette.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(color: palette.field, borderRadius: BorderRadius.circular(20)),
      child: Center(
        child: Icon(Symbols.qr_code_scanner_rounded, size: 64, color: palette.ink3),
      ),
    );
  }

  /// Shown when no camera is available: clipboard import instead of an
  /// empty screen or a raw error.
  Widget _fallback(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    return Screen(
      title: s.qrScanTitle,
      children: [
        const SizedBox(height: 24),
        Center(child: Icon(Symbols.qr_code_scanner_rounded, size: 64, color: palette.ink3)),
        const SizedBox(height: 16),
        Text(
          s.qrNoCamera,
          textAlign: TextAlign.center,
          style: Styles.body.copyWith(color: palette.ink2),
        ),
        const SizedBox(height: 24),
        PrimaryButton(label: s.qrFromClipboard, onTap: _paste),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Symbols.info_rounded, size: 16, color: palette.ink2),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: Styles.secondary.copyWith(color: palette.ink2),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
