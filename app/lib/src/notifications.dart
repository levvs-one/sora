import 'dart:convert';

class AppNotification {
  AppNotification({
    required this.time,
    required this.title,
    required this.body,
    this.action = '',
    this.argument = '',
    this.read = false,
    this.failureKey = '',
    this.messageKey = '',
    Map<String, String> messageArgs = const {},
  }) : messageArgs = Map.unmodifiable(messageArgs);

  final DateTime time;
  final String title;
  final String body;
  final String action;
  final String argument;
  final bool read;
  final String failureKey;
  final String messageKey;
  final Map<String, String> messageArgs;

  AppNotification markRead() => AppNotification(
    time: time,
    title: title,
    body: body,
    action: action,
    argument: argument,
    read: true,
    failureKey: failureKey,
    messageKey: messageKey,
    messageArgs: messageArgs,
  );

  String get stored => jsonEncode({
    'time': time.toIso8601String(),
    'title': title,
    'body': body,
    'action': action,
    'argument': argument,
    'read': read,
    if (failureKey.isNotEmpty) 'failureKey': failureKey,
    if (messageKey.isNotEmpty) 'messageKey': messageKey,
    if (messageArgs.isNotEmpty) 'messageArgs': messageArgs,
  });

  static AppNotification? parse(String value) {
    try {
      final json = jsonDecode(value) as Map<String, dynamic>;
      final rawArgs = json['messageArgs'];
      final argsValid =
          rawArgs == null ||
          rawArgs is Map && rawArgs.keys.every((k) => k is String) && rawArgs.values.every((v) => v is String);
      return AppNotification(
        time: DateTime.parse(json['time'] as String),
        title: json['title'] as String,
        body: json['body'] as String,
        action: json['action'] as String? ?? '',
        argument: json['argument'] as String? ?? '',
        read: json['read'] as bool? ?? false,
        failureKey: json['failureKey'] as String? ?? '',
        messageKey: argsValid && json['messageKey'] is String ? json['messageKey'] as String : '',
        messageArgs: argsValid && rawArgs is Map ? rawArgs.cast<String, String>() : const {},
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
