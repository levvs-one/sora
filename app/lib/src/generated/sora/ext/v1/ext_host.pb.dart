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
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart' as $1;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class MintTokenRequest extends $pb.GeneratedMessage {
  factory MintTokenRequest({
    $core.List<$core.int>? controlToken,
    $core.String? extensionId,
    $core.Iterable<$core.String>? permissions,
  }) {
    final result = MintTokenRequest._();
    if (controlToken != null) result.controlToken = controlToken;
    if (extensionId != null) result.extensionId = extensionId;
    if (permissions != null) result.permissions.addAll(permissions);
    return result;
  }

  MintTokenRequest._();

  factory MintTokenRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MintTokenRequest()..mergeFromBuffer(data, registry);
  factory MintTokenRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MintTokenRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'MintTokenRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: MintTokenRequest.$_createMessage)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'controlToken', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'extensionId')
    ..pPS(3, _omitFieldNames ? '' : 'permissions')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MintTokenRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MintTokenRequest copyWith(void Function(MintTokenRequest) updates) =>
      super.copyWith((message) => updates(message as MintTokenRequest)) as MintTokenRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MintTokenRequest() / MintTokenRequest.new instead')
  static MintTokenRequest create() => MintTokenRequest._();
  static $pb.GeneratedMessage $_createMessage() => MintTokenRequest._();
  @$core.override
  MintTokenRequest createEmptyInstance() => MintTokenRequest._();
  @$core.pragma('dart2js:noInline')
  static MintTokenRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MintTokenRequest>(MintTokenRequest.$_createMessage);
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
    final result = MintTokenResponse._();
    if (extensionToken != null) result.extensionToken = extensionToken;
    return result;
  }

  MintTokenResponse._();

  factory MintTokenResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MintTokenResponse()..mergeFromBuffer(data, registry);
  factory MintTokenResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      MintTokenResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'MintTokenResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: MintTokenResponse.$_createMessage)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'extensionToken', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MintTokenResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MintTokenResponse copyWith(void Function(MintTokenResponse) updates) =>
      super.copyWith((message) => updates(message as MintTokenResponse)) as MintTokenResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use MintTokenResponse() / MintTokenResponse.new instead')
  static MintTokenResponse create() => MintTokenResponse._();
  static $pb.GeneratedMessage $_createMessage() => MintTokenResponse._();
  @$core.override
  MintTokenResponse createEmptyInstance() => MintTokenResponse._();
  @$core.pragma('dart2js:noInline')
  static MintTokenResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MintTokenResponse>(MintTokenResponse.$_createMessage);
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
    final result = RevokeTokenRequest._();
    if (controlToken != null) result.controlToken = controlToken;
    if (extensionToken != null) result.extensionToken = extensionToken;
    return result;
  }

  RevokeTokenRequest._();

  factory RevokeTokenRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeTokenRequest()..mergeFromBuffer(data, registry);
  factory RevokeTokenRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeTokenRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RevokeTokenRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: RevokeTokenRequest.$_createMessage)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'controlToken', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'extensionToken', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeTokenRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeTokenRequest copyWith(void Function(RevokeTokenRequest) updates) =>
      super.copyWith((message) => updates(message as RevokeTokenRequest)) as RevokeTokenRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RevokeTokenRequest() / RevokeTokenRequest.new instead')
  static RevokeTokenRequest create() => RevokeTokenRequest._();
  static $pb.GeneratedMessage $_createMessage() => RevokeTokenRequest._();
  @$core.override
  RevokeTokenRequest createEmptyInstance() => RevokeTokenRequest._();
  @$core.pragma('dart2js:noInline')
  static RevokeTokenRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RevokeTokenRequest>(RevokeTokenRequest.$_createMessage);
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
  factory RevokeTokenResponse() => RevokeTokenResponse._();

  RevokeTokenResponse._();

  factory RevokeTokenResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeTokenResponse()..mergeFromBuffer(data, registry);
  factory RevokeTokenResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RevokeTokenResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RevokeTokenResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: RevokeTokenResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeTokenResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RevokeTokenResponse copyWith(void Function(RevokeTokenResponse) updates) =>
      super.copyWith((message) => updates(message as RevokeTokenResponse)) as RevokeTokenResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RevokeTokenResponse() / RevokeTokenResponse.new instead')
  static RevokeTokenResponse create() => RevokeTokenResponse._();
  static $pb.GeneratedMessage $_createMessage() => RevokeTokenResponse._();
  @$core.override
  RevokeTokenResponse createEmptyInstance() => RevokeTokenResponse._();
  @$core.pragma('dart2js:noInline')
  static RevokeTokenResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RevokeTokenResponse>(RevokeTokenResponse.$_createMessage);
  static RevokeTokenResponse? _defaultInstance;
}

