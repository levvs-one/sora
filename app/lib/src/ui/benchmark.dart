import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../sora.dart';
import 'kit.dart';

/// Throughput benchmark screen.
///
/// Starts measuring [serverIds] (all servers when null) on open and shows
/// per-server progress and results. Measurements persist across restarts and
/// feed speed-based sorting and smart auto-selection. Stale results (older
/// than [Sora.bandwidthTtl]) are marked and ignored by speed modes.
class BenchmarkScreen extends StatefulWidget {
  const BenchmarkScreen({super.key, this.serverIds});

  final List<String>? serverIds;

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final sora = SoraScope.read(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(sora.benchmarkServers(serverIds: widget.serverIds));
    });
  }

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    final ids = widget.serverIds ?? [for (final o in sora.servers) o.id];
    final progress = sora.benchmarkProgress;
    // Sort keys are computed once per build pass, not per comparison:
    // freshBandwidth checks measurement age and displayNameOf scans the
    // server lists, so calling them inside the comparator made every
    // benchmark-progress rebuild O(n log n) scans.
    final freshById = <String, int?>{for (final id in ids) id: sora.freshBandwidth(id)};
    final nameById = <String, String>{for (final id in ids) id: sora.displayNameOf(id).toLowerCase()};
    // Fastest first; unmeasured servers last, by name.
    final ordered = List<String>.of(ids)
      ..sort((a, b) {
        final x = freshById[a], y = freshById[b];
        if (x == null && y == null) {
          return nameById[a]!.compareTo(nameById[b]!);
        }
        if (x == null) return 1;
        if (y == null) return -1;
        return y.compareTo(x);
      });
    return Screen(
      title: s.measureSpeed,
      actions: [
        if (sora.benchmarking)
          RoundButton(icon: Symbols.close_rounded, label: s.cancel, onTap: () => unawaited(sora.cancelBenchmark())),
      ],
      children: [
        if (progress != null) ...[
          Text(
            s.benchmarkProgress(progress.done, progress.total),
            style: Styles.secondary.copyWith(color: palette.ink2),
          ),
          const SizedBox(height: 8),
          // Decorative: the "done of total" text above already announces
          // progress to screen readers.
          ExcludeSemantics(
            child: LinearProgressIndicator(
              value: progress.total == 0 ? null : progress.done / progress.total,
              color: palette.ink,
              backgroundColor: palette.field,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (!sora.benchmarking && ordered.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PrimaryButton(
              label: s.measureSpeed,
              onTap: sora.canBenchmark ? () => unawaited(sora.benchmarkServers(serverIds: widget.serverIds)) : null,
            ),
          ),
        if (ordered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              s.errNoServers,
              textAlign: TextAlign.center,
              style: Styles.secondary.copyWith(color: palette.ink2),
            ),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                for (var i = 0; i < ordered.length; i++) ...[
                  if (i > 0) Divider(height: 1, thickness: 1, indent: 12, endIndent: 12, color: palette.field),
                  // Keyed by server id: the list re-sorts fastest-first
                  // as each measurement lands, so row state (progress
                  // indicator) must follow the server, not the position.
                  _BenchmarkRow(key: ValueKey(ordered[i]), id: ordered[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _BenchmarkRow extends StatelessWidget {
  const _BenchmarkRow({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context);
    final s = S.of(context);
    final palette = Palette.of(context);
    final bps = sora.freshBandwidth(id);
    final stale = bps == null ? sora.bandwidth[id]?.bps : null;
    final pct = sora.benchmarkPct[id];
    final running = sora.benchmarking && bps == null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sora.displayNameOf(id),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Styles.row.copyWith(color: palette.ink),
                ),
                if (running && pct != null) ...[
                  const SizedBox(height: 6),
                  // Decorative: the overall progress text at the top of the
                  // screen announces measurement progress.
                  ExcludeSemantics(
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      color: palette.ink,
                      backgroundColor: palette.field,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (running && pct == null)
            SizedBox.square(dimension: 20, child: CupertinoActivityIndicator(color: palette.ink2))
          else if (bps != null)
            Text(s.speedMbps(mbpsOf(bps)), style: Styles.figures(Styles.secondary).copyWith(color: palette.ink))
          else if (stale != null)
            Text(
              '${s.speedMbps(mbpsOf(stale))} · ${s.benchmarkStale}',
              style: Styles.figures(Styles.caption).copyWith(color: palette.ink3),
            )
          else
            Text('—', style: Styles.figures(Styles.secondary).copyWith(color: palette.ink3)),
        ],
      ),
    );
  }
}
