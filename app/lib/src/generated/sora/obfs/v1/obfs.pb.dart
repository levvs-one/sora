// This is a generated file - do not edit.
//
// Generated from sora/obfs/v1/obfs.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'obfs.pbenum.dart';

class ObfuscationProfile extends $pb.GeneratedMessage {
  factory ObfuscationProfile() => ObfuscationProfile._();

  ObfuscationProfile._();

  factory ObfuscationProfile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ObfuscationProfile()..mergeFromBuffer(data, registry);
  factory ObfuscationProfile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ObfuscationProfile()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ObfuscationProfile',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.obfs.v1'),
      createEmptyInstance: ObfuscationProfile.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ObfuscationProfile clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ObfuscationProfile copyWith(void Function(ObfuscationProfile) updates) =>
      super.copyWith((message) => updates(message as ObfuscationProfile)) as ObfuscationProfile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ObfuscationProfile() / ObfuscationProfile.new instead')
  static ObfuscationProfile create() => ObfuscationProfile._();
  static $pb.GeneratedMessage $_createMessage() => ObfuscationProfile._();
  @$core.override
  ObfuscationProfile createEmptyInstance() => ObfuscationProfile._();
  @$core.pragma('dart2js:noInline')
  static ObfuscationProfile getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ObfuscationProfile>(ObfuscationProfile.$_createMessage);
  static ObfuscationProfile? _defaultInstance;
}

class ApplyObfsProfileRequest extends $pb.GeneratedMessage {
  factory ApplyObfsProfileRequest() => ApplyObfsProfileRequest._();

  ApplyObfsProfileRequest._();

  factory ApplyObfsProfileRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApplyObfsProfileRequest()..mergeFromBuffer(data, registry);
  factory ApplyObfsProfileRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApplyObfsProfileRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplyObfsProfileRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.obfs.v1'),
      createEmptyInstance: ApplyObfsProfileRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyObfsProfileRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyObfsProfileRequest copyWith(void Function(ApplyObfsProfileRequest) updates) =>
      super.copyWith((message) => updates(message as ApplyObfsProfileRequest)) as ApplyObfsProfileRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ApplyObfsProfileRequest() / ApplyObfsProfileRequest.new instead')
  static ApplyObfsProfileRequest create() => ApplyObfsProfileRequest._();
  static $pb.GeneratedMessage $_createMessage() => ApplyObfsProfileRequest._();
  @$core.override
  ApplyObfsProfileRequest createEmptyInstance() => ApplyObfsProfileRequest._();
  @$core.pragma('dart2js:noInline')
  static ApplyObfsProfileRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApplyObfsProfileRequest>(ApplyObfsProfileRequest.$_createMessage);
  static ApplyObfsProfileRequest? _defaultInstance;
}

class ApplyObfsProfileResponse extends $pb.GeneratedMessage {
  factory ApplyObfsProfileResponse() => ApplyObfsProfileResponse._();

  ApplyObfsProfileResponse._();

  factory ApplyObfsProfileResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApplyObfsProfileResponse()..mergeFromBuffer(data, registry);
  factory ApplyObfsProfileResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApplyObfsProfileResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplyObfsProfileResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.obfs.v1'),
      createEmptyInstance: ApplyObfsProfileResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyObfsProfileResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyObfsProfileResponse copyWith(void Function(ApplyObfsProfileResponse) updates) =>
      super.copyWith((message) => updates(message as ApplyObfsProfileResponse)) as ApplyObfsProfileResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ApplyObfsProfileResponse() / ApplyObfsProfileResponse.new instead')
  static ApplyObfsProfileResponse create() => ApplyObfsProfileResponse._();
  static $pb.GeneratedMessage $_createMessage() => ApplyObfsProfileResponse._();
  @$core.override
  ApplyObfsProfileResponse createEmptyInstance() => ApplyObfsProfileResponse._();
  @$core.pragma('dart2js:noInline')
  static ApplyObfsProfileResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApplyObfsProfileResponse>(ApplyObfsProfileResponse.$_createMessage);
  static ApplyObfsProfileResponse? _defaultInstance;
}

