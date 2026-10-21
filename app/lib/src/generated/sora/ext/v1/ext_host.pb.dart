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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart'
    as $1;

import '../../core/v1/core_control.pb.dart' as $2;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class MintTokenRequest extends $pb.GeneratedMessage {
  factory MintTokenRequest({
    $core.List<$core.int>? controlToken,
    $core.String? extensionId,
    $core.Iterable<$core.String>? permissions,
  }) {
    final result = create();
    if (controlToken != null) result.controlToken = controlToken;
    if (extensionId != null) result.extensionId = extensionId;
    if (permissions != null) result.permissions.addAll(permissions);
    return result;
  }

  MintTokenRequest._();

  factory MintTokenRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MintTokenRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MintTokenRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'controlToken', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'extensionId')
    ..pPS(3, _omitFieldNames ? '' : 'permissions')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MintTokenRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MintTokenRequest copyWith(void Function(MintTokenRequest) updates) =>
      super.copyWith((message) => updates(message as MintTokenRequest))
          as MintTokenRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MintTokenRequest create() => MintTokenRequest._();
  @$core.override
  MintTokenRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MintTokenRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MintTokenRequest>(create);
  static MintTokenRequest? _defaultInstance;

  /// The core control token. Proves the caller is the trusted app.
  @$pb.TagNumber(1)
  $core.List<$core.int> get controlToken => $_getN(0);
  @$pb.TagNumber(1)
  set controlToken($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasControlToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearControlToken() => $_clearField(1);

  /// The extension id from its manifest, e.g. "com.example.speedstats".
  @$pb.TagNumber(2)
  $core.String get extensionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set extensionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExtensionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearExtensionId() => $_clearField(2);

  /// The permissions the user granted at install time. Must be a subset of
  /// the registry in core/ext/permissions.go; unknown ids are rejected.
  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get permissions => $_getList(2);
}

class MintTokenResponse extends $pb.GeneratedMessage {
  factory MintTokenResponse({
    $core.List<$core.int>? extensionToken,
  }) {
    final result = create();
    if (extensionToken != null) result.extensionToken = extensionToken;
    return result;
  }

  MintTokenResponse._();

  factory MintTokenResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MintTokenResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MintTokenResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'extensionToken', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MintTokenResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MintTokenResponse copyWith(void Function(MintTokenResponse) updates) =>
      super.copyWith((message) => updates(message as MintTokenResponse))
          as MintTokenResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MintTokenResponse create() => MintTokenResponse._();
  @$core.override
  MintTokenResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static MintTokenResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MintTokenResponse>(create);
  static MintTokenResponse? _defaultInstance;

  /// Opaque 32-byte token. Pass it as extension_token on every other call.
  @$pb.TagNumber(1)
  $core.List<$core.int> get extensionToken => $_getN(0);
  @$pb.TagNumber(1)
  set extensionToken($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExtensionToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtensionToken() => $_clearField(1);
}

class RevokeTokenRequest extends $pb.GeneratedMessage {
  factory RevokeTokenRequest({
    $core.List<$core.int>? controlToken,
    $core.List<$core.int>? extensionToken,
  }) {
    final result = create();
    if (controlToken != null) result.controlToken = controlToken;
    if (extensionToken != null) result.extensionToken = extensionToken;
    return result;
  }

  RevokeTokenRequest._();

