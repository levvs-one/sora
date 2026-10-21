import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../core/link.dart';
import '../design/theme.dart';
import '../generated/sora/custom/v1/custom.pbgrpc.dart';
import '../sora.dart';
import 'kit.dart';

const _protocols = [
  CustomProtocol.CUSTOM_PROTOCOL_VLESS,
  CustomProtocol.CUSTOM_PROTOCOL_VMESS,
  CustomProtocol.CUSTOM_PROTOCOL_TROJAN,
  CustomProtocol.CUSTOM_PROTOCOL_SHADOWSOCKS,
  CustomProtocol.CUSTOM_PROTOCOL_WIREGUARD,
];

/// A WireGuard key: 32 bytes in standard base64, as `wg genkey` prints.
bool isWireGuardKey(String key) {
  try {
    return base64.decode(key.trim()).length == 32;
  } on FormatException {
    return false;
  }
}

/// An IPv4 or IPv6 prefix such as 10.0.0.2/32 or ::/0.
bool isCidr(String value) {
  final parts = value.trim().split('/');
  if (parts.length != 2) return false;
  final address = InternetAddress.tryParse(parts[0]);
  final bits = int.tryParse(parts[1]);
  if (address == null || bits == null) return false;
  return bits >= 0 && bits <= (address.type == InternetAddressType.IPv6 ? 128 : 32);
}

List<String> _list(String text) => [
  for (final part in text.split(','))
    if (part.trim().isNotEmpty) part.trim(),
];

/// The WireGuard part of a hand-added server: the interface addresses and
/// the server's peer entry. The peer endpoint is the server address and
/// port, which the core fills in when it plans the connection.
typedef WireGuardInput = ({String addresses, String peerKey, String presharedKey, String allowedIps, String keepalive});

/// Which WireGuard field is wrong, or null when [privateKey] and [wg] make
/// a usable document.
String? wireGuardProblem(String privateKey, WireGuardInput wg) {
  if (!isWireGuardKey(privateKey)) return 'credentials';
  final addresses = _list(wg.addresses);
  if (addresses.isEmpty || !addresses.every(isCidr)) return 'addresses';
  if (!isWireGuardKey(wg.peerKey)) return 'peerKey';
  if (wg.presharedKey.trim().isNotEmpty && !isWireGuardKey(wg.presharedKey)) return 'presharedKey';
  final allowed = _list(wg.allowedIps);
  if (allowed.isEmpty || !allowed.every(isCidr)) return 'allowedIps';
  final keepalive = wg.keepalive.trim();
  if (keepalive.isNotEmpty) {
    final seconds = int.tryParse(keepalive);
    if (seconds == null || seconds < 0 || seconds > 65535) return 'keepalive';
  }
  return null;
}

/// Builds the credential document the core stores in its vault and reads
/// back when it plans a connection (core/control credentialDocument). An
/// empty secret stores nothing; null means the input does not fit the
/// protocol (Shadowsocks needs `method:password`, WireGuard needs [wg]).
String? customCredentialDocument(CustomProtocol protocol, String secret, {WireGuardInput? wg}) {
  if (protocol == CustomProtocol.CUSTOM_PROTOCOL_WIREGUARD) {
    if (wg == null || wireGuardProblem(secret, wg) != null) return null;
    final keepalive = int.tryParse(wg.keepalive.trim()) ?? 0;
    return jsonEncode({
      'private_key': secret.trim(),
      'addresses': _list(wg.addresses).join(','),
      // The core reads peers as JSON of engine.WireGuardPeer.
      'peers': jsonEncode([
        {
          'PublicKey': wg.peerKey.trim(),
          if (wg.presharedKey.trim().isNotEmpty) 'PreSharedKey': wg.presharedKey.trim(),
          'AllowedIPs': _list(wg.allowedIps),
          if (keepalive > 0) 'PersistentKeepalive': keepalive,
        },
      ]),
    });
  }
  if (secret.isEmpty) return '';
  switch (protocol) {
    case CustomProtocol.CUSTOM_PROTOCOL_VLESS:
    case CustomProtocol.CUSTOM_PROTOCOL_VMESS:
      return jsonEncode({'uuid': secret});
    case CustomProtocol.CUSTOM_PROTOCOL_TROJAN:
      return jsonEncode({'password': secret});
    case CustomProtocol.CUSTOM_PROTOCOL_SHADOWSOCKS:
      final colon = secret.indexOf(':');
      if (colon <= 0 || colon == secret.length - 1) return null;
      return jsonEncode({'method': secret.substring(0, colon), 'password': secret.substring(colon + 1)});
    default:
      return null;
  }
}

