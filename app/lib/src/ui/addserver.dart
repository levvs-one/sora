import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../core/link.dart';
import '../design/theme.dart';
import '../generated/sora/custom/v1/custom.pbgrpc.dart';
import '../sora.dart';
import 'kit.dart';

/// Protocols the core can run for a user-added server.
const _protocols = ['vless', 'vmess', 'trojan', 'shadowsocks', 'wireguard', 'hysteria2', 'tuic'];

/// Hostnames, IPv4 and bracketed IPv6: letters, digits and . : - _ [ ].
final _addressPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9.:\-_\[\]]*$');

/// Adds a user-owned server: name, protocol, address, port and optional
/// credentials. The draft can be reachability-tested before saving; the
/// secret stays hidden until the user reveals it, like in QR sharing.
class AddServerScreen extends StatefulWidget {
  const AddServerScreen({super.key});

  @override
  State<AddServerScreen> createState() => _AddServerScreenState();
}

class _AddServerScreenState extends State<AddServerScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _port = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  String _protocol = _protocols.first;
  final _errors = <String, String>{};

  bool _testing = false;
  bool _saving = false;
  ({bool ok, int latencyMs, CoreFailure? failure})? _testResult;
  CoreFailure? _saveFailure;
  bool get _busy => _testing || _saving;

  @override
  void initState() {
    super.initState();
    for (final entry in {'name': _name, 'address': _address, 'port': _port}.entries) {
      entry.value.addListener(() {
        if (_errors.remove(entry.key) != null && mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _port.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Client-side validation; returns true when the draft is sendable.
  bool _validate() {
    final s = S.of(context);
    final errors = <String, String>{};
    if (_name.text.trim().isEmpty) errors['name'] = s.customServerNameRequired;
    final address = _address.text.trim();
    if (address.isEmpty) {
      errors['address'] = s.customServerAddressRequired;
    } else if (!_addressPattern.hasMatch(address)) {
      errors['address'] = s.customServerAddressInvalid;
    }
    final port = int.tryParse(_port.text.trim());
    if (port == null || port < 1 || port > 65535) errors['port'] = s.customServerPortInvalid;
    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
      _testResult = null;
      _saveFailure = null;
    });
    return errors.isEmpty;
  }

  CustomServer _draft() => CustomServer(
    name: _name.text.trim(),
    protocol: _protocol,
    address: _address.text.trim(),
    port: int.parse(_port.text.trim()),
    username: _username.text.trim(),
    // Secrets are verbatim: never trim the password.
    password: _password.text,
  );

  Future<void> _test() async {
    if (_busy || !_validate()) return;
    final sora = SoraScope.read(context);
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final result = await sora.testCustomServer(_draft());
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testResult = result;
    });
  }

  Future<void> _save() async {
    if (_busy || !_validate()) return;
    final sora = SoraScope.read(context);
    setState(() {
      _saving = true;
      _saveFailure = null;
    });
    final failure = await sora.addCustomServer(_draft());
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _saveFailure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    return Screen(
      title: s.customServerAdd,
      children: [
        Group(
          children: [
            _LabeledField(
              label: s.customServerName,
              error: _errors['name'],
              child: TextField(
                controller: _name,
                textInputAction: TextInputAction.next,
                style: Styles.secondary.copyWith(color: palette.ink),
                decoration: _decoration(s.customServerNameHint, palette),
              ),
            ),
            ChoiceTile<String>(
              title: s.customServerProtocol,
              value: _protocol,
              choices: {for (final p in _protocols) p: p.toUpperCase()},
              onChanged: (p) => setState(() => _protocol = p),
            ),
            _LabeledField(
              label: s.customServerAddress,
              error: _errors['address'],
              child: TextField(
                controller: _address,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                style: Styles.secondary.copyWith(color: palette.ink),
                decoration: _decoration(s.customServerAddressHint, palette),
              ),
            ),
            _LabeledField(
              label: s.customServerPort,
              error: _errors['port'],
              child: TextField(
                controller: _port,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: Styles.secondary.copyWith(color: palette.ink),
                decoration: _decoration(s.customServerPortHint, palette),
              ),
            ),
          ],
        ),
        Heading(s.customServerCredentials),
        Group(
          children: [
            _LabeledField(
              label: s.customServerUsername,
              hint: s.customServerOptional,
              child: TextField(
                controller: _username,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                style: Styles.secondary.copyWith(color: palette.ink),
                decoration: _decoration(null, palette),
              ),
            ),
            _SecretField(controller: _password, label: s.customServerPassword, hint: s.customServerOptional),
          ],
        ),
        Group(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: PrimaryButton(
                label: s.customServerTest,
                busy: _testing,
                onTap: _busy ? null : _test,
              ),
            ),
            if (_testing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CupertinoActivityIndicator(color: palette.ink)),
              )
            else if (_testResult != null)
              _testNote(s, _testResult!),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PrimaryButton(
            label: s.save,
            busy: _saving,
            onTap: _busy ? null : _save,
          ),
        ),
        if (_saveFailure != null) _note(context, Symbols.info_rounded, describe(s, _saveFailure!)),
      ],
    );
  }

  /// A neutral note: info, not an error. Failures are localized through
  /// [describe] and never shown raw or in red.
  Widget _testNote(S s, ({bool ok, int latencyMs, CoreFailure? failure}) result) {
    final failure = result.failure;
    if (failure != null) return _note(context, Symbols.info_rounded, describe(s, failure));
    if (result.ok) return _note(context, Symbols.check_rounded, s.customServerTestOk(s.milliseconds(result.latencyMs)));
    return _note(context, Symbols.info_rounded, s.customServerUnreachable);
  }

  Widget _note(BuildContext context, IconData icon, String text) {
    final palette = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: palette.ink2),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Styles.secondary.copyWith(color: palette.ink2))),
        ],
      ),
    );
  }

  InputDecoration _decoration(String? hint, Palette palette) => InputDecoration(
    hintText: hint,
    hintStyle: Styles.secondary.copyWith(color: palette.ink3),
    isDense: true,
    filled: true,
    fillColor: palette.field,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
  );
}