class GetConnectionsRequest extends $pb.GeneratedMessage {
  factory GetConnectionsRequest({
    $core.List<$core.int>? extensionToken,
  }) {
    final result = GetConnectionsRequest._();
    if (extensionToken != null) result.extensionToken = extensionToken;
    return result;
  }

  GetConnectionsRequest._();

  factory GetConnectionsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetConnectionsRequest()..mergeFromBuffer(data, registry);
  factory GetConnectionsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetConnectionsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetConnectionsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: GetConnectionsRequest.$_createMessage)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'extensionToken', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetConnectionsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetConnectionsRequest copyWith(void Function(GetConnectionsRequest) updates) =>
      super.copyWith((message) => updates(message as GetConnectionsRequest)) as GetConnectionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetConnectionsRequest() / GetConnectionsRequest.new instead')
  static GetConnectionsRequest create() => GetConnectionsRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetConnectionsRequest._();
  @$core.override
  GetConnectionsRequest createEmptyInstance() => GetConnectionsRequest._();
  @$core.pragma('dart2js:noInline')
  static GetConnectionsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetConnectionsRequest>(GetConnectionsRequest.$_createMessage);
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
    final result = ExtensionConnection._();
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
      ExtensionConnection()..mergeFromBuffer(data, registry);
  factory ExtensionConnection.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExtensionConnection()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExtensionConnection',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: ExtensionConnection.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'process')
    ..aOS(3, _omitFieldNames ? '' : 'host')
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'upBytes', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'downBytes', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionConnection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionConnection copyWith(void Function(ExtensionConnection) updates) =>
      super.copyWith((message) => updates(message as ExtensionConnection)) as ExtensionConnection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ExtensionConnection() / ExtensionConnection.new instead')
  static ExtensionConnection create() => ExtensionConnection._();
  static $pb.GeneratedMessage $_createMessage() => ExtensionConnection._();
  @$core.override
  ExtensionConnection createEmptyInstance() => ExtensionConnection._();
  @$core.pragma('dart2js:noInline')
  static ExtensionConnection getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExtensionConnection>(ExtensionConnection.$_createMessage);
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
    final result = GetConnectionsResponse._();
    if (connections != null) result.connections.addAll(connections);
    return result;
  }

  GetConnectionsResponse._();

  factory GetConnectionsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetConnectionsResponse()..mergeFromBuffer(data, registry);
  factory GetConnectionsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetConnectionsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetConnectionsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: GetConnectionsResponse.$_createMessage)
    ..pPM<ExtensionConnection>(1, _omitFieldNames ? '' : 'connections', subBuilder: ExtensionConnection.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetConnectionsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetConnectionsResponse copyWith(void Function(GetConnectionsResponse) updates) =>
      super.copyWith((message) => updates(message as GetConnectionsResponse)) as GetConnectionsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetConnectionsResponse() / GetConnectionsResponse.new instead')
  static GetConnectionsResponse create() => GetConnectionsResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetConnectionsResponse._();
  @$core.override
  GetConnectionsResponse createEmptyInstance() => GetConnectionsResponse._();
  @$core.pragma('dart2js:noInline')
  static GetConnectionsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetConnectionsResponse>(GetConnectionsResponse.$_createMessage);
  static GetConnectionsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<ExtensionConnection> get connections => $_getList(0);
}

