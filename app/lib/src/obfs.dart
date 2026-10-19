// Hand-written client and model for proto/sora/obfs/v1/obfs.proto
// (sora.obfs.v1.ObfsControl): traffic obfuscation — uTLS fingerprints,
// TLS fragmentation and jitter.
//
// The message classes follow the protoc-gen-dart output pattern exactly;
// replace with generated code once protoc runs against the obfs proto.
// The client mirrors the hand-wired BenchmarkServers precedent in
// core_control.pbgrpc.dart: a core without the service answers
// UNIMPLEMENTED and the app degrades gracefully (see Sora.getObfsCapabilities
// and Sora.applyObfsProfile).
//
// Wire notes, read from the spec:
// - Neither RPC carries the control authenticator (the messages have no
//   field for it); auth rides the channel handshake like every other call.
// - Clients must negotiate API 1.11 before calling; older cores fail the
//   call at the transport, which the app treats as "capabilities unknown".
// - fake_sni exists on the wire but has no app UI: it is dangerous
//   (handshakes fail where the server validates SNI) and was not asked for.

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:convert';
import 'dart:core' as $core;

import 'package:flutter/foundation.dart';
import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'generated/sora/core/v1/core_control.pb.dart' show ApiVersion, SoraError;

const $core.bool _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
const $core.bool _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
const $core.bool _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');

/// uTLS ClientHello parrot. Names are the canonical ones from
/// core/engine/fingerprint.go.
class UtlsProfile extends $pb.ProtobufEnum {
  static const UtlsProfile UTLS_PROFILE_UNSPECIFIED =
      UtlsProfile._(0, _omitEnumNames ? '' : 'UTLS_PROFILE_UNSPECIFIED');
  static const UtlsProfile UTLS_PROFILE_CHROME = UtlsProfile._(1, _omitEnumNames ? '' : 'UTLS_PROFILE_CHROME');
  static const UtlsProfile UTLS_PROFILE_FIREFOX = UtlsProfile._(2, _omitEnumNames ? '' : 'UTLS_PROFILE_FIREFOX');
  static const UtlsProfile UTLS_PROFILE_SAFARI = UtlsProfile._(3, _omitEnumNames ? '' : 'UTLS_PROFILE_SAFARI');
  static const UtlsProfile UTLS_PROFILE_IOS = UtlsProfile._(4, _omitEnumNames ? '' : 'UTLS_PROFILE_IOS');
  static const UtlsProfile UTLS_PROFILE_ANDROID = UtlsProfile._(5, _omitEnumNames ? '' : 'UTLS_PROFILE_ANDROID');
  static const UtlsProfile UTLS_PROFILE_EDGE = UtlsProfile._(6, _omitEnumNames ? '' : 'UTLS_PROFILE_EDGE');
  static const UtlsProfile UTLS_PROFILE_360 = UtlsProfile._(7, _omitEnumNames ? '' : 'UTLS_PROFILE_360');
  static const UtlsProfile UTLS_PROFILE_QQ = UtlsProfile._(8, _omitEnumNames ? '' : 'UTLS_PROFILE_QQ');
  static const UtlsProfile UTLS_PROFILE_RANDOM = UtlsProfile._(9, _omitEnumNames ? '' : 'UTLS_PROFILE_RANDOM');
  static const UtlsProfile UTLS_PROFILE_RANDOMIZED =
      UtlsProfile._(10, _omitEnumNames ? '' : 'UTLS_PROFILE_RANDOMIZED');

  static const $core.List<UtlsProfile> values = <UtlsProfile>[
    UTLS_PROFILE_UNSPECIFIED,
    UTLS_PROFILE_CHROME,
    UTLS_PROFILE_FIREFOX,
    UTLS_PROFILE_SAFARI,
    UTLS_PROFILE_IOS,
    UTLS_PROFILE_ANDROID,
    UTLS_PROFILE_EDGE,
    UTLS_PROFILE_360,
    UTLS_PROFILE_QQ,
    UTLS_PROFILE_RANDOM,
    UTLS_PROFILE_RANDOMIZED,
  ];

  static final $core.List<UtlsProfile?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 10);
  static UtlsProfile? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const UtlsProfile._(super.value, super.name);
}

