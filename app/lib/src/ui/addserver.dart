import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../core/link.dart';
import '../design/theme.dart';
import '../generated/sora/custom/v1/custom.pbgrpc.dart';
import '../sora.dart';
import '../notifications.dart';
import 'kit.dart';

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

String customServerProtocol(CustomServer server) =>
    server.protocolName.isNotEmpty ? server.protocolName : customProtocolLabel(server.protocol).toLowerCase();

Future<void> showAddServerSheet(BuildContext context, {CustomServer? server}) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: Palette.of(context).scrim,
  transitionDuration: Duration.zero,
  pageBuilder: (_, _, _) => AddServerScreen(server: server),
);

class AddServerScreen extends StatefulWidget {
  const AddServerScreen({super.key, this.server});

  final CustomServer? server;

  @override
  State<AddServerScreen> createState() => _AddServerScreenState();
}

class _AddServerScreenState extends State<AddServerScreen> {
  final _fields = <String, TextEditingController>{
    for (final key in [
      'name',
      'address',
      'port',
      'credentials',
      'method',
      'user',
      'password',
      'addresses',
      'peerKey',
      'presharedKey',
      'allowedIps',
      'keepalive',
      'server_name',
      'fingerprint',
      'public_key',
      'short_id',
      'spider_x',
      'path',
      'host_header',
      'service_name',
      'mode',
      'alpn',
      'flow',
      'encryption',
      'obfs_param',
      'port_range',
    ])
      key: TextEditingController(),
  };
  final _touched = <String>{};
  final _revealed = <String>{};
  Map<String, String> _material = {};
  late String _protocol;
  String _transport = '', _security = '';
  bool _saving = false, _pasting = false, _filling = false, _peer = false;
  bool get _wireGuard => _protocol == 'wireguard';
  bool get _stream => ['vless', 'vmess', 'trojan'].contains(_protocol);
  bool get _manual => [
    'vless',
    'vmess',
    'trojan',
    'shadowsocks',
    'wireguard',
    'socks5',
    'http',
    'hysteria2',
    'tuic',
    'anytls',
    'mieru',
    'naive',
  ].contains(_protocol);
  bool get _webPath => ['ws', 'h2', 'httpupgrade', 'xhttp'].contains(_transport);
  Iterable<String> get _options => [
    if (_stream && _webPath) ...['path', 'host_header'],
    if (_stream && _transport == 'grpc') 'service_name',
    if (_stream && _transport == 'xhttp') 'mode',
    if (_protocol == 'vless') ...[if (_transport == 'tcp' && _security != 'none') 'flow', 'encryption'],
    if (_security != 'none' && _security.isNotEmpty) ...[
      'server_name',
      if (_protocol != 'naive') 'alpn',
      if (_stream || ['socks5', 'http'].contains(_protocol)) 'fingerprint',
      if (_security == 'reality') ...['public_key', 'short_id', 'spider_x'],
    ],
    if (_protocol == 'hysteria2') 'obfs_param',
    if (_protocol == 'mieru' && !_keepStored) 'port_range',
  ];
  String get _defaultSecurity =>
      ['shadowsocks', 'wireguard', 'socks5', 'http', 'mieru'].contains(_protocol) ? 'none' : 'tls';
  String get _defaultTransport => ['wireguard', 'hysteria2', 'tuic'].contains(_protocol) ? 'udp' : 'tcp';
  bool get _keepStored =>
      widget.server != null && _protocol == customServerProtocol(widget.server!) && _material.isEmpty;
  bool get _nextPeer =>
      _wireGuard &&
      !_peer &&
      _material.isEmpty &&
      (!_keepStored ||
          ['credentials', 'addresses', 'peerKey', 'presharedKey', 'allowedIps', 'keepalive'].any(_touched.contains));
  bool get _busy => _saving || _pasting;
  String _text(String key) => _fields[key]!.text;
  WireGuardInput get _wg => (
    addresses: _text('addresses'),
    peerKey: _text('peerKey'),
    presharedKey: _text('presharedKey'),
    allowedIps: _text('allowedIps'),
    keepalive: _text('keepalive'),
  );