class GetServersRequest extends $pb.GeneratedMessage {
  factory GetServersRequest({
    $core.List<$core.int>? extensionToken,
  }) {
    final result = GetServersRequest._();
    if (extensionToken != null) result.extensionToken = extensionToken;
    return result;
  }

  GetServersRequest._();

  factory GetServersRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetServersRequest()..mergeFromBuffer(data, registry);
  factory GetServersRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetServersRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetServersRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: GetServersRequest.$_createMessage)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'extensionToken', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetServersRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetServersRequest copyWith(void Function(GetServersRequest) updates) =>
      super.copyWith((message) => updates(message as GetServersRequest)) as GetServersRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetServersRequest() / GetServersRequest.new instead')
  static GetServersRequest create() => GetServersRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetServersRequest._();
  @$core.override
  GetServersRequest createEmptyInstance() => GetServersRequest._();
  @$core.pragma('dart2js:noInline')
  static GetServersRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetServersRequest>(GetServersRequest.$_createMessage);
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
    final result = ExtensionServer._();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (country != null) result.country = country;
    if (latencyMs != null) result.latencyMs = latencyMs;
    return result;
  }

  ExtensionServer._();

  factory ExtensionServer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExtensionServer()..mergeFromBuffer(data, registry);
  factory ExtensionServer.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExtensionServer()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExtensionServer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: ExtensionServer.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'country')
    ..aInt64(4, _omitFieldNames ? '' : 'latencyMs')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionServer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionServer copyWith(void Function(ExtensionServer) updates) =>
      super.copyWith((message) => updates(message as ExtensionServer)) as ExtensionServer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ExtensionServer() / ExtensionServer.new instead')
  static ExtensionServer create() => ExtensionServer._();
  static $pb.GeneratedMessage $_createMessage() => ExtensionServer._();
  @$core.override
  ExtensionServer createEmptyInstance() => ExtensionServer._();
  @$core.pragma('dart2js:noInline')
  static ExtensionServer getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExtensionServer>(ExtensionServer.$_createMessage);
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
    final result = GetServersResponse._();
    if (servers != null) result.servers.addAll(servers);
    return result;
  }

  GetServersResponse._();

  factory GetServersResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetServersResponse()..mergeFromBuffer(data, registry);
  factory GetServersResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetServersResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetServersResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: GetServersResponse.$_createMessage)
    ..pPM<ExtensionServer>(1, _omitFieldNames ? '' : 'servers', subBuilder: ExtensionServer.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetServersResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetServersResponse copyWith(void Function(GetServersResponse) updates) =>
      super.copyWith((message) => updates(message as GetServersResponse)) as GetServersResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetServersResponse() / GetServersResponse.new instead')
  static GetServersResponse create() => GetServersResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetServersResponse._();
  @$core.override
  GetServersResponse createEmptyInstance() => GetServersResponse._();
  @$core.pragma('dart2js:noInline')
  static GetServersResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetServersResponse>(GetServersResponse.$_createMessage);
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
    final result = NotifyRequest._();
    if (extensionToken != null) result.extensionToken = extensionToken;
    if (title != null) result.title = title;
    if (body != null) result.body = body;
    return result;
  }

  NotifyRequest._();

  factory NotifyRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NotifyRequest()..mergeFromBuffer(data, registry);
  factory NotifyRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NotifyRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NotifyRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: NotifyRequest.$_createMessage)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'extensionToken', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'title')
    ..aOS(3, _omitFieldNames ? '' : 'body')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotifyRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotifyRequest copyWith(void Function(NotifyRequest) updates) =>
      super.copyWith((message) => updates(message as NotifyRequest)) as NotifyRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use NotifyRequest() / NotifyRequest.new instead')
  static NotifyRequest create() => NotifyRequest._();
  static $pb.GeneratedMessage $_createMessage() => NotifyRequest._();
  @$core.override
  NotifyRequest createEmptyInstance() => NotifyRequest._();
  @$core.pragma('dart2js:noInline')
  static NotifyRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NotifyRequest>(NotifyRequest.$_createMessage);
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
  factory NotifyResponse() => NotifyResponse._();

  NotifyResponse._();

  factory NotifyResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NotifyResponse()..mergeFromBuffer(data, registry);
  factory NotifyResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      NotifyResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NotifyResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: NotifyResponse.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotifyResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NotifyResponse copyWith(void Function(NotifyResponse) updates) =>
      super.copyWith((message) => updates(message as NotifyResponse)) as NotifyResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use NotifyResponse() / NotifyResponse.new instead')
  static NotifyResponse create() => NotifyResponse._();
  static $pb.GeneratedMessage $_createMessage() => NotifyResponse._();
  @$core.override
  NotifyResponse createEmptyInstance() => NotifyResponse._();
  @$core.pragma('dart2js:noInline')
  static NotifyResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NotifyResponse>(NotifyResponse.$_createMessage);
  static NotifyResponse? _defaultInstance;
}