/// Curated obfuscation starting point. Explicit fields always win over the
/// preset, so a preset plus overrides is a custom profile.
class ObfsPreset extends $pb.ProtobufEnum {
  static const ObfsPreset OBFS_PRESET_UNSPECIFIED =
      ObfsPreset._(0, _omitEnumNames ? '' : 'OBFS_PRESET_UNSPECIFIED');
  static const ObfsPreset OBFS_PRESET_OFF = ObfsPreset._(1, _omitEnumNames ? '' : 'OBFS_PRESET_OFF');
  static const ObfsPreset OBFS_PRESET_LIGHT = ObfsPreset._(2, _omitEnumNames ? '' : 'OBFS_PRESET_LIGHT');
  static const ObfsPreset OBFS_PRESET_BALANCED = ObfsPreset._(3, _omitEnumNames ? '' : 'OBFS_PRESET_BALANCED');
  static const ObfsPreset OBFS_PRESET_AGGRESSIVE =
      ObfsPreset._(4, _omitEnumNames ? '' : 'OBFS_PRESET_AGGRESSIVE');

  static const $core.List<ObfsPreset> values = <ObfsPreset>[
    OBFS_PRESET_UNSPECIFIED,
    OBFS_PRESET_OFF,
    OBFS_PRESET_LIGHT,
    OBFS_PRESET_BALANCED,
    OBFS_PRESET_AGGRESSIVE,
  ];

  static final $core.List<ObfsPreset?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 4);
  static ObfsPreset? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ObfsPreset._(super.value, super.name);
}

/// How proxy handshakes should look on the wire. Empty (preset OFF)
/// disables the suite.
class ObfuscationProfile extends $pb.GeneratedMessage {
  factory ObfuscationProfile({
    ObfsPreset? preset,
    UtlsProfile? utlsProfile,
    $core.Iterable<$core.int>? fragSizes,
    $core.int? fragDelayMs,
    $core.int? jitterMs,
    $core.String? fakeSni,
  }) {
    final result = ObfuscationProfile._();
    if (preset != null) result.preset = preset;
    if (utlsProfile != null) result.utlsProfile = utlsProfile;
    if (fragSizes != null) result.fragSizes.addAll(fragSizes);
    if (fragDelayMs != null) result.fragDelayMs = fragDelayMs;
    if (jitterMs != null) result.jitterMs = jitterMs;
    if (fakeSni != null) result.fakeSni = fakeSni;
    return result;
  }

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
    ..aE<ObfsPreset>(1, _omitFieldNames ? '' : 'preset', enumValues: ObfsPreset.values)
    ..aE<UtlsProfile>(2, _omitFieldNames ? '' : 'utlsProfile', enumValues: UtlsProfile.values)
    ..p<$core.int>(3, _omitFieldNames ? '' : 'fragSizes', $pb.PbFieldType.PU3)
    ..aI(4, _omitFieldNames ? '' : 'fragDelayMs', fieldType: $pb.PbFieldType.OU3)
    ..aI(5, _omitFieldNames ? '' : 'jitterMs', fieldType: $pb.PbFieldType.OU3)
    ..aOS(6, _omitFieldNames ? '' : 'fakeSni')
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

