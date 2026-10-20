import 'package:flutter/widgets.dart';

import '../../l10n/strings.dart';
import '../desktop/happ_routing.dart';
import '../rules.dart';
import '../sora.dart';
import 'kit.dart';

/// Imports a Happ routing profile (happ://routing/add/…) as user
/// rules. The user always sees what the profile carries — its name
/// and the rule counts per target, plus the provider DNS it records
/// without applying — and confirms before anything is stored. The
/// converted rules land in the same rule list the rules screen edits,
/// replacing any existing rule for the same destination, so a
/// re-import updates instead of duplicating. Fields sora cannot
/// apply (provider DNS, FakeDNS, a direct default) are recorded in
/// the conversion's notes, not silently dropped; the full accounting
/// lives in happ_routing.dart, mirrored from core/happrouting.
Future<void> showRoutingImport(BuildContext context, Sora sora, String payload) async {
  final s = S.of(context);
  final imported = convertHappRouting(payload);
  if (imported == null) {
    await confirm(context, question: s.qrInvalid, action: s.understood, destructive: false, cancellable: false);
    return;
  }
  final summary = [
    if (imported.name.isNotEmpty) imported.name else s.rules,
    '${s.ruleDirect}: ${imported.countOf(RuleTarget.direct)}',
    '${s.ruleProxy}: ${imported.countOf(RuleTarget.proxy)}',
    '${s.ruleBlock}: ${imported.countOf(RuleTarget.block)}',
    if (imported.remoteDns.isNotEmpty) '${s.dns}: ${imported.remoteDns}',
    // Fields sora recorded but does not apply (FakeDNS, a direct
    // default from GlobalProxy=false, provider DNS, …) are named in
    // the dialog instead of vanishing: the user confirms with the
    // whole picture, not just the rule counts.
    for (final note in imported.notes)
      if (!note.applied) s.routingNoteRecorded(note.field),
  ].join('\n');
  if (imported.rules.isEmpty) {
    // A valid profile with no convertible rules (DNS-only, or every
    // entry unclassifiable): show what arrived, store nothing.
    await confirm(context, question: summary, action: s.understood, destructive: false, cancellable: false);
    return;
  }
  final accepted = await confirm(context, question: summary, action: s.add, destructive: false);
  if (!accepted) return;

  await sora.change((x) {
    x.rules = mergeImportedRules(x.rules, imported.rules);
  });
}