class WatchExtensionEventsRequest extends $pb.GeneratedMessage {
  factory WatchExtensionEventsRequest({
    $core.List<$core.int>? extensionToken,
  }) {
    final result = WatchExtensionEventsRequest._();
    if (extensionToken != null) result.extensionToken = extensionToken;
    return result;
  }

  WatchExtensionEventsRequest._();

  factory WatchExtensionEventsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchExtensionEventsRequest()..mergeFromBuffer(data, registry);
  factory WatchExtensionEventsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchExtensionEventsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'WatchExtensionEventsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: WatchExtensionEventsRequest.$_createMessage)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'extensionToken', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchExtensionEventsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchExtensionEventsRequest copyWith(void Function(WatchExtensionEventsRequest) updates) =>
      super.copyWith((message) => updates(message as WatchExtensionEventsRequest)) as WatchExtensionEventsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WatchExtensionEventsRequest() / WatchExtensionEventsRequest.new instead')
  static WatchExtensionEventsRequest create() => WatchExtensionEventsRequest._();
  static $pb.GeneratedMessage $_createMessage() => WatchExtensionEventsRequest._();
  @$core.override
  WatchExtensionEventsRequest createEmptyInstance() => WatchExtensionEventsRequest._();
  @$core.pragma('dart2js:noInline')
  static WatchExtensionEventsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WatchExtensionEventsRequest>(WatchExtensionEventsRequest.$_createMessage);
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
    final result = ExtensionEvent._();
    if (kind != null) result.kind = kind;
    if (detail != null) result.detail = detail;
    if (at != null) result.at = at;
    return result;
  }

  ExtensionEvent._();

  factory ExtensionEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExtensionEvent()..mergeFromBuffer(data, registry);
  factory ExtensionEvent.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExtensionEvent()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExtensionEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.ext.v1'),
      createEmptyInstance: ExtensionEvent.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'kind')
    ..aOS(2, _omitFieldNames ? '' : 'detail')
    ..aOM<$1.Timestamp>(3, _omitFieldNames ? '' : 'at', subBuilder: $1.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExtensionEvent copyWith(void Function(ExtensionEvent) updates) =>
      super.copyWith((message) => updates(message as ExtensionEvent)) as ExtensionEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ExtensionEvent() / ExtensionEvent.new instead')
  static ExtensionEvent create() => ExtensionEvent._();
  static $pb.GeneratedMessage $_createMessage() => ExtensionEvent._();
  @$core.override
  ExtensionEvent createEmptyInstance() => ExtensionEvent._();
  @$core.pragma('dart2js:noInline')
  static ExtensionEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExtensionEvent>(ExtensionEvent.$_createMessage);
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

const $core.bool _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
