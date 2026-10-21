// This is a generated file - do not edit.
//
// Generated from sora/ext/v1/ext_host.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// The first message configures the worker; later messages carry bridge replies.
class WorkerClientMessage extends $pb.GeneratedMessage {
  factory WorkerClientMessage({
    $core.List<$core.int>? controlToken,
    $core.String? manifestJson,
    $core.String? source,
    $core.String? configJson,
    $core.String? replyJson,
  }) {
    final result = WorkerClientMessage._();
    if (controlToken != null) result.controlToken = controlToken;
    if (manifestJson != null) result.manifestJson = manifestJson;
    if (source != null) result.source = source;
    if (configJson != null) result.configJson = configJson;
    if (replyJson != null) result.replyJson = replyJson;
    return result;
  }

  WorkerClientMessage._();

  factory WorkerClientMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WorkerClientMessage()..mergeFromBuffer(data, registry);
  factory WorkerClientMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WorkerClientMessage()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'WorkerClientMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: WorkerClientMessage.$_createMessage)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'controlToken', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'manifestJson')
    ..aOS(3, _omitFieldNames ? '' : 'source')
    ..aOS(4, _omitFieldNames ? '' : 'configJson')
    ..aOS(5, _omitFieldNames ? '' : 'replyJson')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WorkerClientMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WorkerClientMessage copyWith(void Function(WorkerClientMessage) updates) =>
      super.copyWith((message) => updates(message as WorkerClientMessage)) as WorkerClientMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WorkerClientMessage() / WorkerClientMessage.new instead')
  static WorkerClientMessage create() => WorkerClientMessage._();
  static $pb.GeneratedMessage $_createMessage() => WorkerClientMessage._();
  @$core.override
  WorkerClientMessage createEmptyInstance() => WorkerClientMessage._();
  @$core.pragma('dart2js:noInline')
  static WorkerClientMessage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WorkerClientMessage>(WorkerClientMessage.$_createMessage);
  static WorkerClientMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get controlToken => $_getN(0);
  @$pb.TagNumber(1)
  set controlToken($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasControlToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearControlToken() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get manifestJson => $_getSZ(1);
  @$pb.TagNumber(2)
  set manifestJson($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasManifestJson() => $_has(1);
  @$pb.TagNumber(2)
  void clearManifestJson() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get source => $_getSZ(2);
  @$pb.TagNumber(3)
  set source($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSource() => $_has(2);
  @$pb.TagNumber(3)
  void clearSource() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get configJson => $_getSZ(3);
  @$pb.TagNumber(4)
  set configJson($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasConfigJson() => $_has(3);
  @$pb.TagNumber(4)
  void clearConfigJson() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get replyJson => $_getSZ(4);
  @$pb.TagNumber(5)
  set replyJson($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasReplyJson() => $_has(4);
  @$pb.TagNumber(5)
  void clearReplyJson() => $_clearField(5);
}

class WorkerHostMessage extends $pb.GeneratedMessage {
  factory WorkerHostMessage({
    $core.String? callJson,
    $core.String? log,
    $core.bool? failed,
  }) {
    final result = WorkerHostMessage._();
    if (callJson != null) result.callJson = callJson;
    if (log != null) result.log = log;
    if (failed != null) result.failed = failed;
    return result;
  }

  WorkerHostMessage._();

  factory WorkerHostMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WorkerHostMessage()..mergeFromBuffer(data, registry);
  factory WorkerHostMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WorkerHostMessage()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'WorkerHostMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: WorkerHostMessage.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'callJson')
    ..aOS(2, _omitFieldNames ? '' : 'log')
    ..aOB(3, _omitFieldNames ? '' : 'failed')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WorkerHostMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WorkerHostMessage copyWith(void Function(WorkerHostMessage) updates) =>
      super.copyWith((message) => updates(message as WorkerHostMessage)) as WorkerHostMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WorkerHostMessage() / WorkerHostMessage.new instead')
  static WorkerHostMessage create() => WorkerHostMessage._();
  static $pb.GeneratedMessage $_createMessage() => WorkerHostMessage._();
  @$core.override
  WorkerHostMessage createEmptyInstance() => WorkerHostMessage._();
  @$core.pragma('dart2js:noInline')
  static WorkerHostMessage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WorkerHostMessage>(WorkerHostMessage.$_createMessage);
  static WorkerHostMessage? _defaultInstance;

  /// Bridge call JSON, dispatched by the app using PanelBridge.
  @$pb.TagNumber(1)
  $core.String get callJson => $_getSZ(0);
  @$pb.TagNumber(1)
  set callJson($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCallJson() => $_has(0);
  @$pb.TagNumber(1)
  void clearCallJson() => $_clearField(1);

  /// Bounded operational or script log, also retained in the core LogHub.
  @$pb.TagNumber(2)
  $core.String get log => $_getSZ(1);
  @$pb.TagNumber(2)
  set log($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLog() => $_has(1);
  @$pb.TagNumber(2)
  void clearLog() => $_clearField(2);

  /// One failed run; the app emits a localized notification.
  @$pb.TagNumber(3)
  $core.bool get failed => $_getBF(2);
  @$pb.TagNumber(3)
  set failed($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFailed() => $_has(2);
  @$pb.TagNumber(3)
  void clearFailed() => $_clearField(3);
}

const $core.bool _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
