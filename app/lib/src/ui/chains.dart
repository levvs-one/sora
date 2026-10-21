import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../chains.dart';
import '../design/theme.dart';
import '../sora.dart';
import 'kit.dart';
import 'profiles.dart' show newLocalId;
import 'subscription_sheet.dart';

/// Proxy chains: named 2–3 hop routes through the user's servers.
class ChainsScreen extends StatefulWidget {
  const ChainsScreen({super.key});

  @override
  State<ChainsScreen> createState() => _ChainsScreenState();
}

class _ChainsScreenState extends State<ChainsScreen> {
  Future<void> _connect(BuildContext context, ProxyChain chain) async {
    final sora = SoraScope.read(context);
    try {
      await sora.connectChain(chain);
      // A later identical failure must surface again; without this the
      // failure pipeline would suppress it as a duplicate forever.
      sora.recovered('chain-connect');
    } catch (error) {
      sora.reportFailure(error, source: 'chain-connect');
    }
  }

  Future<void> _delete(BuildContext context, ProxyChain chain) async {
    final s = S.of(context);
    if (!await confirm(context, question: s.chainDeleteConfirm(chain.name), action: s.chainDelete)) {
      return;
    }
    if (context.mounted) SoraScope.read(context).chains.remove(chain.id);
  }

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    final chains = sora.chains.chains;
    // The capability note appears only when the core explicitly reports its
    // capabilities without the chain flag; an unknown core is not judged.
    final showUnsupported = sora.coreCapabilities.isNotEmpty && !sora.chainsSupported;
    return Screen(
      title: s.chains,
      actions: [
        RoundButton(
          icon: Symbols.add_rounded,
          label: s.chainAdd,
          onTap: () => push<void>(context, const ChainBuilderScreen()),
        ),
      ],
      children: [
        if (showUnsupported)
          Group(
            children: [Tile(title: s.chainUnsupported, titleColor: palette.ink2)],
          ),
        if (showUnsupported) const SizedBox(height: 16),
        if (chains.isEmpty)
          Group(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Symbols.link_rounded, size: 40, weight: 400, color: palette.ink3),
                    const SizedBox(height: 12),
                    Text(
                      s.chainsEmpty,
                      textAlign: TextAlign.center,
                      style: Styles.secondary.copyWith(color: palette.ink2),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          for (final chain in chains)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Group(
                children: [
                  Tile(
                    title: chain.name,
                    detail: _hopSummary(sora, chain),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RoundButton(
                          icon: Symbols.edit_rounded,
                          label: s.edit,
                          onTap: () => push<void>(context, ChainBuilderScreen(chain: chain)),
                        ),
                        RoundButton(
                          icon: Symbols.delete_rounded,
                          label: s.chainDelete,
                          onTap: () => unawaited(_delete(context, chain)),
                        ),
                      ],
                    ),
                    onTap: () => unawaited(_connect(context, chain)),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(_latencyLine(s, sora, chain), style: Styles.secondary.copyWith(color: palette.ink2)),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  String _hopSummary(Sora sora, ProxyChain chain) =>
      [for (final hop in chain.hops) sora.displayNameOf(hop)].join(' → ');

  String _latencyLine(S s, Sora sora, ProxyChain chain) {
    final ms = chain.estimatedLatency(sora.latency);
    return ms == null ? s.chainEstimate : '${s.chainEstimate}: ${s.latencyMs(ms)}';
  }
}

/// One server row in the chain picker: tap toggles membership.
class _ServerPickRow extends StatelessWidget {
  const _ServerPickRow({
    required this.name,
    required this.detail,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String name;
  final String? detail;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    return Tile(
      title: name,
      detail: detail,
      selected: selected,
      trailing: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: selected ? palette.ink : palette.ink3),
          borderRadius: BorderRadius.circular(6),
          color: selected ? palette.ink : Colors.transparent,
        ),
        child: SizedBox.square(
          dimension: 22,
          child: selected ? Icon(Symbols.check_rounded, size: 16, weight: 700, color: palette.surface) : null,
        ),
      ),
      onTap: enabled ? onTap : null,
    );
  }
}

/// Builds or edits a proxy chain: picks 2–3 servers and orders them.
class ChainBuilderScreen extends StatefulWidget {
  const ChainBuilderScreen({super.key, this.chain});

  final ProxyChain? chain;

  @override
  State<ChainBuilderScreen> createState() => _ChainBuilderScreenState();
}

class _ChainBuilderScreenState extends State<ChainBuilderScreen> {
  late String _name;
  late List<String> _hops;

  @override
  void initState() {
    super.initState();
    _name = widget.chain?.name ?? '';
    _hops = List<String>.of(widget.chain?.hops ?? const <String>[]);
  }

  Future<void> _editName() async {
    final s = S.of(context);
    await showFieldSheet(
      context,
      title: s.chainName,
      hint: s.chainName,
      action: s.save,
      initial: _name,
      submit: (value) async {
        if (value.trim().isEmpty) return s.chainName;
        setState(() => _name = value.trim());
        return null;
      },
    );
  }

  void _toggleHop(String id) {
    setState(() {
      if (_hops.contains(id)) {
        _hops.remove(id);
      } else if (_hops.length < maxChainHops) {
        _hops.add(id);
      }
    });
  }

  void _save() {
    final sora = SoraScope.read(context);
    final s = S.of(context);
    if (_name.trim().isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(s.chainName)));
      return;
    }
    final error = ChainsStore.validateHops(_hops);
    if (error != null) {
      final message = switch (error) {
        'chainTooFew' => s.chainTooFew,
        'chainTooMany' => s.chainTooMany,
        'chainDuplicate' => s.chainDuplicate,
        _ => s.chainTooFew,
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    final chain = ProxyChain(id: widget.chain?.id ?? newLocalId('c'), name: _name.trim(), hops: _hops);
    final storeError = widget.chain == null ? sora.chains.add(chain) : sora.chains.update(chain);
    if (storeError != null) {
      final message = switch (storeError) {
        'chainTooMany' => s.chainTooMany,
        'chainDuplicate' => s.chainDuplicate,
        _ => s.chainTooFew,
      };
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    final hidden = sora.hiddenServerIds;
    final servers = [
      for (final o in sora.servers)
        if (!hidden.contains(o.id)) o,
    ];
    final estimate = ProxyChain(id: '', name: '', hops: _hops).estimatedLatency(sora.latency);
    return Screen(
      title: widget.chain == null ? s.chainAdd : s.chainName,
      actions: [RoundButton(icon: Symbols.check_rounded, label: s.chainSave, onTap: _save)],
      children: [
        Group(
          children: [LinkTile(title: s.chainName, value: _name.isEmpty ? null : _name, onTap: _editName)],
        ),
        const SizedBox(height: 16),
        Heading(s.chainPickServers),
        Group(
          children: [
            for (final server in servers)
              _ServerPickRow(
                name: sora.displayNameOf(server.id),
                detail: server.displayProtocol.isEmpty ? null : server.displayProtocol,
                selected: _hops.contains(server.id),
                enabled: _hops.contains(server.id) || _hops.length < maxChainHops,
                onTap: () => _toggleHop(server.id),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Heading(s.chainOrderHint),
        if (_hops.isEmpty)
          Group(
            children: [Tile(title: s.chainTooFew, titleColor: palette.ink2)],
          )
        else
          Group(
            children: [
              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorderItem: (oldIndex, newIndex) {
                  setState(() {
                    final hop = _hops.removeAt(oldIndex);
                    _hops.insert(newIndex, hop);
                  });
                },
                children: [
                  for (var i = 0; i < _hops.length; i++)
                    ListTile(
                      key: ValueKey(_hops[i]),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      leading: Icon(Symbols.drag_handle_rounded, color: palette.ink3),
                      title: Text(sora.displayNameOf(_hops[i]), style: Styles.body.copyWith(color: palette.ink)),
                      subtitle: Text(
                        i == 0 ? s.chainEntry : (i == _hops.length - 1 ? s.chainExit : s.chainHop('${i + 1}')),
                        style: Styles.secondary.copyWith(color: palette.ink2),
                      ),
                      trailing: RoundButton(
                        icon: Symbols.close_rounded,
                        label: s.remove,
                        onTap: () => setState(() => _hops.removeAt(i)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        const SizedBox(height: 16),
        Group(
          children: [
            Tile(
              title: s.chainEstimate,
              trailing: Text(
                estimate == null ? '—' : s.latencyMs(estimate),
                style: Styles.bodyStrong.copyWith(color: palette.ink),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
