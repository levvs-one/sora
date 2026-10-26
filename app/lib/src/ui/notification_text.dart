import 'package:intl/intl.dart';

import '../../l10n/strings.dart';
import '../core/link.dart';
import '../notifications.dart';
import 'kit.dart' show describe;

/// Stored wording remains a fallback for extension messages and future event kinds.
({String title, String body}) notificationText(S s, AppNotification notice) {
  final message = notice.messageKey.isEmpty
      ? _legacyMessage(notice)
      : (key: notice.messageKey, args: notice.messageArgs);
  if (message == null) return (title: notice.title, body: notice.body);
  final args = message.args;
  final entry = args['entry'] ?? '';
  String failure() =>
      describe(s, CoreFailure(args['failure'] ?? notice.failureKey, httpStatus: int.tryParse(args['status'] ?? '')));
  return switch (message.key) {
    'notice.failure' => (title: failure(), body: ''),
    'notice.connectionFailed' => (title: s.noticeFailed, body: failure()),
    'notice.connectionLost' => (title: s.noticeLost, body: s.noticeLostBody),
    'notice.connectionRestored' => (
      title: s.noticeRestored,
      body: switch (args['mode']) {
        'auto' => s.serverAuto,
        'bypass' => s.serverBypass,
        _ => entry,
      },
    ),
    'notice.backup' => (title: entry, body: s.noticeBackup),
    'notice.next' => (title: entry, body: s.noticeNext),
    'notice.returned' => (title: entry, body: s.noticeMainBack),
    'notice.degraded' => (title: entry, body: s.noticeDegraded),
    'notice.update' => (title: s.updateAvailable(args['version'] ?? ''), body: s.updateOpenAbout),
    'notice.profileAsk' => (title: s.profileApplyAsk(args['name'] ?? ''), body: ''),
    'notice.profileApplied' => (title: s.profileApplied(args['name'] ?? ''), body: ''),
    'notice.tray' => (title: s.noticeInTray, body: s.noticeInTrayBody),
    'notice.expired' => (title: s.noticeSubscription, body: '${args['name']}: ${s.expired.toLowerCase()}'),
    'notice.expiring' => (
      title: s.noticeSubscription,
      body: s.expiresIn(args['name'] ?? '', int.tryParse(args['days'] ?? '') ?? 0),
    ),
    'notice.traffic' => (title: s.noticeSubscription, body: s.trafficLow(args['name'] ?? '', _trafficAmount(s, args))),
    'notice.static' => (
      title: _labels(s)[args['title']] ?? notice.title,
      body: _labels(s)[args['body']] ?? notice.body,
    ),
    _ => (title: notice.title, body: notice.body),
  };
}

Map<String, String> _labels(S s) => {
  'customServerOwn': s.customServerOwn,
  'customServerNameRequired': s.customServerNameRequired,
  'customServerAddressRequired': s.customServerAddressRequired,
  'customServerAddressInvalid': s.customServerAddressInvalid,
  'customServerPortInvalid': s.customServerPortInvalid,
  'customServerSecretRequired': s.customServerSecretRequired,
  'customServerWgKeyInvalid': s.customServerWgKeyInvalid,
  'customServerWgCidrInvalid': s.customServerWgCidrInvalid,
  'customServerWgKeepaliveInvalid': s.customServerWgKeepaliveInvalid,
  'customServerLinkInvalid': s.customServerLinkInvalid,
  'qrScanTitle': s.qrScanTitle,
  'qrNoCode': s.qrNoCode,
  'qrInvalid': s.qrInvalid,
  'diagnosticHttp': s.diagnosticHttp,
  'diagnosticNoData': s.diagnosticNoData,
  'diagnosticEvents': s.diagnosticEvents,
  'diagnosticUnavailable': s.diagnosticUnavailable,
  'diagnosticPackets': s.diagnosticPackets,
  'diagnosticRequiresTun': s.diagnosticRequiresTun,
  'updates': s.updates,
  'updateNetworkError': s.updateNetworkError,
  'updateReleaseError': s.updateReleaseError,
  'updateChecksumError': s.updateChecksumError,
  'updateInstallError': s.updateInstallError,
  'updateWaitConnection': s.updateWaitConnection,
  'updateUnsupported': s.updateUnsupported,
  'updateRollbackError': s.updateRollbackError,
  'updateRollbackCacheError': s.updateRollbackCacheError,
  'invalidValue': s.invalidValue,
  'probeUrl': s.probeUrl,
  'profileName': s.profileName,
  'subscription': s.subscription,
  'profileSsids': s.profileSsids,
  'profileGateways': s.profileGateways,
  'profileAsns': s.profileAsns,
  'fragmentPackets': s.fragmentPackets,
  'fragmentLength': s.fragmentLength,
  'fragmentInterval': s.fragmentInterval,
  'splitPos': s.splitPos,
};

