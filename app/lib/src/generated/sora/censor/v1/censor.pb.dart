// This is a generated file - do not edit.
//
// Generated from sora/censor/v1/censor.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'censor.pbenum.dart';

class AttemptEvent extends $pb.GeneratedMessage {
  factory AttemptEvent() => AttemptEvent._();

  AttemptEvent._();

  factory AttemptEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AttemptEvent()..mergeFromBuffer(data, registry);
  factory AttemptEvent.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AttemptEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AttemptEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.censor.v1'),
      createEmptyInstance: AttemptEvent.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttemptEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AttemptEvent copyWith(void Function(AttemptEvent) updates) =>
      super.copyWith((message) => updates(message as AttemptEvent)) as AttemptEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AttemptEvent() / AttemptEvent.new instead')
  static AttemptEvent create() => AttemptEvent._();
  static $pb.GeneratedMessage $_createMessage() => AttemptEvent._();
  @$core.override
  AttemptEvent createEmptyInstance() => AttemptEvent._();
  @$core.pragma('dart2js:noInline')
  static AttemptEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AttemptEvent>(AttemptEvent.$_createMessage);
  static AttemptEvent? _defaultInstance;
}

class ObfuscationProfileRef extends $pb.GeneratedMessage {
  factory ObfuscationProfileRef() => ObfuscationProfileRef._();

  ObfuscationProfileRef._();

  factory ObfuscationProfileRef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ObfuscationProfileRef()..mergeFromBuffer(data, registry);
  factory ObfuscationProfileRef.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ObfuscationProfileRef()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ObfuscationProfileRef',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.censor.v1'),
      createEmptyInstance: ObfuscationProfileRef.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ObfuscationProfileRef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ObfuscationProfileRef copyWith(void Function(ObfuscationProfileRef) updates) =>
      super.copyWith((message) => updates(message as ObfuscationProfileRef)) as ObfuscationProfileRef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ObfuscationProfileRef() / ObfuscationProfileRef.new instead')
  static ObfuscationProfileRef create() => ObfuscationProfileRef._();
  static $pb.GeneratedMessage $_createMessage() => ObfuscationProfileRef._();
  @$core.override
  ObfuscationProfileRef createEmptyInstance() => ObfuscationProfileRef._();
  @$core.pragma('dart2js:noInline')
  static ObfuscationProfileRef getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ObfuscationProfileRef>(ObfuscationProfileRef.$_createMessage);
  static ObfuscationProfileRef? _defaultInstance;
}

class CensorshipVerdict extends $pb.GeneratedMessage {
  factory CensorshipVerdict() => CensorshipVerdict._();

  CensorshipVerdict._();

  factory CensorshipVerdict.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CensorshipVerdict()..mergeFromBuffer(data, registry);
  factory CensorshipVerdict.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CensorshipVerdict()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CensorshipVerdict',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.censor.v1'),
      createEmptyInstance: CensorshipVerdict.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CensorshipVerdict clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CensorshipVerdict copyWith(void Function(CensorshipVerdict) updates) =>
      super.copyWith((message) => updates(message as CensorshipVerdict)) as CensorshipVerdict;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CensorshipVerdict() / CensorshipVerdict.new instead')
  static CensorshipVerdict create() => CensorshipVerdict._();
  static $pb.GeneratedMessage $_createMessage() => CensorshipVerdict._();
  @$core.override
  CensorshipVerdict createEmptyInstance() => CensorshipVerdict._();
  @$core.pragma('dart2js:noInline')
  static CensorshipVerdict getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CensorshipVerdict>(CensorshipVerdict.$_createMessage);
  static CensorshipVerdict? _defaultInstance;
}

class DetectCensorshipRequest extends $pb.GeneratedMessage {
  factory DetectCensorshipRequest() => DetectCensorshipRequest._();

  DetectCensorshipRequest._();

  factory DetectCensorshipRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DetectCensorshipRequest()..mergeFromBuffer(data, registry);
  factory DetectCensorshipRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DetectCensorshipRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DetectCensorshipRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.censor.v1'),
      createEmptyInstance: DetectCensorshipRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetectCensorshipRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetectCensorshipRequest copyWith(void Function(DetectCensorshipRequest) updates) =>
      super.copyWith((message) => updates(message as DetectCensorshipRequest)) as DetectCensorshipRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DetectCensorshipRequest() / DetectCensorshipRequest.new instead')
  static DetectCensorshipRequest create() => DetectCensorshipRequest._();
  static $pb.GeneratedMessage $_createMessage() => DetectCensorshipRequest._();
  @$core.override
  DetectCensorshipRequest createEmptyInstance() => DetectCensorshipRequest._();
  @$core.pragma('dart2js:noInline')
  static DetectCensorshipRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DetectCensorshipRequest>(DetectCensorshipRequest.$_createMessage);
  static DetectCensorshipRequest? _defaultInstance;
}

class DetectCensorshipResponse extends $pb.GeneratedMessage {
  factory DetectCensorshipResponse() => DetectCensorshipResponse._();

  DetectCensorshipResponse._();

  factory DetectCensorshipResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DetectCensorshipResponse()..mergeFromBuffer(data, registry);
  factory DetectCensorshipResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DetectCensorshipResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DetectCensorshipResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.censor.v1'),
      createEmptyInstance: DetectCensorshipResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetectCensorshipResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DetectCensorshipResponse copyWith(void Function(DetectCensorshipResponse) updates) =>
      super.copyWith((message) => updates(message as DetectCensorshipResponse)) as DetectCensorshipResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DetectCensorshipResponse() / DetectCensorshipResponse.new instead')
  static DetectCensorshipResponse create() => DetectCensorshipResponse._();
  static $pb.GeneratedMessage $_createMessage() => DetectCensorshipResponse._();
  @$core.override
  DetectCensorshipResponse createEmptyInstance() => DetectCensorshipResponse._();
  @$core.pragma('dart2js:noInline')
  static DetectCensorshipResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DetectCensorshipResponse>(DetectCensorshipResponse.$_createMessage);
  static DetectCensorshipResponse? _defaultInstance;
}

const $core.bool _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
