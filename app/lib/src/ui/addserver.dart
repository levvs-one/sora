import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../core/link.dart';
import '../design/theme.dart';
import '../generated/sora/custom/v1/custom.pbgrpc.dart';
import '../sora.dart';
import 'kit.dart';

/// Protocols the core can run for a user-added server: the full
/// [CustomProtocol] enum minus UNSPECIFIED, which the core rejects.
const _protocols = [
  CustomProtocol.CUSTOM_PROTOCOL_VLESS,
  CustomProtocol.CUSTOM_PROTOCOL_VMESS,
  CustomProtocol.CUSTOM_PROTOCOL_TROJAN,
  CustomProtocol.CUSTOM_PROTOCOL_SHADOWSOCKS,
  CustomProtocol.CUSTOM_PROTOCOL_WIREGUARD,
];

/// Display name for a custom protocol: the generated enum keeps the
/// CUSTOM_PROTOCOL_ prefix, the UI shows the bare name (VLESS, VMESS, ...).
String customProtocolLabel(CustomProtocol protocol) =>
    protocol.name.replaceFirst('CUSTOM_PROTOCOL_', '');

/// Hostnames, IPv4 and bracketed IPv6: letters, digits and . : - _ [ ].
final _addressPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9.:\-_\[\]]*$');

/// Adds a user-owned server: name, protocol, address, port and an optional
/// write-only secret (UUID, password, key — the core never returns it).
/// Reachability is tested from the servers list after saving: the core API
/// tests only saved servers, by id, so there is no pre-save test here.
class AddServerScreen extends StatefulWidget {
  const AddServerScreen({super.key});

  @override
  State<AddServerScreen> createState() => _AddServerScreenState();
}

class _AddServerScreenState extends State<AddServerScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _port = TextEditingController();
  final _credentials = TextEditingController();

  CustomProtocol _protocol = _protocols.first;
  final _errors = <String, String>{};

  bool _saving = false;
  CoreFailure? _saveFailure;

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
    _credentials.dispose();
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
      _saveFailure = null;
    });
    return errors.isEmpty;
  }

  CustomServer _draft() => CustomServer(
    name: _name.text.trim(),
    protocol: _protocol,
    address: _address.text.trim(),
    port: int.parse(_port.text.trim()),
    // Secrets are verbatim: never trim the credentials.
    credentials: _credentials.text,
  );

  Future<void> _save() async {
    if (_saving || !_validate()) return;
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
            ChoiceTile<CustomProtocol>(
              title: s.customServerProtocol,
              value: _protocol,
              choices: {for (final p in _protocols) p: customProtocolLabel(p)},
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
        Group(
          children: [
            _SecretField(
              controller: _credentials,
              label: s.customServerCredentials,
              hint: s.customServerOptional,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PrimaryButton(
            label: s.save,
            busy: _saving,
            onTap: _saving ? null : _save,
          ),
        ),
        if (_saveFailure != null) _note(context, Symbols.info_rounded, describe(s, _saveFailure!)),
      ],
    );
  }

  /// A neutral note: info, not an error. Failures are localized through
  /// [describe] and never shown raw or in red.
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
              child: Text(error!, style: Styles.dangerCaption(context)),
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