// Old histories contain rendered strings. Recognize complete known templates,
// retaining unmatched text instead of guessing at arbitrary external messages.
({String key, Map<String, String> args})? _legacyMessage(AppNotification notice) {
  final failure = notice.failureKey.startsWith('core.') || notice.failureKey.startsWith('app.');
  final status = notice.failureKey == 'core.subscription.status'
      ? RegExp(r'\b[1-5][0-9]{2}\b').firstMatch('${notice.title} ${notice.body}')?.group(0)
      : null;
  final failureArgs = {'failure': notice.failureKey, 'status': ?status};
  if (failure && notice.body.isEmpty) return (key: 'notice.failure', args: failureArgs);
  for (final locale in S.supportedLocales) {
    final old = lookupS(locale);
    if (failure && notice.title == old.noticeFailed) return (key: 'notice.connectionFailed', args: failureArgs);
    if (notice.title == old.noticeLost && notice.body == old.noticeLostBody) {
      return (key: 'notice.connectionLost', args: const {});
    }
    if (notice.title == old.noticeRestored) return (key: 'notice.connectionRestored', args: {'entry': notice.body});
    if (notice.title == old.noticeInTray && notice.body == old.noticeInTrayBody) {
      return (key: 'notice.tray', args: const {});
    }
    if (notice.action == 'logs') {
      if (notice.body == old.noticeBackup) return (key: 'notice.backup', args: {'entry': notice.title});
      if (notice.body == old.noticeNext) return (key: 'notice.next', args: {'entry': notice.title});
      if (notice.body == old.noticeDegraded) return (key: 'notice.degraded', args: {'entry': notice.title});
    }
    if (notice.body == old.noticeMainBack && notice.action.isEmpty) {
      return (key: 'notice.returned', args: {'entry': notice.title});
    }
    if (notice.action == 'update' && notice.body == old.updateOpenAbout) {
      final version = _capture(old.updateAvailable(_marker), notice.title);
      if (version != null) return (key: 'notice.update', args: {'version': version});
    }
    if (notice.action == 'apply-profile') {
      final name = _capture(old.profileApplyAsk(_marker), notice.title);
      if (name != null) return (key: 'notice.profileAsk', args: {'name': name});
    }
    if (notice.action == 'undo-profile') {
      final name = _capture(old.profileApplied(_marker), notice.title);
      if (name != null) return (key: 'notice.profileApplied', args: {'name': name});
    }
    if (notice.action == 'subscription' && notice.title == old.noticeSubscription) {
      final expired = _capture('$_marker: ${old.expired.toLowerCase()}', notice.body);
      if (expired != null) return (key: 'notice.expired', args: {'name': expired});
      final traffic = old.trafficLow(_marker, _amountMarker);
      final split = traffic.indexOf(_amountMarker);
      if (split >= 0) {
        final end = traffic.substring(split + _amountMarker.length);
        if (notice.body.endsWith(end)) {
          final prefix = traffic.substring(0, split);
          final join = prefix.substring(prefix.indexOf(_marker) + _marker.length);
          final from = notice.body.lastIndexOf(join, notice.body.length - end.length - 1);
          if (join.isNotEmpty && from >= 0) {
            final name = _capture(prefix, notice.body.substring(0, from + join.length));
            final left = notice.body.substring(from + join.length, notice.body.length - end.length);
            final units = [
              old.bytesB(_marker),
              old.bytesKB(_marker),
              old.bytesMB(_marker),
              old.bytesGB(_marker),
              old.bytesTB(_marker),
            ];
            for (var unit = 0; name != null && unit < units.length; unit++) {
              final number = _capture(units[unit], left);
              if (number == null) continue;
              try {
                final format = NumberFormat(
                  '0.#',
                  Intl.verifiedLocale(old.localeName, NumberFormat.localeExists, onFailure: (_) => 'en'),
                );
                final value = format.parse(number);
                if (value < 0 || format.format(value) != number) continue;
                return (key: 'notice.traffic', args: {'name': name, 'amount': '$value', 'unit': '$unit'});
              } on FormatException {
                continue;
              }
            }
          }
        }
      }
      // The existing warning policy emits only inDays 0..2.
      for (var days = 0; days < 3; days++) {
        final name = _capture(old.expiresIn(_marker, days), notice.body);
        if (name != null) return (key: 'notice.expiring', args: {'name': name, 'days': '$days'});
      }
    }
    final labels = _labels(old);
    final title = labels.entries.where((e) => e.value == notice.title).firstOrNull?.key;
    final body = labels.entries.where((e) => e.value == notice.body).firstOrNull?.key;
    if (title != null && (notice.body.isEmpty || body != null)) {
      return (key: 'notice.static', args: {'title': title, 'body': ?body});
    }
  }
  return null;
}

String _trafficAmount(S s, Map<String, String> args) {
  final value = num.tryParse(args['amount'] ?? '');
  if (value == null || !value.isFinite || value < 0) return args['left'] ?? '';
  final number = NumberFormat(
    value >= 100 || args['unit'] == '0' ? '0' : '0.#',
    Intl.verifiedLocale(s.localeName, NumberFormat.localeExists, onFailure: (_) => 'en'),
  ).format(value);
  return switch (args['unit']) {
    '0' => s.bytesB(number),
    '1' => s.bytesKB(number),
    '2' => s.bytesMB(number),
    '3' => s.bytesGB(number),
    '4' => s.bytesTB(number),
    _ => args['left'] ?? '',
  };
}

const _amountMarker = '\uE002sora-notification-amount\uE003';
const _marker = '\uE000sora-notification-value\uE001';

String? _capture(String template, String value) {
  final at = template.indexOf(_marker);
  if (at < 0 || template.indexOf(_marker, at + _marker.length) >= 0) return null;
  final prefix = template.substring(0, at), suffix = template.substring(at + _marker.length);
  if (value.length < prefix.length + suffix.length || !value.startsWith(prefix) || !value.endsWith(suffix)) return null;
  return value.substring(prefix.length, value.length - suffix.length);
}