  @override
  void initState() {
    super.initState();
    final server = widget.server;
    _protocol = server == null ? 'vless' : customServerProtocol(server);
    _fields['name']!.text = server?.name ?? '';
    _fields['address']!.text = server?.address ?? '';
    _fields['port']!.text = server == null ? '' : '${server.port}';
    _transport = server?.transport.isNotEmpty == true ? server!.transport : _defaultTransport;
    _security = server?.security.isNotEmpty == true ? server!.security : _defaultSecurity;
    _fields['allowedIps']!.text = '0.0.0.0/0, ::/0';
    for (final entry in _fields.entries) {
      entry.value.addListener(() {
        if (_filling) return;
        setState(() => _touched.add(entry.key));
      });
    }
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Map<String, String> _problems() {
    final s = S.of(context);
    final errors = <String, String>{};
    if (_text('name').trim().isEmpty) errors['name'] = s.customServerNameRequired;
    final address = _text('address').trim();
    if (address.isEmpty) {
      errors['address'] = s.customServerAddressRequired;
    } else if (!_addressPattern.hasMatch(address) && InternetAddress.tryParse(address) == null) {
      errors['address'] = s.customServerAddressInvalid;
    }
    final port = int.tryParse(_text('port').trim());
    if (port == null || port < 1 || port > 65535) errors['port'] = s.customServerPortInvalid;
    if (_wireGuard) {
      final replacing =
          !_keepStored ||
          ['credentials', 'addresses', 'peerKey', 'presharedKey', 'allowedIps', 'keepalive'].any(_touched.contains);
      if (replacing) {
        final field = wireGuardProblem(_text('credentials'), _wg);
        if (field != null) {
          errors[field] = switch (field) {
            'addresses' || 'allowedIps' => s.customServerWgCidrInvalid,
            'keepalive' => s.customServerWgKeepaliveInvalid,
            _ => s.customServerWgKeyInvalid,
          };
        }
      }
    } else if (!_keepStored) {
      if (!_manual && _material.isEmpty) errors['credentials'] = s.customServerLinkInvalid;
      if (_manual && _text('credentials').isEmpty && !['http', 'socks5', 'naive'].contains(_protocol)) {
        errors['credentials'] = s.customServerSecretRequired;
      }
      if (_protocol == 'shadowsocks' && _text('method').trim().isEmpty) errors['method'] = s.customServerSecretRequired;
      if (_protocol == 'tuic' && _text('password').isEmpty) errors['password'] = s.customServerSecretRequired;
      if (_protocol == 'mieru' && _text('user').isEmpty) errors['user'] = s.customServerSecretRequired;
    }
    if (_security == 'reality' && (!_keepStored || _touched.contains('security')) && _text('public_key').isEmpty) {
      errors['public_key'] = s.customServerSecretRequired;
    }
    return errors;
  }

  Future<void> _paste() async {
    if (_busy) return;
    setState(() {
      _pasting = true;
    });
    final sora = SoraScope.read(context);
    sora.recovered('custom-paste');
    try {
      final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
      final answer = await sora.previewCustomServer(clipboard?.text ?? '');
      if (!mounted) return;
      final server = answer.server;
      final material = (jsonDecode(answer.credentialDocument) as Map<String, dynamic>).cast<String, String>();
      final peers = material['peers'] == null ? <dynamic>[] : jsonDecode(material['peers']!) as List;
      final peer = peers.isEmpty ? <String, dynamic>{} : peers.first as Map<String, dynamic>;
      _filling = true;
      for (final field in _fields.values) {
        field.clear();
      }
      _fields['name']!.text = server.name;
      _fields['address']!.text = server.address;
      _fields['port']!.text = '${server.port}';
      _protocol = customServerProtocol(server);
      _peer = false;
      _transport = server.transport.isEmpty ? _defaultTransport : server.transport;
      _security = server.security.isEmpty ? _defaultSecurity : server.security;
      _material = material;
      _fields['credentials']!.text =
          material[_wireGuard
              ? 'private_key'
              : ['vless', 'vmess', 'tuic'].contains(_protocol)
              ? 'uuid'
              : 'password'] ??
          '';
      for (final key in ['method', 'user', 'password', 'addresses', ..._options]) {
        _fields[key]!.text = material[key] ?? '';
      }
      if (_protocol == 'mieru' && material['mieru'] != null) {
        _fields['port_range']!.text = (jsonDecode(material['mieru']!) as Map)['PortRange'] as String? ?? '';
      }
      _fields['peerKey']!.text = peer['PublicKey'] as String? ?? '';
      _fields['presharedKey']!.text = peer['PreSharedKey'] as String? ?? '';
      _fields['allowedIps']!.text = (peer['AllowedIPs'] as List? ?? ['0.0.0.0/0', '::/0']).join(', ');
      _fields['keepalive']!.text = peer['PersistentKeepalive']?.toString() ?? '';
      _touched.clear();
      _revealed.clear();
    } catch (error) {
      if (!mounted) return;
      final failure = CoreFailure.from(error);
      if (failure.key.startsWith('core.subscription.') || failure.key == 'core.request.invalid') {
        unawaited(
          sora.recordNotification(
            AppNotification(
              time: DateTime.now(),
              title: S.of(context).customServerOwn,
              body: S.of(context).customServerLinkInvalid,
              failureKey: 'form.custom.invalid_link',
            ),
          ),
        );
      } else {
        sora.reportFailure(error, source: 'custom-paste', mode: FailureMode.action);
      }
    } finally {
      _filling = false;
      if (mounted) setState(() => _pasting = false);
    }
  }

  String _document() {
    if (!_manual && _material.isNotEmpty) return jsonEncode(_material);
    if (_keepStored && !_touched.any((key) => !['name', 'address', 'port'].contains(key))) return '';
    final values = {..._material};
    void put(String field, String key) {
      if (!_keepStored || (_touched.contains(field) && _text(field).isNotEmpty)) values[key] = _text(field);
    }

    if (_wireGuard) {
      final wg = jsonDecode(
        customCredentialDocument(CustomProtocol.CUSTOM_PROTOCOL_WIREGUARD, _text('credentials'), wg: _wg)!,
      ) as Map<String, dynamic>;
      // Preserve additional imported peers and Amnezia options while editing
      // the first peer exposed by this form.
      final peers = values['peers'] == null ? <dynamic>[] : jsonDecode(values['peers']!) as List;
      final first = (jsonDecode(wg['peers'] as String) as List).single as Map<String, dynamic>;
      if (peers.isEmpty) {
        peers.add(first);
      } else {
        peers[0] = {...peers.first as Map, ...first};
      }
      final peer = peers.first as Map;
      peer.remove('Endpoint');
      if (_text('presharedKey').trim().isEmpty) peer.remove('PreSharedKey');
      if ((int.tryParse(_text('keepalive').trim()) ?? 0) == 0) peer.remove('PersistentKeepalive');
      values.addAll({
        'private_key': wg['private_key'] as String,
        'addresses': wg['addresses'] as String,
        'peers': jsonEncode(peers),
      });
    } else {
      put('credentials', ['vless', 'vmess', 'tuic'].contains(_protocol) ? 'uuid' : 'password');
      if (_protocol == 'shadowsocks') put('method', 'method');
      if (['socks5', 'http', 'mieru', 'naive'].contains(_protocol)) put('user', 'user');
      if (_protocol == 'tuic') put('password', 'password');
    }
    for (final field in _options) {
      if (!_keepStored || _touched.contains(field)) {
        values[field] = field == 'obfs_param' ? _text(field) : _text(field).trim();
      }
    }
    if (!_keepStored || _touched.contains('security')) values['security'] = _security;
    if ((_touched.contains('transport') && _transport != 'tcp') ||
        (_touched.contains('security') && _security == 'none')) {
      values['flow'] = '';
    }
    if (_protocol == 'hysteria2' && (!_keepStored || _touched.contains('obfs_param'))) {
      values['obfs'] = _text('obfs_param').isEmpty ? '' : 'salamander';
    }
    // Native option blobs are write-only; flat edits must not replace unseen settings.
    if (_protocol == 'mieru' && !_keepStored) {
      final native = values['mieru'] == null
          ? <String, dynamic>{}
          : jsonDecode(values['mieru']!) as Map<String, dynamic>;
      if (!_keepStored || _touched.contains('port_range')) native['PortRange'] = _text('port_range').trim();
      values['mieru'] = jsonEncode(native);
      values.remove('port_range');
    }
    if (_protocol == 'naive' && !_keepStored) {
      final native = values['naive'] == null
          ? <String, dynamic>{}
          : jsonDecode(values['naive']!) as Map<String, dynamic>;
      native['QUIC'] = _transport == 'udp';
      values['naive'] = jsonEncode(native);
    }
    return jsonEncode(values);
  }

  Future<void> _save() async {
    if (_busy) return;
    final errors = _problems();
    if (errors.isNotEmpty) {
      setState(() => _touched.addAll(errors.keys));
      unawaited(
        SoraScope.read(context).recordNotification(
          AppNotification(time: DateTime.now(), title: S.of(context).customServerOwn, body: errors.values.first),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final draft = CustomServer(
      id: widget.server?.id,
      name: _text('name').trim(),
      protocolName: _protocol,
      protocol: CustomProtocol.values.firstWhere(
        (p) => customProtocolLabel(p).toLowerCase() == _protocol,
        orElse: () => CustomProtocol.CUSTOM_PROTOCOL_UNSPECIFIED,
      ),
      address: _text('address').trim(),
      port: int.parse(_text('port').trim()),
      transport: _transport,
      security: _security,
      credentials: _document(),
    );
    final failure = await SoraScope.read(context).addCustomServer(draft, replaceCredentials: _material.isNotEmpty);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  void _changeProtocol(String value) {
    if (_busy || value == _protocol) return;
    _filling = true;
    for (final entry in _fields.entries) {
      if (!['name', 'address', 'port'].contains(entry.key)) entry.value.clear();
    }
    _fields['allowedIps']!.text = '0.0.0.0/0, ::/0';
    _filling = false;
    setState(() {
      _protocol = value;
      _peer = false;
      _material = {};
      final original = widget.server;
      final restoring = original != null && customServerProtocol(original) == value;
      _transport = restoring && original.transport.isNotEmpty ? original.transport : _defaultTransport;
      _security = restoring && original.security.isNotEmpty ? original.security : _defaultSecurity;
      _touched.removeWhere((key) => !['name', 'address', 'port'].contains(key));
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context), palette = Palette.of(context);
    final problems = _problems();
    final protocols = {...SoraScope.of(context).customProtocols, _protocol};
    final style = Styles.body.copyWith(color: palette.ink);
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop()},
      child: Focus(
        autofocus: true,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
            child: Center(
              child: SizedBox(
                width: 520,
                child: Material(
                  key: const ValueKey('custom-server-sheet'),
                  color: palette.background,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.server == null ? s.customServerOwn : s.edit,
                                style: Styles.heading.copyWith(color: palette.ink),
                              ),
                            ),
                            RoundButton(
                              icon: Symbols.close_rounded,
                              label: s.cancel,
                              onTap: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextButton.icon(
                                key: const ValueKey('custom-paste'),
                                onPressed: _busy ? null : _paste,
                                style: TextButton.styleFrom(
                                  foregroundColor: palette.ink,
                                  minimumSize: const Size(double.infinity, 48),
                                  backgroundColor: palette.surface,
                                  alignment: AlignmentDirectional.centerStart,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: _pasting
                                    ? const CupertinoActivityIndicator(radius: 8)
                                    : const Icon(Symbols.content_paste_rounded, size: 20),
                                label: Text(s.customServerPaste, style: style),
                              ),
                              const SizedBox(height: 16),
                              Group(
                                children: [
                                  ChoiceTile<String>(
                                    key: const ValueKey('custom-protocol'),
                                    title: s.customServerProtocol,
                                    value: _protocol,
                                    choices: {for (final p in protocols) p: p.toUpperCase()},
                                    onChanged: _changeProtocol,
                                  ),
                                  _field('name', s.customServerName),
                                  _field('address', s.customServerAddress),
                                  _field('port', s.customServerPort, digits: true),
                                ],
                              ),
                              if (_manual) ...[
                                Heading(
                                  _wireGuard
                                      ? 'WireGuard'
                                      : '${_protocol.toUpperCase()} · ${s.customServerCredentials}',
                                ),
                                if (_wireGuard)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Segments<bool>(
                                      key: const ValueKey('custom-wg-section'),
                                      value: _peer,
                                      choices: {false: s.customServerWgInterface, true: s.customServerWgPeer},
                                      onChanged: (v) {
                                        if (!_busy) setState(() => _peer = v);
                                      },
                                    ),
                                  ),
                                if (!_wireGuard || !_peer)
                                  Group(
                                    children: [
                                      if (['socks5', 'http', 'mieru', 'naive'].contains(_protocol))
                                        _field(
                                          'user',
                                          s.customServerUser,
                                          info: _protocol == 'mieru' ? null : s.customServerOptional,
                                        ),
                                      if (_protocol == 'shadowsocks') _field('method', s.customServerCipher),
                                      _field(
                                        'credentials',
                                        _wireGuard
                                            ? s.customServerWgPrivateKey
                                            : ['vless', 'vmess', 'tuic'].contains(_protocol)
                                            ? 'UUID'
                                            : s.customServerPassword,
                                        secret: true,
                                        info: _keepStored
                                            ? s.customServerOptional
                                            : _wireGuard
                                            ? s.customServerWgKeyInvalid
                                            : null,
                                      ),
                                      if (_protocol == 'tuic') _field('password', s.customServerPassword, secret: true),
                                      if (_wireGuard)
                                        _field(
                                          'addresses',
                                          s.customServerWgAddresses,
                                          info: s.customServerWgCidrInvalid,
                                        ),
                                    ],
                                  ),
                                if (_wireGuard && _peer)
                                  Group(
                                    children: [
                                      _field('peerKey', s.customServerWgPeerKey, info: s.customServerWgKeyInvalid),
                                      _field(
                                        'allowedIps',
                                        s.customServerWgAllowedIps,
                                        info: s.customServerWgCidrInvalid,
                                      ),
                                      ExpansionTile(
                                        key: const ValueKey('custom-wg-peer-options'),
                                        title: Text(
                                          s.customServerOptions,
                                          style: Styles.body.copyWith(color: palette.ink),
                                        ),
                                        enabled: !_busy,
                                        minTileHeight: 48,
                                        iconColor: palette.ink,
                                        collapsedIconColor: palette.ink,
                                        shape: const Border(),
                                        collapsedShape: const Border(),
                                        expansionAnimationStyle: AnimationStyle(
                                          duration: Motion.of(context, const Duration(milliseconds: 180)),
                                        ),
                                        children: [
                                          _field(
                                            'presharedKey',
                                            s.customServerWgPresharedKey,
                                            secret: true,
                                            info: '${s.customServerOptional}. ${s.customServerWgKeyInvalid}',
                                          ),
                                          _field(
                                            'keepalive',
                                            s.customServerWgKeepalive,
                                            digits: true,
                                            info: '${s.customServerOptional}. ${s.customServerWgKeepaliveInvalid}',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                if (!_wireGuard && _protocol != 'shadowsocks')
                                  Group(
                                    children: [
                                      ExpansionTile(
                                        key: ValueKey('custom-options-$_protocol'),
                                        title: Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                s.customServerOptions,
                                                style: Styles.body.copyWith(color: palette.ink),
                                              ),
                                            ),
                                            InfoButton(
                                              title: s.customServerOptions,
                                              description: s.customServerOptionsInfo,
                                            ),
                                          ],
                                        ),
                                        enabled: !_busy,
                                        minTileHeight: 48,
                                        textColor: palette.ink,
                                        collapsedTextColor: palette.ink,
                                        iconColor: palette.ink,
                                        collapsedIconColor: palette.ink,
                                        shape: const Border(),
                                        collapsedShape: const Border(),
                                        expansionAnimationStyle: AnimationStyle(
                                          duration: Motion.of(context, const Duration(milliseconds: 180)),
                                        ),
                                        children: [
                                          if (_stream || _protocol == 'mieru' || (_protocol == 'naive' && !_keepStored))
                                            ChoiceTile<String>(
                                              key: const ValueKey('custom-transport'),
                                              title: s.customServerTransport,
                                              value: _transport,
                                              choices: {
                                                for (final v
                                                    in _stream
                                                        ? ['tcp', 'ws', 'grpc', 'h2', 'httpupgrade', 'xhttp']
                                                        : ['tcp', 'udp'])
                                                  v: v.toUpperCase(),
                                              },
                                              onChanged: (v) {
                                                if (_busy) return;
                                                setState(() {
                                                  _transport = v;
                                                  _touched.add('transport');
                                                });
                                              },
                                            ),
                                          if (_stream || ['socks5', 'http'].contains(_protocol))
                                            ChoiceTile<String>(
                                              key: const ValueKey('custom-security'),
                                              title: s.customServerSecurity,
                                              value: _security,
                                              choices: {
                                                'none': s.tlsRecordNo,
                                                'tls': 'TLS',
                                                if (_protocol == 'vless') 'reality': 'REALITY',
                                              },
                                              onChanged: (v) {
                                                if (_busy) return;
                                                setState(() {
                                                  _security = v;
                                                  _touched.add('security');
                                                });
                                              },
                                            ),
                                          for (final key in _options)
                                            if (key == 'mode')
                                              ChoiceTile<String>(
                                                key: const ValueKey('custom-mode'),
                                                title: 'XHTTP · mode',
                                                value: _text('mode'),
                                                choices: {
                                                  '': s.engineAuto,
                                                  'auto': 'auto',
                                                  'packet-up': 'packet-up',
                                                  'stream-up': 'stream-up',
                                                  'stream-one': 'stream-one',
                                                  if (![
                                                    '',
                                                    'auto',
                                                    'packet-up',
                                                    'stream-up',
                                                    'stream-one',
                                                  ].contains(_text('mode')))
                                                    _text('mode'): _text('mode'),
                                                },
                                                onChanged: (v) {
                                                  if (!_busy) _fields['mode']!.text = v;
                                                },
                                              )
                                            else
                                              _field(
                                                key,
                                                switch (key) {
                                                  'server_name' => 'SNI',
                                                  'fingerprint' => 'uTLS',
                                                  'alpn' => 'ALPN',
                                                  'public_key' => 'REALITY · ${s.customServerWgPeerKey}',
                                                  'short_id' => 'REALITY · Short ID',
                                                  'spider_x' => 'REALITY · SpiderX',
                                                  'path' => 'Path',
                                                  'host_header' => 'HTTP Host',
                                                  'service_name' => 'gRPC · serviceName',
                                                  'mode' => 'XHTTP · mode',
                                                  'flow' => 'VLESS · flow',
                                                  'encryption' => 'VLESS · encryption',
                                                  'obfs_param' => 'Salamander · ${s.customServerPassword}',
                                                  'port_range' => 'Mieru · ${s.customServerPort}',
                                                  _ => key,
                                                },
                                                secret: key == 'obfs_param',
                                                info: null,
                                              ),
                                        ],
                                      ),
                                    ],
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: PrimaryButton(
                          key: const ValueKey('custom-save'),
                          label: _nextPeer ? s.tourNext : s.save,
                          busy: _saving,
                          onTap:
                              _busy ||
                                  problems.keys.any(
                                    (k) =>
                                        !_nextPeer ||
                                        ['name', 'address', 'port', 'credentials', 'addresses'].contains(k),
                                  )
                              ? null
                              : _nextPeer
                              ? () => setState(() => _peer = true)
                              : _save,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String key, String label, {String? info, bool digits = false, bool secret = false}) {
    final s = S.of(context), palette = Palette.of(context);
    final editingWireGuard =
        _wireGuard &&
        ['credentials', 'addresses', 'peerKey', 'presharedKey', 'allowedIps', 'keepalive'].any(_touched.contains);
    final error = _touched.contains(key) || editingWireGuard || (key == 'public_key' && _touched.contains('security'))
        ? _problems()[key]
        : null;
    final last =
        key ==
        switch (_protocol) {
          'wireguard' => 'keepalive',
          'shadowsocks' => 'method',
          'socks5' || 'http' => 'user',
          'tuic' => 'password',
          _ => 'credentials',
        };
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: error == null ? palette.field : palette.danger),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(label, style: Styles.row.copyWith(color: palette.ink)),
              ),
              if (info != null) InfoButton(title: label, description: info),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: label,
            hint: error,
            child: TextField(
              key: ValueKey('custom-$key'),
              controller: _fields[key],
              textDirection: key == 'name' ? null : TextDirection.ltr,
              enabled: !_busy,
              obscureText: secret && !_revealed.contains(key),
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: digits ? TextInputType.number : TextInputType.text,
              inputFormatters: digits ? [FilteringTextInputFormatter.digitsOnly] : null,
              textInputAction: last ? TextInputAction.done : TextInputAction.next,
              onSubmitted: last ? (_) => _save() : null,
              style: Styles.body.copyWith(color: palette.ink),
              decoration: InputDecoration(
                border: border,
                enabledBorder: border,
                disabledBorder: border,
                focusedBorder: border.copyWith(
                  borderSide: BorderSide(color: error == null ? palette.ink : palette.danger, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                isDense: true,
                suffixIcon: secret
                    ? IconButton(
                        tooltip: _revealed.contains(key) ? s.customServerHideSecret : s.customServerShowSecret,
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                if (!_revealed.remove(key)) _revealed.add(key);
                              }),
                        icon: Icon(
                          _revealed.contains(key) ? Symbols.visibility_off_rounded : Symbols.visibility_rounded,
                          size: 20,
                          color: palette.ink,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
