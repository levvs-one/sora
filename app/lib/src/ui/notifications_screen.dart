import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/strings.dart';
import '../design/theme.dart';
import '../notifications.dart';
import '../sora.dart';
import '../speedtest_services.dart';
import 'kit.dart';
import 'notification_text.dart';
import 'logs.dart';
import 'subscription.dart';
import 'speedtest.dart';
import 'about.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  DateTime? _newest;
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    final sora = SoraScope.of(context), s = S.of(context), palette = Palette.of(context);
    final locale = Intl.verifiedLocale(s.localeName, DateFormat.localeExists, onFailure: (_) => 'en');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final days = <DateTime, List<List<AppNotification>>>{};
    for (final notice in sora.history) {
      final time = notice.time.toLocal();
      final rows = days.putIfAbsent(DateTime(time.year, time.month, time.day), () => []);
      final repeated = rows.where((row) {
        final first = row.first;
        return first.time.difference(notice.time).abs() <= const Duration(minutes: 2) &&
            (notificationText(s, first), first.action, first.argument, first.failureKey) ==
                (notificationText(s, notice), notice.action, notice.argument, notice.failureKey);
      }).firstOrNull;
      if (repeated == null) {
        rows.add([notice]);
      } else {
        repeated.add(notice);
      }
    }
    final previous = _newest;
    final appeared = _shown;
    _shown = true;
    _newest = sora.history.firstOrNull?.time;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 880),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (Navigator.of(context).canPop())
                        RoundButton(
                          icon: Symbols.chevron_left_rounded,
                          label: MaterialLocalizations.of(context).backButtonTooltip,
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                      Expanded(
                        child: Text(s.notifications, style: Styles.heading.copyWith(color: palette.ink)),
                      ),
                      if (sora.unreadCount > 0)
                        IconButton(
                          key: const ValueKey('notifications-read-all'),
                          tooltip: s.notificationsMarkRead,
                          onPressed: () => unawaited(sora.markNotificationsRead()),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(36, 36),
                            padding: const EdgeInsets.all(8),
                            hoverColor: palette.hover,
                            focusColor: palette.pressed,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: Icon(Symbols.done_all_rounded, size: 18, color: palette.ink2),
                        ),
                      TextButton(
                        key: const ValueKey('notifications-clear'),
                        onPressed: sora.history.isEmpty ? null : () => unawaited(sora.clearNotifications()),
                        style: TextButton.styleFrom(
                          foregroundColor: palette.ink2,
                          disabledForegroundColor: palette.ink3,
                          textStyle: Styles.secondary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(s.clear),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (days.isEmpty)
                    Text(s.notificationsEmpty, style: Styles.secondary.copyWith(color: palette.ink2))
                  else
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          for (final day in days.entries) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                              child: Text(
                                day.key == today
                                    ? s.notificationsToday
                                    : day.key == yesterday
                                    ? s.notificationsYesterday
                                    : DateFormat.yMMMMd(locale).format(day.key),
                                style: Styles.caption.copyWith(color: palette.ink3),
                              ),
                            ),
                            Material(
                              key: ValueKey(day.key),
                              color: palette.surface,
                              borderRadius: BorderRadius.circular(12),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                children: [
                                  for (var i = 0; i < day.value.length; i++) ...[
                                    if (i > 0)
                                      Divider(height: 1, thickness: 0, indent: 12, endIndent: 12, color: palette.field),
                                    TweenAnimationBuilder<double>(
                                      key: ValueKey((
                                        day.value[i].last.time,
                                        day.value[i].last.title,
                                        day.value[i].last.body,
                                        day.value[i].last.action,
                                        day.value[i].last.argument,
                                        day.value[i].last.failureKey,
                                      )),
                                      tween: Tween(
                                        begin:
                                            appeared && (previous == null || day.value[i].first.time.isAfter(previous))
                                            ? 0
                                            : 1,
                                        end: 1,
                                      ),
                                      duration: Motion.of(context, Motion.fast),
                                      curve: Motion.curve,
                                      builder: (_, value, child) => Opacity(
                                        opacity: value,
                                        child: Transform.translate(offset: Offset(0, -8 * (1 - value)), child: child),
                                      ),
                                      child: NotificationRow(notices: day.value[i]),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationRow extends StatelessWidget {
  const NotificationRow({super.key, required this.notices});
  final List<AppNotification> notices;

  @override
  Widget build(BuildContext context) {
    final notice = notices.first;
    final s = S.of(context), palette = Palette.of(context);
    final words = notificationText(s, notice);
    final unread = notices.any((n) => !n.read);
    final action = switch (notice.action) {
      'connect' => s.retryConnect,
      'logs' => s.openLogs,
      'subscription' => s.subscription,
      'speedtest' => s.refresh,
      'update' => s.updateOpenAbout,
      'apply-profile' => s.profileApply,
      'undo-profile' => s.profileUndo,
      _ => null,
    };
    return Semantics(
      label: unread ? s.notificationsUnread : null,
      hint: action,
      button: action != null || unread,
      child: Tooltip(
        message: [words.title, if (words.body.isNotEmpty && words.body != words.title) words.body].join('\n'),
        child: InkWell(
          onTap: action == null && !unread
              ? null
              : () {
                  unawaited(SoraScope.read(context).markNotificationsRead(notices: notices));
                  runNotificationAction(context, notice);
                },
          hoverColor: palette.hover,
          focusColor: palette.pressed,
          highlightColor: palette.pressed,
          hoverDuration: Duration.zero,
          splashFactory: NoSplash.splashFactory,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SizedBox.square(
                        dimension: 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: unread ? palette.ink : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              child: Text(
                                words.title,
                                maxLines: words.body.isEmpty || words.body == words.title ? 2 : 1,
                                overflow: TextOverflow.ellipsis,
                                style: Styles.bodyStrong.copyWith(fontSize: 14, height: 1.2, color: palette.ink),
                              ),
                            ),
                            if (notices.length > 1) ...[
                              const SizedBox(width: 8),
                              Text(
                                s.notificationRepeat(notices.length),
                                style: Styles.figures(Styles.caption).copyWith(color: palette.ink2),
                              ),
                            ],
                            const SizedBox(width: 12),
                            Text(
                              DateFormat.Hm(s.localeName).format(notice.time.toLocal()),
                              style: Styles.figures(Styles.caption).copyWith(color: palette.ink3),
                            ),
                          ],
                        ),
                        if (words.body.isNotEmpty && words.body != words.title) ...[
                          const SizedBox(height: 2),
                          Text(
                            words.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Styles.secondary.copyWith(color: palette.ink),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void runNotificationAction(BuildContext context, AppNotification notice) {
  final sora = SoraScope.read(context);
  switch (notice.action) {
    case 'update':
      unawaited(push<void>(context, const AboutScreen()));
    case 'connect':
      unawaited(sora.connect());
    case 'logs':
      unawaited(push<void>(context, const LogsScreen()));
    case 'subscription':
      unawaited(push<void>(context, SubscriptionScreen(id: notice.argument)));
    case 'speedtest':
      final service = speedtestServices.where((s) => s.url == notice.argument).firstOrNull;
      if (service != null) unawaited(push<void>(context, Scaffold(body: SpeedtestScreen(initialService: service))));
    case 'apply-profile':
      final profile = sora.profiles.byId(notice.argument);
      if (profile != null) unawaited(sora.applyProfileWithUndo(profile));
    case 'undo-profile':
      unawaited(sora.undoProfileApply(notice.argument));
  }
}