/// A text field with a caption label above and an optional validation error
/// below it.
class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child, this.error, this.hint});

  final String label;
  final Widget child;
  final String? error;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(label, style: Styles.caption.copyWith(color: palette.ink2)),
              if (hint != null) ...[
                const SizedBox(width: 6),
                Text(hint!, style: Styles.caption.copyWith(color: palette.ink3)),
              ],
            ],
          ),
          const SizedBox(height: 6),
          child,
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(error!, style: Styles.caption.copyWith(color: palette.danger)),
            ),
        ],
      ),
    );
  }
}

/// A password field that stays obscured until the user reveals it, like the
/// hidden link in QR sharing.
class _SecretField extends StatefulWidget {
  const _SecretField({required this.controller, required this.label, required this.hint});

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  State<_SecretField> createState() => _SecretFieldState();
}

class _SecretFieldState extends State<_SecretField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final palette = Palette.of(context);
    return _LabeledField(
      label: widget.label,
      hint: widget.hint,
      child: TextField(
        controller: widget.controller,
        obscureText: _hidden,
        enableSuggestions: false,
        autocorrect: false,
        textInputAction: TextInputAction.done,
        style: Styles.secondary.copyWith(color: palette.ink),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: palette.field,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          suffixIcon: Tooltip(
            message: _hidden ? s.customServerShowSecret : s.customServerHideSecret,
            child: Pressable(
              onTap: () => setState(() => _hidden = !_hidden),
              radius: 8,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(
                  _hidden ? Symbols.visibility_rounded : Symbols.visibility_off_rounded,
                  size: 18,
                  color: palette.ink2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