class GetObfsCapabilitiesRequest extends $pb.GeneratedMessage {
  factory GetObfsCapabilitiesRequest() => GetObfsCapabilitiesRequest._();

  GetObfsCapabilitiesRequest._();

  factory GetObfsCapabilitiesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetObfsCapabilitiesRequest()..mergeFromBuffer(data, registry);
  factory GetObfsCapabilitiesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetObfsCapabilitiesRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetObfsCapabilitiesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.obfs.v1'),
      createEmptyInstance: GetObfsCapabilitiesRequest.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetObfsCapabilitiesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetObfsCapabilitiesRequest copyWith(void Function(GetObfsCapabilitiesRequest) updates) =>
      super.copyWith((message) => updates(message as GetObfsCapabilitiesRequest)) as GetObfsCapabilitiesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetObfsCapabilitiesRequest() / GetObfsCapabilitiesRequest.new instead')
  static GetObfsCapabilitiesRequest create() => GetObfsCapabilitiesRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetObfsCapabilitiesRequest._();
  @$core.override
  GetObfsCapabilitiesRequest createEmptyInstance() => GetObfsCapabilitiesRequest._();
  @$core.pragma('dart2js:noInline')
  static GetObfsCapabilitiesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetObfsCapabilitiesRequest>(GetObfsCapabilitiesRequest.$_createMessage);
  static GetObfsCapabilitiesRequest? _defaultInstance;
}

class GetObfsCapabilitiesResponse extends $pb.GeneratedMessage {
  factory GetObfsCapabilitiesResponse() => GetObfsCapabilitiesResponse._();

  GetObfsCapabilitiesResponse._();

  factory GetObfsCapabilitiesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetObfsCapabilitiesResponse()..mergeFromBuffer(data, registry);
  factory GetObfsCapabilitiesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetObfsCapabilitiesResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetObfsCapabilitiesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.obfs.v1'),
      createEmptyInstance: GetObfsCapabilitiesResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetObfsCapabilitiesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetObfsCapabilitiesResponse copyWith(void Function(GetObfsCapabilitiesResponse) updates) =>
      super.copyWith((message) => updates(message as GetObfsCapabilitiesResponse)) as GetObfsCapabilitiesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetObfsCapabilitiesResponse() / GetObfsCapabilitiesResponse.new instead')
  static GetObfsCapabilitiesResponse create() => GetObfsCapabilitiesResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetObfsCapabilitiesResponse._();
  @$core.override
  GetObfsCapabilitiesResponse createEmptyInstance() => GetObfsCapabilitiesResponse._();
  @$core.pragma('dart2js:noInline')
  static GetObfsCapabilitiesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetObfsCapabilitiesResponse>(GetObfsCapabilitiesResponse.$_createMessage);
  static GetObfsCapabilitiesResponse? _defaultInstance;
}

class EngineObfsCapabilities extends $pb.GeneratedMessage {
  factory EngineObfsCapabilities() => EngineObfsCapabilities._();

  EngineObfsCapabilities._();

  factory EngineObfsCapabilities.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EngineObfsCapabilities()..mergeFromBuffer(data, registry);
  factory EngineObfsCapabilities.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EngineObfsCapabilities()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EngineObfsCapabilities',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.obfs.v1'),
      createEmptyInstance: EngineObfsCapabilities.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineObfsCapabilities clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineObfsCapabilities copyWith(void Function(EngineObfsCapabilities) updates) =>
      super.copyWith((message) => updates(message as EngineObfsCapabilities)) as EngineObfsCapabilities;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use EngineObfsCapabilities() / EngineObfsCapabilities.new instead')
  static EngineObfsCapabilities create() => EngineObfsCapabilities._();
  static $pb.GeneratedMessage $_createMessage() => EngineObfsCapabilities._();
  @$core.override
  EngineObfsCapabilities createEmptyInstance() => EngineObfsCapabilities._();
  @$core.pragma('dart2js:noInline')
  static EngineObfsCapabilities getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EngineObfsCapabilities>(EngineObfsCapabilities.$_createMessage);
  static EngineObfsCapabilities? _defaultInstance;
}

const $core.bool _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