  factory RevokeTokenRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RevokeTokenRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RevokeTokenRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'controlToken', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'extensionToken', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeTokenRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeTokenRequest copyWith(void Function(RevokeTokenRequest) updates) =>
      super.copyWith((message) => updates(message as RevokeTokenRequest))
          as RevokeTokenRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RevokeTokenRequest create() => RevokeTokenRequest._();
  @$core.override
  RevokeTokenRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RevokeTokenRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RevokeTokenRequest>(create);
  static RevokeTokenRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get controlToken => $_getN(0);
  @$pb.TagNumber(1)
  set controlToken($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasControlToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearControlToken() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get extensionToken => $_getN(1);
  @$pb.TagNumber(2)
  set extensionToken($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasExtensionToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearExtensionToken() => $_clearField(2);
}

class RevokeTokenResponse extends $pb.GeneratedMessage {
  factory RevokeTokenResponse() => create();

  RevokeTokenResponse._();

  factory RevokeTokenResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RevokeTokenResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RevokeTokenResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeTokenResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeTokenResponse copyWith(void Function(RevokeTokenResponse) updates) =>
      super.copyWith((message) => updates(message as RevokeTokenResponse))
          as RevokeTokenResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RevokeTokenResponse create() => RevokeTokenResponse._();
  @$core.override
  RevokeTokenResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RevokeTokenResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RevokeTokenResponse>(create);
  static RevokeTokenResponse? _defaultInstance;
}

class GetConnectionsRequest extends $pb.GeneratedMessage {
  factory GetConnectionsRequest({
    $core.List<$core.int>? extensionToken,
  }) {
    final result = create();
    if (extensionToken != null) result.extensionToken = extensionToken;
    return result;
  }

  GetConnectionsRequest._();

  factory GetConnectionsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetConnectionsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetConnectionsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'extensionToken', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetConnectionsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetConnectionsRequest copyWith(
          void Function(GetConnectionsRequest) updates) =>
      super.copyWith((message) => updates(message as GetConnectionsRequest))
          as GetConnectionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetConnectionsRequest create() => GetConnectionsRequest._();
  @$core.override
  GetConnectionsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetConnectionsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetConnectionsRequest>(create);
  static GetConnectionsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get extensionToken => $_getN(0);
  @$pb.TagNumber(1)
  set extensionToken($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExtensionToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtensionToken() => $_clearField(1);
}

class ExtensionConnection extends $pb.GeneratedMessage {
  factory ExtensionConnection({
    $core.String? id,
    $core.String? process,
    $core.String? host,
    $fixnum.Int64? upBytes,
    $fixnum.Int64? downBytes,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (process != null) result.process = process;
    if (host != null) result.host = host;
    if (upBytes != null) result.upBytes = upBytes;
    if (downBytes != null) result.downBytes = downBytes;
    return result;
  }

  ExtensionConnection._();

  factory ExtensionConnection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExtensionConnection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExtensionConnection',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'process')
    ..aOS(3, _omitFieldNames ? '' : 'host')
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'upBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(
        5, _omitFieldNames ? '' : 'downBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionConnection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionConnection copyWith(void Function(ExtensionConnection) updates) =>
      super.copyWith((message) => updates(message as ExtensionConnection))
          as ExtensionConnection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExtensionConnection create() => ExtensionConnection._();
  @$core.override
  ExtensionConnection createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExtensionConnection getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExtensionConnection>(create);
  static ExtensionConnection? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Process name only; no PIDs or paths leave the core towards extensions.
  @$pb.TagNumber(2)
  $core.String get process => $_getSZ(1);
  @$pb.TagNumber(2)
  set process($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProcess() => $_has(1);
  @$pb.TagNumber(2)
  void clearProcess() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get host => $_getSZ(2);
  @$pb.TagNumber(3)
  set host($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHost() => $_has(2);
  @$pb.TagNumber(3)
  void clearHost() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get upBytes => $_getI64(3);
  @$pb.TagNumber(4)
  set upBytes($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUpBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearUpBytes() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get downBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set downBytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDownBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearDownBytes() => $_clearField(5);
}

class GetConnectionsResponse extends $pb.GeneratedMessage {
  factory GetConnectionsResponse({
    $core.Iterable<ExtensionConnection>? connections,
  }) {
    final result = create();
    if (connections != null) result.connections.addAll(connections);
    return result;
  }

  GetConnectionsResponse._();

  factory GetConnectionsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetConnectionsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetConnectionsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..pPM<ExtensionConnection>(1, _omitFieldNames ? '' : 'connections',
        subBuilder: ExtensionConnection.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetConnectionsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetConnectionsResponse copyWith(
          void Function(GetConnectionsResponse) updates) =>
      super.copyWith((message) => updates(message as GetConnectionsResponse))
          as GetConnectionsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetConnectionsResponse create() => GetConnectionsResponse._();
  @$core.override
  GetConnectionsResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetConnectionsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetConnectionsResponse>(create);
  static GetConnectionsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ExtensionConnection> get connections => $_getList(0);
}

class GetServersRequest extends $pb.GeneratedMessage {
  factory GetServersRequest({
    $core.List<$core.int>? extensionToken,
  }) {
    final result = create();
    if (extensionToken != null) result.extensionToken = extensionToken;
    return result;
  }

  GetServersRequest._();

  factory GetServersRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetServersRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetServersRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'extensionToken', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetServersRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetServersRequest copyWith(void Function(GetServersRequest) updates) =>
      super.copyWith((message) => updates(message as GetServersRequest))
          as GetServersRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetServersRequest create() => GetServersRequest._();
  @$core.override
  GetServersRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetServersRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetServersRequest>(create);
  static GetServersRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get extensionToken => $_getN(0);
  @$pb.TagNumber(1)
  set extensionToken($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExtensionToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtensionToken() => $_clearField(1);
}

class ExtensionServer extends $pb.GeneratedMessage {
  factory ExtensionServer({
    $core.String? id,
    $core.String? name,
    $core.String? country,
    $fixnum.Int64? latencyMs,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (country != null) result.country = country;
    if (latencyMs != null) result.latencyMs = latencyMs;
    return result;
  }

  ExtensionServer._();

  factory ExtensionServer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExtensionServer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExtensionServer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'country')
    ..aInt64(4, _omitFieldNames ? '' : 'latencyMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionServer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionServer copyWith(void Function(ExtensionServer) updates) =>
      super.copyWith((message) => updates(message as ExtensionServer))
          as ExtensionServer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExtensionServer create() => ExtensionServer._();
  @$core.override
  ExtensionServer createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExtensionServer getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExtensionServer>(create);
  static ExtensionServer? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get country => $_getSZ(2);
  @$pb.TagNumber(3)
  set country($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCountry() => $_has(2);
  @$pb.TagNumber(3)
  void clearCountry() => $_clearField(3);

  /// -1 when unknown.
  @$pb.TagNumber(4)
  $fixnum.Int64 get latencyMs => $_getI64(3);
  @$pb.TagNumber(4)
  set latencyMs($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLatencyMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearLatencyMs() => $_clearField(4);
}

class GetServersResponse extends $pb.GeneratedMessage {
  factory GetServersResponse({
    $core.Iterable<ExtensionServer>? servers,
  }) {
    final result = create();
    if (servers != null) result.servers.addAll(servers);
    return result;
  }

  GetServersResponse._();

  factory GetServersResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetServersResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetServersResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..pPM<ExtensionServer>(1, _omitFieldNames ? '' : 'servers',
        subBuilder: ExtensionServer.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetServersResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetServersResponse copyWith(void Function(GetServersResponse) updates) =>
      super.copyWith((message) => updates(message as GetServersResponse))
          as GetServersResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetServersResponse create() => GetServersResponse._();
  @$core.override
  GetServersResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetServersResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetServersResponse>(create);
  static GetServersResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ExtensionServer> get servers => $_getList(0);
}

class NotifyRequest extends $pb.GeneratedMessage {
  factory NotifyRequest({
    $core.List<$core.int>? extensionToken,
    $core.String? title,
    $core.String? body,
  }) {
    final result = create();
    if (extensionToken != null) result.extensionToken = extensionToken;
    if (title != null) result.title = title;
    if (body != null) result.body = body;
    return result;
  }

  NotifyRequest._();

  factory NotifyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NotifyRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NotifyRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'extensionToken', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'body')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotifyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotifyRequest copyWith(void Function(NotifyRequest) updates) =>
      super.copyWith((message) => updates(message as NotifyRequest))
          as NotifyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NotifyRequest create() => NotifyRequest._();
  @$core.override
  NotifyRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NotifyRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NotifyRequest>(create);
  static NotifyRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get extensionToken => $_getN(0);
  @$pb.TagNumber(1)
  set extensionToken($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExtensionToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtensionToken() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get title => $_getSZ(1);
  @$pb.TagNumber(2)
  set title($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTitle() => $_has(1);
  @$pb.TagNumber(2)
  void clearTitle() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get body => $_getSZ(2);
  @$pb.TagNumber(3)
  set body($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBody() => $_has(2);
  @$pb.TagNumber(3)
  void clearBody() => $_clearField(3);
}

class NotifyResponse extends $pb.GeneratedMessage {
  factory NotifyResponse() => create();

  NotifyResponse._();

  factory NotifyResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NotifyResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NotifyResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotifyResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotifyResponse copyWith(void Function(NotifyResponse) updates) =>
      super.copyWith((message) => updates(message as NotifyResponse))
          as NotifyResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NotifyResponse create() => NotifyResponse._();
  @$core.override
  NotifyResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NotifyResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NotifyResponse>(create);
  static NotifyResponse? _defaultInstance;
}

class WatchExtensionEventsRequest extends $pb.GeneratedMessage {
  factory WatchExtensionEventsRequest({
    $core.List<$core.int>? extensionToken,
  }) {
    final result = create();
    if (extensionToken != null) result.extensionToken = extensionToken;
    return result;
  }

  WatchExtensionEventsRequest._();

  factory WatchExtensionEventsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WatchExtensionEventsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchExtensionEventsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'extensionToken', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchExtensionEventsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchExtensionEventsRequest copyWith(
          void Function(WatchExtensionEventsRequest) updates) =>
      super.copyWith(
              (message) => updates(message as WatchExtensionEventsRequest))
          as WatchExtensionEventsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WatchExtensionEventsRequest create() =>
      WatchExtensionEventsRequest._();
  @$core.override
  WatchExtensionEventsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WatchExtensionEventsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WatchExtensionEventsRequest>(create);
  static WatchExtensionEventsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get extensionToken => $_getN(0);
  @$pb.TagNumber(1)
  set extensionToken($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExtensionToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtensionToken() => $_clearField(1);
}

class ExtensionEvent extends $pb.GeneratedMessage {
  factory ExtensionEvent({
    $core.String? kind,
    $core.String? detail,
    $1.Timestamp? at,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (detail != null) result.detail = detail;
    if (at != null) result.at = at;
    return result;
  }

  ExtensionEvent._();

  factory ExtensionEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ExtensionEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ExtensionEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'kind')
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..aOM<$1.Timestamp>(3, _omitFieldNames ? '' : 'at',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionEvent copyWith(void Function(ExtensionEvent) updates) =>
      super.copyWith((message) => updates(message as ExtensionEvent))
          as ExtensionEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExtensionEvent create() => ExtensionEvent._();
  @$core.override
  ExtensionEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ExtensionEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExtensionEvent>(create);
  static ExtensionEvent? _defaultInstance;

  /// One of "session.connected", "session.disconnected", "network.changed",
  /// "extension.disabled". The app stops the stream on "extension.disabled".
  @$pb.TagNumber(1)
  $core.String get kind => $_getSZ(0);
  @$pb.TagNumber(1)
  set kind($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get detail => $_getSZ(1);
  @$pb.TagNumber(2)
  set detail($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDetail() => $_has(1);
  @$pb.TagNumber(2)
  void clearDetail() => $_clearField(2);

  @$pb.TagNumber(3)
  $1.Timestamp get at => $_getN(2);
  @$pb.TagNumber(3)
  set at($1.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearAt() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.Timestamp ensureAt() => $_ensure(2);
}

/// BypassBinding binds one destination to a bypass strategy. Match is a
/// plan-rule destination ("domain:example.com", "full:example.com", an IP
/// literal, a CIDR, "geosite:...", "geoip:...", "ruleset:..."; a bare
/// domain is shorthand for "domain:<domain>").
class BypassBinding extends $pb.GeneratedMessage {
  factory BypassBinding({
    $core.String? match,
    $2.BypassStrategy? strategy,
  }) {
    final result = create();
    if (match != null) result.match = match;
    if (strategy != null) result.strategy = strategy;
    return result;
  }

  BypassBinding._();

  factory BypassBinding.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BypassBinding.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BypassBinding',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'match')
    ..aOM<$2.BypassStrategy>(2, _omitFieldNames ? '' : 'strategy',
        subBuilder: $2.BypassStrategy.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BypassBinding clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BypassBinding copyWith(void Function(BypassBinding) updates) =>
      super.copyWith((message) => updates(message as BypassBinding))
          as BypassBinding;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BypassBinding create() => BypassBinding._();
  @$core.override
  BypassBinding createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BypassBinding getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BypassBinding>(create);
  static BypassBinding? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get match => $_getSZ(0);
  @$pb.TagNumber(1)
  set match($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMatch() => $_has(0);
  @$pb.TagNumber(1)
  void clearMatch() => $_clearField(1);

  @$pb.TagNumber(2)
  $2.BypassStrategy get strategy => $_getN(1);
  @$pb.TagNumber(2)
  set strategy($2.BypassStrategy value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasStrategy() => $_has(1);
  @$pb.TagNumber(2)
  void clearStrategy() => $_clearField(2);
  @$pb.TagNumber(2)
  $2.BypassStrategy ensureStrategy() => $_ensure(1);
}

class GetBypassCapabilitiesRequest extends $pb.GeneratedMessage {
  factory GetBypassCapabilitiesRequest({
    $core.List<$core.int>? extensionToken,
  }) {
    final result = create();
    if (extensionToken != null) result.extensionToken = extensionToken;
    return result;
  }

  GetBypassCapabilitiesRequest._();

  factory GetBypassCapabilitiesRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetBypassCapabilitiesRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetBypassCapabilitiesRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'extensionToken', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBypassCapabilitiesRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBypassCapabilitiesRequest copyWith(
          void Function(GetBypassCapabilitiesRequest) updates) =>
      super.copyWith(
              (message) => updates(message as GetBypassCapabilitiesRequest))
          as GetBypassCapabilitiesRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBypassCapabilitiesRequest create() =>
      GetBypassCapabilitiesRequest._();
  @$core.override
  GetBypassCapabilitiesRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetBypassCapabilitiesRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetBypassCapabilitiesRequest>(create);
  static GetBypassCapabilitiesRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get extensionToken => $_getN(0);
  @$pb.TagNumber(1)
  set extensionToken($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExtensionToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtensionToken() => $_clearField(1);
}

/// BackendInfo is one bypass backend's measured availability.
class BackendInfo extends $pb.GeneratedMessage {
  factory BackendInfo({
    $core.String? kind,
    $core.bool? available,
    $core.String? reason,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (available != null) result.available = available;
    if (reason != null) result.reason = reason;
    return result;
  }

  BackendInfo._();

  factory BackendInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BackendInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BackendInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'kind')
    ..aOB(2, _omitFieldNames ? '' : 'available')
    ..aOS(3, _omitFieldNames ? '' : 'reason')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BackendInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BackendInfo copyWith(void Function(BackendInfo) updates) =>
      super.copyWith((message) => updates(message as BackendInfo))
          as BackendInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BackendInfo create() => BackendInfo._();
  @$core.override
  BackendInfo createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BackendInfo getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BackendInfo>(create);
  static BackendInfo? _defaultInstance;

  /// "tpws" or "nfqws".
  @$pb.TagNumber(1)
  $core.String get kind => $_getSZ(0);
  @$pb.TagNumber(1)
  set kind($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get available => $_getBF(1);
  @$pb.TagNumber(2)
  set available($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAvailable() => $_has(1);
  @$pb.TagNumber(2)
  void clearAvailable() => $_clearField(2);

  /// Why the backend is unavailable (the missing capability and the
  /// remedy), empty when available.
  @$pb.TagNumber(3)
  $core.String get reason => $_getSZ(2);
  @$pb.TagNumber(3)
  set reason($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReason() => $_has(2);
  @$pb.TagNumber(3)
  void clearReason() => $_clearField(3);
}

class GetBypassCapabilitiesResponse extends $pb.GeneratedMessage {
  factory GetBypassCapabilitiesResponse({
    $core.String? platform,
    $core.Iterable<BackendInfo>? backends,
  }) {
    final result = create();
    if (platform != null) result.platform = platform;
    if (backends != null) result.backends.addAll(backends);
    return result;
  }

  GetBypassCapabilitiesResponse._();

  factory GetBypassCapabilitiesResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetBypassCapabilitiesResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetBypassCapabilitiesResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'platform')
    ..pPM<BackendInfo>(2, _omitFieldNames ? '' : 'backends',
        subBuilder: BackendInfo.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBypassCapabilitiesResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBypassCapabilitiesResponse copyWith(
          void Function(GetBypassCapabilitiesResponse) updates) =>
      super.copyWith(
              (message) => updates(message as GetBypassCapabilitiesResponse))
          as GetBypassCapabilitiesResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBypassCapabilitiesResponse create() =>
      GetBypassCapabilitiesResponse._();
  @$core.override
  GetBypassCapabilitiesResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetBypassCapabilitiesResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetBypassCapabilitiesResponse>(create);
  static GetBypassCapabilitiesResponse? _defaultInstance;

  /// The executor family of this host, e.g. "linux-nfqueue".
  @$pb.TagNumber(1)
  $core.String get platform => $_getSZ(0);
  @$pb.TagNumber(1)
  set platform($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlatform() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlatform() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<BackendInfo> get backends => $_getList(1);
}

class GetBypassStateRequest extends $pb.GeneratedMessage {
  factory GetBypassStateRequest({
    $core.List<$core.int>? extensionToken,
  }) {
    final result = create();
    if (extensionToken != null) result.extensionToken = extensionToken;
    return result;
  }

  GetBypassStateRequest._();

  factory GetBypassStateRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetBypassStateRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetBypassStateRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'extensionToken', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBypassStateRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBypassStateRequest copyWith(
          void Function(GetBypassStateRequest) updates) =>
      super.copyWith((message) => updates(message as GetBypassStateRequest))
          as GetBypassStateRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBypassStateRequest create() => GetBypassStateRequest._();
  @$core.override
  GetBypassStateRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetBypassStateRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetBypassStateRequest>(create);
  static GetBypassStateRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get extensionToken => $_getN(0);
  @$pb.TagNumber(1)
  set extensionToken($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExtensionToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtensionToken() => $_clearField(1);
}

class GetBypassStateResponse extends $pb.GeneratedMessage {
  factory GetBypassStateResponse({
    $core.String? platform,
    $core.String? globalSource,
    $core.String? globalFrom,
    $core.bool? sessionActive,
    $core.bool? pendingApply,
    $core.int? bindingsCount,
  }) {
    final result = create();
    if (platform != null) result.platform = platform;
    if (globalSource != null) result.globalSource = globalSource;
    if (globalFrom != null) result.globalFrom = globalFrom;
    if (sessionActive != null) result.sessionActive = sessionActive;
    if (pendingApply != null) result.pendingApply = pendingApply;
    if (bindingsCount != null) result.bindingsCount = bindingsCount;
    return result;
  }

  GetBypassStateResponse._();

  factory GetBypassStateResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetBypassStateResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetBypassStateResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'platform')
    ..aOS(2, _omitFieldNames ? '' : 'globalSource')
    ..aOS(3, _omitFieldNames ? '' : 'globalFrom')
    ..aOB(4, _omitFieldNames ? '' : 'sessionActive')
    ..aOB(5, _omitFieldNames ? '' : 'pendingApply')
    ..aI(6, _omitFieldNames ? '' : 'bindingsCount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBypassStateResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBypassStateResponse copyWith(
          void Function(GetBypassStateResponse) updates) =>
      super.copyWith((message) => updates(message as GetBypassStateResponse))
          as GetBypassStateResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBypassStateResponse create() => GetBypassStateResponse._();
  @$core.override
  GetBypassStateResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetBypassStateResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetBypassStateResponse>(create);
  static GetBypassStateResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get platform => $_getSZ(0);
  @$pb.TagNumber(1)
  set platform($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlatform() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlatform() => $_clearField(1);

  /// Where the global bypass strategy of the last built plan came from:
  /// "user", "extension", "core_default" or "none" (no plan built yet, or
  /// the plan carries no global bypass).
  @$pb.TagNumber(2)
  $core.String get globalSource => $_getSZ(1);
  @$pb.TagNumber(2)
  set globalSource($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasGlobalSource() => $_has(1);
  @$pb.TagNumber(2)
  void clearGlobalSource() => $_clearField(2);

  /// The extension id the global strategy came from, when global_source
  /// is "extension"; empty otherwise.
  @$pb.TagNumber(3)
  $core.String get globalFrom => $_getSZ(2);
  @$pb.TagNumber(3)
  set globalFrom($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGlobalFrom() => $_has(2);
  @$pb.TagNumber(3)
  void clearGlobalFrom() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get sessionActive => $_getBF(3);
  @$pb.TagNumber(4)
  set sessionActive($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSessionActive() => $_has(3);
  @$pb.TagNumber(4)
  void clearSessionActive() => $_clearField(4);

  /// A stored layer is newer than the last built plan: it will only take
  /// effect at the next Connect.
  @$pb.TagNumber(5)
  $core.bool get pendingApply => $_getBF(4);
  @$pb.TagNumber(5)
  set pendingApply($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPendingApply() => $_has(4);
  @$pb.TagNumber(5)
  void clearPendingApply() => $_clearField(5);

  /// Bindings the last built plan actually carries from extension layers
  /// (conflicts with user rules are skipped at merge time and not counted).
  @$pb.TagNumber(6)
  $core.int get bindingsCount => $_getIZ(5);
  @$pb.TagNumber(6)
  set bindingsCount($core.int value) => $_setSignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasBindingsCount() => $_has(5);
  @$pb.TagNumber(6)
  void clearBindingsCount() => $_clearField(6);
}

class GetBypassLayerRequest extends $pb.GeneratedMessage {
  factory GetBypassLayerRequest({
    $core.List<$core.int>? extensionToken,
  }) {
    final result = create();
    if (extensionToken != null) result.extensionToken = extensionToken;
    return result;
  }

  GetBypassLayerRequest._();

  factory GetBypassLayerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetBypassLayerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetBypassLayerRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'extensionToken', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBypassLayerRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBypassLayerRequest copyWith(
          void Function(GetBypassLayerRequest) updates) =>
      super.copyWith((message) => updates(message as GetBypassLayerRequest))
          as GetBypassLayerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBypassLayerRequest create() => GetBypassLayerRequest._();
  @$core.override
  GetBypassLayerRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetBypassLayerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetBypassLayerRequest>(create);
  static GetBypassLayerRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get extensionToken => $_getN(0);
  @$pb.TagNumber(1)
  set extensionToken($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExtensionToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtensionToken() => $_clearField(1);
}

class GetBypassLayerResponse extends $pb.GeneratedMessage {
  factory GetBypassLayerResponse({
    $2.BypassStrategy? global,
    $core.bool? hasGlobal_2,
    $core.Iterable<BypassBinding>? bindings,
    $fixnum.Int64? updatedAtUnix,
  }) {
    final result = create();
    if (global != null) result.global = global;
    if (hasGlobal_2 != null) result.hasGlobal_2 = hasGlobal_2;
    if (bindings != null) result.bindings.addAll(bindings);
    if (updatedAtUnix != null) result.updatedAtUnix = updatedAtUnix;
    return result;
  }

  GetBypassLayerResponse._();

  factory GetBypassLayerResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GetBypassLayerResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GetBypassLayerResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..aOM<$2.BypassStrategy>(1, _omitFieldNames ? '' : 'global',
        subBuilder: $2.BypassStrategy.create)
    ..aOB(2, _omitFieldNames ? '' : 'hasGlobal')
    ..pPM<BypassBinding>(3, _omitFieldNames ? '' : 'bindings',
        subBuilder: BypassBinding.create)
    ..aInt64(4, _omitFieldNames ? '' : 'updatedAtUnix')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBypassLayerResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetBypassLayerResponse copyWith(
          void Function(GetBypassLayerResponse) updates) =>
      super.copyWith((message) => updates(message as GetBypassLayerResponse))
          as GetBypassLayerResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetBypassLayerResponse create() => GetBypassLayerResponse._();
  @$core.override
  GetBypassLayerResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static GetBypassLayerResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetBypassLayerResponse>(create);
  static GetBypassLayerResponse? _defaultInstance;

  /// The layer's global strategy; meaningful only when has_global is set.
  @$pb.TagNumber(1)
  $2.BypassStrategy get global => $_getN(0);
  @$pb.TagNumber(1)
  set global($2.BypassStrategy value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasGlobal() => $_has(0);
  @$pb.TagNumber(1)
  void clearGlobal() => $_clearField(1);
  @$pb.TagNumber(1)
  $2.BypassStrategy ensureGlobal() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.bool get hasGlobal_2 => $_getBF(1);
  @$pb.TagNumber(2)
  set hasGlobal_2($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHasGlobal_2() => $_has(1);
  @$pb.TagNumber(2)
  void clearHasGlobal_2() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<BypassBinding> get bindings => $_getList(2);

  /// When the layer was stored, seconds since the epoch. Zero when the
  /// calling extension has no layer.
  @$pb.TagNumber(4)
  $fixnum.Int64 get updatedAtUnix => $_getI64(3);
  @$pb.TagNumber(4)
  set updatedAtUnix($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUpdatedAtUnix() => $_has(3);
  @$pb.TagNumber(4)
  void clearUpdatedAtUnix() => $_clearField(4);
}

class ApplyBypassLayerRequest extends $pb.GeneratedMessage {
  factory ApplyBypassLayerRequest({
    $core.List<$core.int>? extensionToken,
    $core.bool? hasGlobal,
    $2.BypassStrategy? global_3,
    $core.Iterable<BypassBinding>? bindings,
  }) {
    final result = create();
    if (extensionToken != null) result.extensionToken = extensionToken;
    if (hasGlobal != null) result.hasGlobal = hasGlobal;
    if (global_3 != null) result.global_3 = global_3;
    if (bindings != null) result.bindings.addAll(bindings);
    return result;
  }

  ApplyBypassLayerRequest._();

  factory ApplyBypassLayerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ApplyBypassLayerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApplyBypassLayerRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'extensionToken', $pb.PbFieldType.OY)
    ..aOB(2, _omitFieldNames ? '' : 'hasGlobal')
    ..aOM<$2.BypassStrategy>(3, _omitFieldNames ? '' : 'global',
        subBuilder: $2.BypassStrategy.create)
    ..pPM<BypassBinding>(4, _omitFieldNames ? '' : 'bindings',
        subBuilder: BypassBinding.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyBypassLayerRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyBypassLayerRequest copyWith(
          void Function(ApplyBypassLayerRequest) updates) =>
      super.copyWith((message) => updates(message as ApplyBypassLayerRequest))
          as ApplyBypassLayerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplyBypassLayerRequest create() => ApplyBypassLayerRequest._();
  @$core.override
  ApplyBypassLayerRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ApplyBypassLayerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApplyBypassLayerRequest>(create);
  static ApplyBypassLayerRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get extensionToken => $_getN(0);
  @$pb.TagNumber(1)
  set extensionToken($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExtensionToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtensionToken() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get hasGlobal => $_getBF(1);
  @$pb.TagNumber(2)
  set hasGlobal($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasHasGlobal() => $_has(1);
  @$pb.TagNumber(2)
  void clearHasGlobal() => $_clearField(2);

  /// The global strategy; ignored when has_global is false.
  @$pb.TagNumber(3)
  $2.BypassStrategy get global_3 => $_getN(2);
  @$pb.TagNumber(3)
  set global_3($2.BypassStrategy value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasGlobal_3() => $_has(2);
  @$pb.TagNumber(3)
  void clearGlobal_3() => $_clearField(3);
  @$pb.TagNumber(3)
  $2.BypassStrategy ensureGlobal_3() => $_ensure(2);

  @$pb.TagNumber(4)
  $pb.PbList<BypassBinding> get bindings => $_getList(3);
}

class ApplyBypassLayerResponse extends $pb.GeneratedMessage {
  factory ApplyBypassLayerResponse({
    $fixnum.Int64? updatedAtUnix,
  }) {
    final result = create();
    if (updatedAtUnix != null) result.updatedAtUnix = updatedAtUnix;
    return result;
  }

  ApplyBypassLayerResponse._();

  factory ApplyBypassLayerResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ApplyBypassLayerResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ApplyBypassLayerResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'updatedAtUnix')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyBypassLayerResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApplyBypassLayerResponse copyWith(
          void Function(ApplyBypassLayerResponse) updates) =>
      super.copyWith((message) => updates(message as ApplyBypassLayerResponse))
          as ApplyBypassLayerResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplyBypassLayerResponse create() => ApplyBypassLayerResponse._();
  @$core.override
  ApplyBypassLayerResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ApplyBypassLayerResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ApplyBypassLayerResponse>(create);
  static ApplyBypassLayerResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get updatedAtUnix => $_getI64(0);
  @$pb.TagNumber(1)
  set updatedAtUnix($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUpdatedAtUnix() => $_has(0);
  @$pb.TagNumber(1)
  void clearUpdatedAtUnix() => $_clearField(1);
}

class TuneDesyncRequest extends $pb.GeneratedMessage {
  factory TuneDesyncRequest({
    $core.List<$core.int>? extensionToken,
    $core.String? engine,
  }) {
    final result = create();
    if (extensionToken != null) result.extensionToken = extensionToken;
    if (engine != null) result.engine = engine;
    return result;
  }

  TuneDesyncRequest._();

  factory TuneDesyncRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TuneDesyncRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TuneDesyncRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'extensionToken', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'engine')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TuneDesyncRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TuneDesyncRequest copyWith(void Function(TuneDesyncRequest) updates) =>
      super.copyWith((message) => updates(message as TuneDesyncRequest))
          as TuneDesyncRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TuneDesyncRequest create() => TuneDesyncRequest._();
  @$core.override
  TuneDesyncRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TuneDesyncRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TuneDesyncRequest>(create);
  static TuneDesyncRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get extensionToken => $_getN(0);
  @$pb.TagNumber(1)
  set extensionToken($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExtensionToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtensionToken() => $_clearField(1);

  /// Executor to tune for: "nfqws" or "tpws". Empty means the core
  /// default (nfqws), exactly as in sora.censor.v1.
  @$pb.TagNumber(2)
  $core.String get engine => $_getSZ(1);
  @$pb.TagNumber(2)
  set engine($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEngine() => $_has(1);
  @$pb.TagNumber(2)
  void clearEngine() => $_clearField(2);
}

class TuneDesyncResponse extends $pb.GeneratedMessage {
  factory TuneDesyncResponse({
    $core.String? winnerId,
    $core.String? winnerDescribe,
    $core.double? score,
    $core.int? attempts,
    $core.bool? hasStrategy,
    $2.BypassStrategy? strategy_6,
  }) {
    final result = create();
    if (winnerId != null) result.winnerId = winnerId;
    if (winnerDescribe != null) result.winnerDescribe = winnerDescribe;
    if (score != null) result.score = score;
    if (attempts != null) result.attempts = attempts;
    if (hasStrategy != null) result.hasStrategy = hasStrategy;
    if (strategy_6 != null) result.strategy_6 = strategy_6;
    return result;
  }

  TuneDesyncResponse._();

  factory TuneDesyncResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TuneDesyncResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TuneDesyncResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'winnerId')
    ..aOS(2, _omitFieldNames ? '' : 'winnerDescribe')
    ..aD(3, _omitFieldNames ? '' : 'score')
    ..aI(4, _omitFieldNames ? '' : 'attempts')
    ..aOB(5, _omitFieldNames ? '' : 'hasStrategy')
    ..aOM<$2.BypassStrategy>(6, _omitFieldNames ? '' : 'strategy',
        subBuilder: $2.BypassStrategy.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TuneDesyncResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TuneDesyncResponse copyWith(void Function(TuneDesyncResponse) updates) =>
      super.copyWith((message) => updates(message as TuneDesyncResponse))
          as TuneDesyncResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TuneDesyncResponse create() => TuneDesyncResponse._();
  @$core.override
  TuneDesyncResponse createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TuneDesyncResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TuneDesyncResponse>(create);
  static TuneDesyncResponse? _defaultInstance;

  /// The winning strategy's stable id: a registry profile id, or the
  /// genome id ("d/...") when the winner is known only as a genome.
  /// Empty when no candidate worked.
  @$pb.TagNumber(1)
  $core.String get winnerId => $_getSZ(0);
  @$pb.TagNumber(1)
  set winnerId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasWinnerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearWinnerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get winnerDescribe => $_getSZ(1);
  @$pb.TagNumber(2)
  set winnerDescribe($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasWinnerDescribe() => $_has(1);
  @$pb.TagNumber(2)
  void clearWinnerDescribe() => $_clearField(2);

  /// The winner's fitness in [0,1].
  @$pb.TagNumber(3)
  $core.double get score => $_getN(2);
  @$pb.TagNumber(3)
  set score($core.double value) => $_setDouble(2, value);
  @$pb.TagNumber(3)
  $core.bool hasScore() => $_has(2);
  @$pb.TagNumber(3)
  void clearScore() => $_clearField(3);

  /// How many candidates were probed.
  @$pb.TagNumber(4)
  $core.int get attempts => $_getIZ(3);
  @$pb.TagNumber(4)
  set attempts($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAttempts() => $_has(3);
  @$pb.TagNumber(4)
  void clearAttempts() => $_clearField(4);

  /// Whether strategy carries the winner's strategy. A winner whose
  /// genome has no faithful strategy rendering reports false while the
  /// other fields stay honest.
  @$pb.TagNumber(5)
  $core.bool get hasStrategy => $_getBF(4);
  @$pb.TagNumber(5)
  set hasStrategy($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHasStrategy() => $_has(4);
  @$pb.TagNumber(5)
  void clearHasStrategy() => $_clearField(5);

  @$pb.TagNumber(6)
  $2.BypassStrategy get strategy_6 => $_getN(5);
  @$pb.TagNumber(6)
  set strategy_6($2.BypassStrategy value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasStrategy_6() => $_has(5);
  @$pb.TagNumber(6)
  void clearStrategy_6() => $_clearField(6);
  @$pb.TagNumber(6)
  $2.BypassStrategy ensureStrategy_6() => $_ensure(5);
}

class WatchBypassEventsRequest extends $pb.GeneratedMessage {
  factory WatchBypassEventsRequest({
    $core.List<$core.int>? extensionToken,
  }) {
    final result = create();
    if (extensionToken != null) result.extensionToken = extensionToken;
    return result;
  }

  WatchBypassEventsRequest._();

  factory WatchBypassEventsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WatchBypassEventsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WatchBypassEventsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'extensionToken', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchBypassEventsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchBypassEventsRequest copyWith(
          void Function(WatchBypassEventsRequest) updates) =>
      super.copyWith((message) => updates(message as WatchBypassEventsRequest))
          as WatchBypassEventsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WatchBypassEventsRequest create() => WatchBypassEventsRequest._();
  @$core.override
  WatchBypassEventsRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WatchBypassEventsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WatchBypassEventsRequest>(create);
  static WatchBypassEventsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get extensionToken => $_getN(0);
  @$pb.TagNumber(1)
  set extensionToken($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasExtensionToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearExtensionToken() => $_clearField(1);
}

class BypassEvent extends $pb.GeneratedMessage {
  factory BypassEvent({
    $core.String? kind,
    $core.String? censorshipKind,
    $core.String? explanation,
    $1.Timestamp? at,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (censorshipKind != null) result.censorshipKind = censorshipKind;
    if (explanation != null) result.explanation = explanation;
    if (at != null) result.at = at;
    return result;
  }

  BypassEvent._();

  factory BypassEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory BypassEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'BypassEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'kind')
    ..aOS(2, _omitFieldNames ? '' : 'censorshipKind')
    ..aOS(3, _omitFieldNames ? '' : 'explanation')
    ..aOM<$1.Timestamp>(4, _omitFieldNames ? '' : 'at',
        subBuilder: $1.Timestamp.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BypassEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BypassEvent copyWith(void Function(BypassEvent) updates) =>
      super.copyWith((message) => updates(message as BypassEvent))
          as BypassEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BypassEvent create() => BypassEvent._();
  @$core.override
  BypassEvent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static BypassEvent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BypassEvent>(create);
  static BypassEvent? _defaultInstance;

  /// One of "censorship", "strategy", "session". The session journal
  /// today emits censorship verdicts and session state changes; "strategy"
  /// is reserved for strategy-change events the journal does not produce
  /// yet and is never synthesized.
  @$pb.TagNumber(1)
  $core.String get kind => $_getSZ(0);
  @$pb.TagNumber(1)
  set kind($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  /// The censorship classification ("sni_blocking", "rst_injection", ...)
  /// when kind is "censorship"; empty otherwise.
  @$pb.TagNumber(2)
  $core.String get censorshipKind => $_getSZ(1);
  @$pb.TagNumber(2)
  set censorshipKind($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCensorshipKind() => $_has(1);
  @$pb.TagNumber(2)
  void clearCensorshipKind() => $_clearField(2);

  /// Plain-language account of the event, as journaled.
  @$pb.TagNumber(3)
  $core.String get explanation => $_getSZ(2);
  @$pb.TagNumber(3)
  set explanation($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExplanation() => $_has(2);
  @$pb.TagNumber(3)
  void clearExplanation() => $_clearField(3);

  @$pb.TagNumber(4)
  $1.Timestamp get at => $_getN(3);
  @$pb.TagNumber(4)
  set at($1.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $1.Timestamp ensureAt() => $_ensure(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