/// Display name for a custom protocol: the generated enum keeps the
/// CUSTOM_PROTOCOL_ prefix, the UI shows the bare name (VLESS, VMESS, ...).
String customProtocolLabel(CustomProtocol protocol) => protocol.name.replaceFirst('CUSTOM_PROTOCOL_', '');

/// Hostnames, IPv4 and bracketed IPv6: letters, digits and . : - _ [ ].
final _addressPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9.:\-_\[\]]*$');

/// Adds a user-owned server: name, protocol, address, port and an optional
/// write-only secret (UUID, password or key; the core never returns it).
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
  final _wgAddresses = TextEditingController();
  final _wgPeerKey = TextEditingController();
  final _wgPresharedKey = TextEditingController();
  final _wgAllowedIps = TextEditingController(text: '0.0.0.0/0, ::/0');
  final _wgKeepalive = TextEditingController();

  bool get _wireGuard => _protocol == CustomProtocol.CUSTOM_PROTOCOL_WIREGUARD;

  WireGuardInput get _wg => (
    addresses: _wgAddresses.text,
    peerKey: _wgPeerKey.text,
    presharedKey: _wgPresharedKey.text,
    allowedIps: _wgAllowedIps.text,
    keepalive: _wgKeepalive.text,
  );

  CustomProtocol _protocol = _protocols.first;
  final _errors = <String, String>{};

  bool _saving = false;
  CoreFailure? _saveFailure;

  @override
  void initState() {
    super.initState();
    for (final entry in {
      'name': _name,
      'address': _address,
      'port': _port,
      'credentials': _credentials,
      'addresses': _wgAddresses,
      'peerKey': _wgPeerKey,
      'presharedKey': _wgPresharedKey,
      'allowedIps': _wgAllowedIps,
      'keepalive': _wgKeepalive,
    }.entries) {
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
    for (final c in [_wgAddresses, _wgPeerKey, _wgPresharedKey, _wgAllowedIps, _wgKeepalive]) {
      c.dispose();
    }
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
    if (_wireGuard) {
      final field = wireGuardProblem(_credentials.text, _wg);
      if (field != null) {
        errors[field] = switch (field) {
          'addresses' || 'allowedIps' => s.customServerWgCidrInvalid,
          'keepalive' => s.customServerWgKeepaliveInvalid,
          _ => s.customServerWgKeyInvalid,
        };
      }
    } else if (customCredentialDocument(_protocol, _credentials.text) == null) {
      errors['credentials'] = s.customServerShadowsocksCredentials;
    }
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
    credentials: customCredentialDocument(_protocol, _credentials.text, wg: _wg)!,
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
              label: _wireGuard ? s.customServerWgPrivateKey : s.customServerCredentials,
              hint: _wireGuard
                  ? ''
                  : _protocol == CustomProtocol.CUSTOM_PROTOCOL_SHADOWSOCKS
                  ? s.customServerShadowsocksCredentials
                  : s.customServerOptional,
              error: _errors['credentials'],
            ),
          ],
        ),
        if (_wireGuard)
          Group(
            children: [
              _plainField(s.customServerWgAddresses, _wgAddresses, 'addresses', hint: '10.0.0.2/32, fd00::2/128'),
              _plainField(s.customServerWgPeerKey, _wgPeerKey, 'peerKey'),
              _SecretField(
                controller: _wgPresharedKey,
                label: s.customServerWgPresharedKey,
                hint: s.customServerOptional,
                error: _errors['presharedKey'],
              ),
              _plainField(s.customServerWgAllowedIps, _wgAllowedIps, 'allowedIps'),
              _plainField(
                s.customServerWgKeepalive,
                _wgKeepalive,
                'keepalive',
                hint: '25',
                label2: s.customServerOptional,
                digits: true,
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PrimaryButton(label: s.save, busy: _saving, onTap: _saving ? null : _save),
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
          Expanded(
            child: Text(text, style: Styles.secondary.copyWith(color: palette.ink2)),
          ),
        ],
      ),
    );
  }

  Widget _plainField(
    String label,
    TextEditingController controller,
    String key, {
    String? hint,
    String? label2,
    bool digits = false,
  }) {
    final palette = Palette.of(context);
    return _LabeledField(
      label: label,
      hint: label2,
      error: _errors[key],
      child: TextField(
        controller: controller,
        autocorrect: false,
        enableSuggestions: false,
        keyboardType: digits ? TextInputType.number : TextInputType.text,
        inputFormatters: digits ? [FilteringTextInputFormatter.digitsOnly] : null,
        textInputAction: TextInputAction.next,
        style: Styles.secondary.copyWith(color: palette.ink),
        decoration: _decoration(hint, palette),
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
              if (hint != null && hint!.isNotEmpty) ...[
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
  const _SecretField({required this.controller, required this.label, required this.hint, this.error});

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? error;

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
      error: widget.error,
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