  /// A preset to start from; explicit fields override it. UNSPECIFIED with
  /// explicit fields is a fully custom profile.
  @$pb.TagNumber(1)
  ObfsPreset get preset => $_getN(0);
  @$pb.TagNumber(1)
  set preset(ObfsPreset value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasPreset() => $_has(0);
  @$pb.TagNumber(1)
  void clearPreset() => $_clearField(1);

  /// uTLS ClientHello fingerprint. UNSPECIFIED keeps whatever the
  /// subscription or the engine default sets.
  @$pb.TagNumber(2)
  UtlsProfile get utlsProfile => $_getN(1);
  @$pb.TagNumber(2)
  set utlsProfile(UtlsProfile value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasUtlsProfile() => $_has(1);
  @$pb.TagNumber(2)
  void clearUtlsProfile() => $_clearField(2);

  /// TLS fragmentation: the ClientHello is split into TCP segments of
  /// these sizes in bytes. Empty disables fragmentation.
  @$pb.TagNumber(3)
  $core.List<$core.int> get fragSizes => $_getList(2);

  /// Pause between fragments in milliseconds. Zero means no artificial
  /// pause; engines without a delay knob ignore it.
  @$pb.TagNumber(4)
  $core.int get fragDelayMs => $_getIZ(3);
  @$pb.TagNumber(4)
  set fragDelayMs($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFragDelayMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearFragDelayMs() => $_clearField(4);

  /// Random jitter added on top of frag_delay_ms. Needs frag_delay_ms > 0.
  @$pb.TagNumber(5)
  $core.int get jitterMs => $_getIZ(4);
  @$pb.TagNumber(5)
  set jitterMs($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasJitterMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearJitterMs() => $_clearField(5);

  /// Decoy SNI. No app UI sets this: servers that validate SNI fail the
  /// handshake, so it stays empty unless a future careful flow needs it.
  @$pb.TagNumber(6)
  $core.String get fakeSni => $_getSZ(5);
  @$pb.TagNumber(6)
  set fakeSni($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasFakeSni() => $_has(5);
  @$pb.TagNumber(6)
  void clearFakeSni() => $_clearField(6);
}

class ApplyObfsProfileRequest extends $pb.GeneratedMessage {
  factory ApplyObfsProfileRequest({
    ApiVersion? apiVersion,
    ObfuscationProfile? profile,
  }) {
    final result = ApplyObfsProfileRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (profile != null) result.profile = profile;
    return result;
  }

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
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..aOM<ObfuscationProfile>(2, _omitFieldNames ? '' : 'profile', subBuilder: ObfuscationProfile.$_createMessage)
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

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  ObfuscationProfile get profile => $_getN(1);
  @$pb.TagNumber(2)
  set profile(ObfuscationProfile value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasProfile() => $_has(1);
  @$pb.TagNumber(2)
  void clearProfile() => $_clearField(2);
  @$pb.TagNumber(2)
  ObfuscationProfile ensureProfile() => $_ensure(1);
}

class ApplyObfsProfileResponse extends $pb.GeneratedMessage {
  factory ApplyObfsProfileResponse({
    ObfuscationProfile? applied,
    $core.Iterable<$core.String>? compatibleEngines,
    $core.Iterable<$core.String>? warnings,
    SoraError? error,
  }) {
    final result = ApplyObfsProfileResponse._();
    if (applied != null) result.applied = applied;
    if (compatibleEngines != null) result.compatibleEngines.addAll(compatibleEngines);
    if (warnings != null) result.warnings.addAll(warnings);
    if (error != null) result.error = error;
    return result;
  }

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
    ..aOM<ObfuscationProfile>(1, _omitFieldNames ? '' : 'applied', subBuilder: ObfuscationProfile.$_createMessage)
    ..pPS(2, _omitFieldNames ? '' : 'compatibleEngines')
    ..pPS(3, _omitFieldNames ? '' : 'warnings')
    ..aOM<SoraError>(4, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
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

  /// The profile as stored: preset expanded, fields normalized.
  @$pb.TagNumber(1)
  ObfuscationProfile get applied => $_getN(0);
  @$pb.TagNumber(1)
  set applied(ObfuscationProfile value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApplied() => $_has(0);
  @$pb.TagNumber(1)
  void clearApplied() => $_clearField(1);
  @$pb.TagNumber(1)
  ObfuscationProfile ensureApplied() => $_ensure(0);

  /// Engine names able to carry every feature the profile enables.
  @$pb.TagNumber(2)
  $core.List<$core.String> get compatibleEngines => $_getList(1);

  /// Non-fatal notes, surfaced in the UI.
  @$pb.TagNumber(3)
  $core.List<$core.String> get warnings => $_getList(2);

  @$pb.TagNumber(4)
  SoraError get error => $_getN(3);
  @$pb.TagNumber(4)
  set error(SoraError value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
  @$pb.TagNumber(4)
  SoraError ensureError() => $_ensure(3);
}

class GetObfsCapabilitiesRequest extends $pb.GeneratedMessage {
  factory GetObfsCapabilitiesRequest({
    ApiVersion? apiVersion,
  }) {
    final result = GetObfsCapabilitiesRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    return result;
  }

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
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
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

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);
}

class GetObfsCapabilitiesResponse extends $pb.GeneratedMessage {
  factory GetObfsCapabilitiesResponse({
    $core.Iterable<EngineObfsCapabilities>? engines,
    SoraError? error,
  }) {
    final result = GetObfsCapabilitiesResponse._();
    if (engines != null) result.engines.addAll(engines);
    if (error != null) result.error = error;
    return result;
  }

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
    ..pPM<EngineObfsCapabilities>(1, _omitFieldNames ? '' : 'engines',
        subBuilder: EngineObfsCapabilities.$_createMessage)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
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

  @$pb.TagNumber(1)
  $core.List<EngineObfsCapabilities> get engines => $_getList(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

/// What one installed engine really supports, read from the renderers in
/// core/engine, not from marketing pages.
class EngineObfsCapabilities extends $pb.GeneratedMessage {
  factory EngineObfsCapabilities({
    $core.String? engine,
    $core.bool? utls,
    $core.Iterable<$core.String>? utlsProfiles,
    $core.bool? supportsVersionedParrots,
    $core.bool? fragmentation,
    $core.bool? fragmentParams,
    $core.bool? jitter,
    $core.bool? fakeSni,
  }) {
    final result = EngineObfsCapabilities._();
    if (engine != null) result.engine = engine;
    if (utls != null) result.utls = utls;
    if (utlsProfiles != null) result.utlsProfiles.addAll(utlsProfiles);
    if (supportsVersionedParrots != null) result.supportsVersionedParrots = supportsVersionedParrots;
    if (fragmentation != null) result.fragmentation = fragmentation;
    if (fragmentParams != null) result.fragmentParams = fragmentParams;
    if (jitter != null) result.jitter = jitter;
    if (fakeSni != null) result.fakeSni = fakeSni;
    return result;
  }

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
    ..aOS(1, _omitFieldNames ? '' : 'engine')
    ..aOB(2, _omitFieldNames ? '' : 'utls')
    ..pPS(3, _omitFieldNames ? '' : 'utlsProfiles')
    ..aOB(4, _omitFieldNames ? '' : 'supportsVersionedParrots')
    ..aOB(5, _omitFieldNames ? '' : 'fragmentation')
    ..aOB(6, _omitFieldNames ? '' : 'fragmentParams')
    ..aOB(7, _omitFieldNames ? '' : 'jitter')
    ..aOB(8, _omitFieldNames ? '' : 'fakeSni')
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

  /// "sing-box", "xray" or "mihomo".
  @$pb.TagNumber(1)
  $core.String get engine => $_getSZ(0);
  @$pb.TagNumber(1)
  set engine($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEngine() => $_has(0);
  @$pb.TagNumber(1)
  void clearEngine() => $_clearField(1);

  /// The engine can send a uTLS ClientHello parrot.
  @$pb.TagNumber(2)
  $core.bool get utls => $_getBF(1);
  @$pb.TagNumber(2)
  set utls($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUtls() => $_has(1);
  @$pb.TagNumber(2)
  void clearUtls() => $_clearField(2);

  /// Canonical profile names the engine accepts (see UtlsProfile).
  @$pb.TagNumber(3)
  $core.List<$core.String> get utlsProfiles => $_getList(2);

  /// The engine accepts versioned parrots such as "hellochrome_155".
  @$pb.TagNumber(4)
  $core.bool get supportsVersionedParrots => $_getBF(3);
  @$pb.TagNumber(4)
  set supportsVersionedParrots($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSupportsVersionedParrots() => $_has(3);
  @$pb.TagNumber(4)
  void clearSupportsVersionedParrots() => $_clearField(4);

  /// The engine can split the TLS ClientHello across TCP segments.
  @$pb.TagNumber(5)
  $core.bool get fragmentation => $_getBF(4);
  @$pb.TagNumber(5)
  set fragmentation($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasFragmentation() => $_has(4);
  @$pb.TagNumber(5)
  void clearFragmentation() => $_clearField(5);

  /// The engine tunes fragment sizes and delays, not just on/off.
  @$pb.TagNumber(6)
  $core.bool get fragmentParams => $_getBF(5);
  @$pb.TagNumber(6)
  set fragmentParams($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasFragmentParams() => $_has(5);
  @$pb.TagNumber(6)
  void clearFragmentParams() => $_clearField(6);

  /// The engine randomizes the inter-fragment delay.
  @$pb.TagNumber(7)
  $core.bool get jitter => $_getBF(6);
  @$pb.TagNumber(7)
  set jitter($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasJitter() => $_has(6);
  @$pb.TagNumber(7)
  void clearJitter() => $_clearField(7);

  /// The engine can send a decoy SNI. Displayed only; the app never sets it.
  @$pb.TagNumber(8)
  $core.bool get fakeSni => $_getBF(7);
  @$pb.TagNumber(8)
  set fakeSni($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasFakeSni() => $_has(7);
  @$pb.TagNumber(8)
  void clearFakeSni() => $_clearField(8);
}

/// Hand-written client for sora.obfs.v1.ObfsControl.
class ObfsControlClient extends $grpc.Client {
  ObfsControlClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<ApplyObfsProfileResponse> applyObfsProfile(
    ApplyObfsProfileRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$applyObfsProfile, request, options: options);
  }

  $grpc.ResponseFuture<GetObfsCapabilitiesResponse> getObfsCapabilities(
    GetObfsCapabilitiesRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getObfsCapabilities, request, options: options);
  }

  static final _$applyObfsProfile = $grpc.ClientMethod<ApplyObfsProfileRequest, ApplyObfsProfileResponse>(
    '/sora.obfs.v1.ObfsControl/ApplyObfsProfile',
    (ApplyObfsProfileRequest value) => value.writeToBuffer(),
    ApplyObfsProfileResponse.fromBuffer,
  );
  static final _$getObfsCapabilities = $grpc.ClientMethod<GetObfsCapabilitiesRequest, GetObfsCapabilitiesResponse>(
    '/sora.obfs.v1.ObfsControl/GetObfsCapabilities',
    (GetObfsCapabilitiesRequest value) => value.writeToBuffer(),
    GetObfsCapabilitiesResponse.fromBuffer,
  );
}

// ---------------------------------------------------------------------------
// App model.
// ---------------------------------------------------------------------------

/// Preset ids for [ObfsSettings.preset]. The wire presets LIGHT and OFF both
/// exist; "custom" is UNSPECIFIED with explicit fields.
const obfsPresetOff = 'off';
const obfsPresetLight = 'light';
const obfsPresetBalanced = 'balanced';
const obfsPresetAggressive = 'aggressive';
const obfsPresetCustom = 'custom';

/// All preset ids the model accepts. The UI offers every id but "light".
const obfsPresets = <String>[obfsPresetAggressive, obfsPresetBalanced, obfsPresetLight, obfsPresetOff, obfsPresetCustom];

/// uTLS profile ids in UI order; '' means "auto" (UTLS_PROFILE_UNSPECIFIED:
/// the subscription or the engine default decides).
const obfsUtlsAuto = '';
const obfsUtlsProfiles = <String>[
  'chrome',
  'firefox',
  'safari',
  'ios',
  'android',
  'edge',
  '360',
  'qq',
  'random',
  'randomized',
];

/// Fragment sizes (bytes) sent when the user enables fragmentation without a
/// preset. Mirrors the legacy Xray "100-200" default range in the new
/// grammar; engines with an on/off switch (sing-box) fragment with their own
/// sizes anyway.
const obfsDefaultFragSizes = <int>[100, 200];

/// Delay defaults for a manual jitter toggle: the legacy "10-20" interval
/// range as base delay plus jitter. jitter_ms needs frag_delay_ms > 0.
const obfsDefaultFragDelayMs = 10;
const obfsDefaultJitterMs = 10;

/// Negotiated API minor required by ObfsControl (spec: "Since 1.11").
const obfsMinApiMinor = 11;

/// Maps a UI uTLS profile id to the wire enum; null when unknown.
UtlsProfile? utlsProfileOf(String name) => switch (name) {
      '' => UtlsProfile.UTLS_PROFILE_UNSPECIFIED,
      'chrome' => UtlsProfile.UTLS_PROFILE_CHROME,
      'firefox' => UtlsProfile.UTLS_PROFILE_FIREFOX,
      'safari' => UtlsProfile.UTLS_PROFILE_SAFARI,
      'ios' => UtlsProfile.UTLS_PROFILE_IOS,
      'android' => UtlsProfile.UTLS_PROFILE_ANDROID,
      'edge' => UtlsProfile.UTLS_PROFILE_EDGE,
      '360' => UtlsProfile.UTLS_PROFILE_360,
      'qq' => UtlsProfile.UTLS_PROFILE_QQ,
      'random' => UtlsProfile.UTLS_PROFILE_RANDOM,
      'randomized' => UtlsProfile.UTLS_PROFILE_RANDOMIZED,
      _ => null,
    };

/// Outcome of [Sora.applyObfsProfile]: engines able to carry the profile and
/// the non-fatal notes the spec asks the UI to surface.
typedef ObfsApplyResult = ({List<String> compatibleEngines, List<String> warnings});

/// App-side obfuscation settings, persisted as JSON in settings (key
/// "obfs"). Named presets travel to the core as preset-only and are
/// expanded there; any manual edit turns the profile custom.
class ObfsSettings extends ChangeNotifier {
  ObfsSettings(this._read, this._write) {
    _load();
  }

  final String Function() _read;
  final void Function(String) _write;

  String _preset = obfsPresetOff;
  String _utls = obfsUtlsAuto;
  bool _fragment = false;
  bool _jitter = false;

  /// 'off', 'light', 'balanced', 'aggressive' or 'custom'.
  String get preset => _preset;

  /// uTLS profile id, '' for auto.
  String get utls => _utls;

  bool get fragment => _fragment;
  bool get jitter => _jitter;

  void _load() {
    final raw = _read();
    if (raw.isEmpty) return;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return;
      final preset = json['preset'];
      if (preset is String && obfsPresets.contains(preset)) _preset = preset;
      final utls = json['utls'];
      if (utls is String && (utls.isEmpty || utlsProfileOf(utls) != null)) _utls = utls;
      final fragment = json['fragment'];
      if (fragment is bool) _fragment = fragment;
      final jitter = json['jitter'];
      if (jitter is bool) _jitter = jitter;
      // Repair stores written before the jitter setter implied fragmentation.
      if (_jitter && !_fragment) _fragment = true;
    } catch (_) {
      // Corrupt payload: keep defaults rather than crash the screen.
    }
  }

  void _save() {
    _write(jsonEncode({'preset': _preset, 'utls': _utls, 'fragment': _fragment, 'jitter': _jitter}));
  }

  /// Applies a named preset. Manual edits go through the setters below and
  /// flip the preset to custom.
  void applyPreset(String preset) {
    if (!obfsPresets.contains(preset) || _preset == preset) return;
    _preset = preset;
    _save();
    notifyListeners();
  }

  set utls(String value) {
    if (_utls == value) return;
    _utls = value;
    _preset = obfsPresetCustom;
    _save();
    notifyListeners();
  }

  set fragment(bool value) {
    if (_fragment == value) return;
    _fragment = value;
    // Jitter is meaningless without fragmentation (jitter_ms needs
    // frag_delay_ms > 0); keep the model consistent so the UI never shows
    // an enabled-but-dead toggle.
    if (!value) _jitter = false;
    _preset = obfsPresetCustom;
    _save();
    notifyListeners();
  }

  set jitter(bool value) {
    // Jitter is dead without fragmentation (jitter_ms needs frag_delay_ms >
    // 0), so enabling jitter implies fragmentation — mirroring how disabling
    // fragmentation clears jitter below. Without this, {jitter: true,
    // fragment: false} persists a toggle the wire profile silently ignores.
    if (_jitter == value && (!value || _fragment)) return;
    if (value) _fragment = true;
    _jitter = value;
    _preset = obfsPresetCustom;
    _save();
    notifyListeners();
  }

  /// Builds the wire profile. Named presets travel preset-only (the core
  /// expands them); custom carries explicit fields. fake_sni is never set
  /// by the app UI.
  ObfuscationProfile toProfile() {
    final profile = ObfuscationProfile();
    switch (_preset) {
      case obfsPresetOff:
        profile.preset = ObfsPreset.OBFS_PRESET_OFF;
      case obfsPresetLight:
        profile.preset = ObfsPreset.OBFS_PRESET_LIGHT;
      case obfsPresetBalanced:
        profile.preset = ObfsPreset.OBFS_PRESET_BALANCED;
      case obfsPresetAggressive:
        profile.preset = ObfsPreset.OBFS_PRESET_AGGRESSIVE;
      default:
        final utlsProfile = utlsProfileOf(_utls);
        if (utlsProfile != null) profile.utlsProfile = utlsProfile;
        if (_fragment) {
          profile.fragSizes.addAll(obfsDefaultFragSizes);
          if (_jitter) {
            profile.fragDelayMs = obfsDefaultFragDelayMs;
            profile.jitterMs = obfsDefaultJitterMs;
          }
        }
    }
    return profile;
  }
}
