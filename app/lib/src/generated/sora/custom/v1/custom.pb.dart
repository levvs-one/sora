// This is a generated file - do not edit.
//
// Generated from sora/custom/v1/custom.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../core/v1/core_control.pb.dart' as $1;
import 'custom.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'custom.pbenum.dart';

/// CustomServer describes one user-added server. The credentials field is
/// write-only: it is accepted by SaveCustomServer and cleared (with
/// has_credentials set) on every response.
class CustomServer extends $pb.GeneratedMessage {
  factory CustomServer({
    $core.String? id,
    $core.String? name,
    CustomProtocol? protocol,
    $core.String? address,
    $core.int? port,
    $core.String? credentials,
    $core.bool? hasCredentials_7,
  }) {
    final result = CustomServer._();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (protocol != null) result.protocol = protocol;
    if (address != null) result.address = address;
    if (port != null) result.port = port;
    if (credentials != null) result.credentials = credentials;
    if (hasCredentials_7 != null) result.hasCredentials_7 = hasCredentials_7;
    return result;
  }

  CustomServer._();

  factory CustomServer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CustomServer()..mergeFromBuffer(data, registry);
  factory CustomServer.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CustomServer()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CustomServer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.custom.v1'),
      createEmptyInstance: CustomServer.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aE<CustomProtocol>(3, _omitFieldNames ? '' : 'protocol', enumValues: CustomProtocol.values)
    ..aOS(4, _omitFieldNames ? '' : 'address')
    ..aI(5, _omitFieldNames ? '' : 'port', fieldType: $pb.PbFieldType.OU3)
    ..aOS(6, _omitFieldNames ? '' : 'credentials')
    ..aOB(7, _omitFieldNames ? '' : 'hasCredentials')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CustomServer clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CustomServer copyWith(void Function(CustomServer) updates) =>
      super.copyWith((message) => updates(message as CustomServer)) as CustomServer;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CustomServer() / CustomServer.new instead')
  static CustomServer create() => CustomServer._();
  static $pb.GeneratedMessage $_createMessage() => CustomServer._();
  @$core.override
  CustomServer createEmptyInstance() => CustomServer._();
  @$core.pragma('dart2js:noInline')
  static CustomServer getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CustomServer>(CustomServer.$_createMessage);
  static CustomServer? _defaultInstance;

  /// Empty on create; the core assigns an id. Immutable afterwards.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Display name. Limit: 1 to 128 UTF-8 bytes.
  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  CustomProtocol get protocol => $_getN(2);
  @$pb.TagNumber(3)
  set protocol(CustomProtocol value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasProtocol() => $_has(2);
  @$pb.TagNumber(3)
  void clearProtocol() => $_clearField(3);

  /// Hostname or IP literal of the server.
  @$pb.TagNumber(4)
  $core.String get address => $_getSZ(3);
  @$pb.TagNumber(4)
  set address($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAddress() => $_has(3);
  @$pb.TagNumber(4)
  void clearAddress() => $_clearField(4);

  /// TCP port, 1 to 65535.
  @$pb.TagNumber(5)
  $core.int get port => $_getIZ(4);
  @$pb.TagNumber(5)
  set port($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPort() => $_has(4);
  @$pb.TagNumber(5)
  void clearPort() => $_clearField(5);

  /// Write-only secret material (UUID, password, key, ...). Accepted by
  /// SaveCustomServer, never returned by any RPC.
  @$pb.TagNumber(6)
  $core.String get credentials => $_getSZ(5);
  @$pb.TagNumber(6)
  set credentials($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCredentials() => $_has(5);
  @$pb.TagNumber(6)
  void clearCredentials() => $_clearField(6);

  /// True when the core holds credentials for this server. Read-only: the
  /// value sent on SaveCustomServer is ignored.
  @$pb.TagNumber(7)
  $core.bool get hasCredentials_7 => $_getBF(6);
  @$pb.TagNumber(7)
  set hasCredentials_7($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasHasCredentials_7() => $_has(6);
  @$pb.TagNumber(7)
  void clearHasCredentials_7() => $_clearField(7);
}

class SaveCustomServerRequest extends $pb.GeneratedMessage {
  factory SaveCustomServerRequest({
    $1.ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    CustomServer? server,
  }) {
    final result = SaveCustomServerRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    if (server != null) result.server = server;
    return result;
  }

  SaveCustomServerRequest._();

  factory SaveCustomServerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SaveCustomServerRequest()..mergeFromBuffer(data, registry);
  factory SaveCustomServerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SaveCustomServerRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SaveCustomServerRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.custom.v1'),
      createEmptyInstance: SaveCustomServerRequest.$_createMessage)
    ..aOM<$1.ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: $1.ApiVersion.$_createMessage)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOM<CustomServer>(3, _omitFieldNames ? '' : 'server', subBuilder: CustomServer.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveCustomServerRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveCustomServerRequest copyWith(void Function(SaveCustomServerRequest) updates) =>
      super.copyWith((message) => updates(message as SaveCustomServerRequest)) as SaveCustomServerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SaveCustomServerRequest() / SaveCustomServerRequest.new instead')
  static SaveCustomServerRequest create() => SaveCustomServerRequest._();
  static $pb.GeneratedMessage $_createMessage() => SaveCustomServerRequest._();
  @$core.override
  SaveCustomServerRequest createEmptyInstance() => SaveCustomServerRequest._();
  @$core.pragma('dart2js:noInline')
  static SaveCustomServerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveCustomServerRequest>(SaveCustomServerRequest.$_createMessage);
  static SaveCustomServerRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $1.ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion($1.ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => $_clearField(2);

  @$pb.TagNumber(3)
  CustomServer get server => $_getN(2);
  @$pb.TagNumber(3)
  set server(CustomServer value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasServer() => $_has(2);
  @$pb.TagNumber(3)
  void clearServer() => $_clearField(3);
  @$pb.TagNumber(3)
  CustomServer ensureServer() => $_ensure(2);
}

class SaveCustomServerResponse extends $pb.GeneratedMessage {
  factory SaveCustomServerResponse({
    CustomServer? server,
    $1.SoraError? error,
  }) {
    final result = SaveCustomServerResponse._();
    if (server != null) result.server = server;
    if (error != null) result.error = error;
    return result;
  }

  SaveCustomServerResponse._();

  factory SaveCustomServerResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SaveCustomServerResponse()..mergeFromBuffer(data, registry);
  factory SaveCustomServerResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SaveCustomServerResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SaveCustomServerResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.custom.v1'),
      createEmptyInstance: SaveCustomServerResponse.$_createMessage)
    ..aOM<CustomServer>(1, _omitFieldNames ? '' : 'server', subBuilder: CustomServer.$_createMessage)
    ..aOM<$1.SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: $1.SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveCustomServerResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveCustomServerResponse copyWith(void Function(SaveCustomServerResponse) updates) =>
      super.copyWith((message) => updates(message as SaveCustomServerResponse)) as SaveCustomServerResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SaveCustomServerResponse() / SaveCustomServerResponse.new instead')
  static SaveCustomServerResponse create() => SaveCustomServerResponse._();
  static $pb.GeneratedMessage $_createMessage() => SaveCustomServerResponse._();
  @$core.override
  SaveCustomServerResponse createEmptyInstance() => SaveCustomServerResponse._();
  @$core.pragma('dart2js:noInline')
  static SaveCustomServerResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveCustomServerResponse>(SaveCustomServerResponse.$_createMessage);
  static SaveCustomServerResponse? _defaultInstance;

  @$pb.TagNumber(1)
  CustomServer get server => $_getN(0);
  @$pb.TagNumber(1)
  set server(CustomServer value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasServer() => $_has(0);
  @$pb.TagNumber(1)
  void clearServer() => $_clearField(1);
  @$pb.TagNumber(1)
  CustomServer ensureServer() => $_ensure(0);

  @$pb.TagNumber(2)
  $1.SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($1.SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.SoraError ensureError() => $_ensure(1);
}

class ListCustomServersRequest extends $pb.GeneratedMessage {
  factory ListCustomServersRequest({
    $1.ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
  }) {
    final result = ListCustomServersRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    return result;
  }

  ListCustomServersRequest._();

  factory ListCustomServersRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListCustomServersRequest()..mergeFromBuffer(data, registry);
  factory ListCustomServersRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListCustomServersRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ListCustomServersRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.custom.v1'),
      createEmptyInstance: ListCustomServersRequest.$_createMessage)
    ..aOM<$1.ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: $1.ApiVersion.$_createMessage)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListCustomServersRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListCustomServersRequest copyWith(void Function(ListCustomServersRequest) updates) =>
      super.copyWith((message) => updates(message as ListCustomServersRequest)) as ListCustomServersRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListCustomServersRequest() / ListCustomServersRequest.new instead')
  static ListCustomServersRequest create() => ListCustomServersRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListCustomServersRequest._();
  @$core.override
  ListCustomServersRequest createEmptyInstance() => ListCustomServersRequest._();
  @$core.pragma('dart2js:noInline')
  static ListCustomServersRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListCustomServersRequest>(ListCustomServersRequest.$_createMessage);
  static ListCustomServersRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $1.ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion($1.ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => $_clearField(2);
}

class ListCustomServersResponse extends $pb.GeneratedMessage {
  factory ListCustomServersResponse({
    $core.Iterable<CustomServer>? servers,
    $1.SoraError? error,
  }) {
    final result = ListCustomServersResponse._();
    if (servers != null) result.servers.addAll(servers);
    if (error != null) result.error = error;
    return result;
  }

  ListCustomServersResponse._();

  factory ListCustomServersResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListCustomServersResponse()..mergeFromBuffer(data, registry);
  factory ListCustomServersResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListCustomServersResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ListCustomServersResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.custom.v1'),
      createEmptyInstance: ListCustomServersResponse.$_createMessage)
    ..pPM<CustomServer>(1, _omitFieldNames ? '' : 'servers', subBuilder: CustomServer.$_createMessage)
    ..aOM<$1.SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: $1.SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListCustomServersResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListCustomServersResponse copyWith(void Function(ListCustomServersResponse) updates) =>
      super.copyWith((message) => updates(message as ListCustomServersResponse)) as ListCustomServersResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListCustomServersResponse() / ListCustomServersResponse.new instead')
  static ListCustomServersResponse create() => ListCustomServersResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListCustomServersResponse._();
  @$core.override
  ListCustomServersResponse createEmptyInstance() => ListCustomServersResponse._();
  @$core.pragma('dart2js:noInline')
  static ListCustomServersResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListCustomServersResponse>(ListCustomServersResponse.$_createMessage);
  static ListCustomServersResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<CustomServer> get servers => $_getList(0);

  @$pb.TagNumber(2)
  $1.SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($1.SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.SoraError ensureError() => $_ensure(1);
}

class DeleteCustomServerRequest extends $pb.GeneratedMessage {
  factory DeleteCustomServerRequest({
    $1.ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    $core.String? id,
  }) {
    final result = DeleteCustomServerRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    if (id != null) result.id = id;
    return result;
  }

  DeleteCustomServerRequest._();

  factory DeleteCustomServerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteCustomServerRequest()..mergeFromBuffer(data, registry);
  factory DeleteCustomServerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteCustomServerRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeleteCustomServerRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.custom.v1'),
      createEmptyInstance: DeleteCustomServerRequest.$_createMessage)
    ..aOM<$1.ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: $1.ApiVersion.$_createMessage)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteCustomServerRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteCustomServerRequest copyWith(void Function(DeleteCustomServerRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteCustomServerRequest)) as DeleteCustomServerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DeleteCustomServerRequest() / DeleteCustomServerRequest.new instead')
  static DeleteCustomServerRequest create() => DeleteCustomServerRequest._();
  static $pb.GeneratedMessage $_createMessage() => DeleteCustomServerRequest._();
  @$core.override
  DeleteCustomServerRequest createEmptyInstance() => DeleteCustomServerRequest._();
  @$core.pragma('dart2js:noInline')
  static DeleteCustomServerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteCustomServerRequest>(DeleteCustomServerRequest.$_createMessage);
  static DeleteCustomServerRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $1.ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion($1.ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get id => $_getSZ(2);
  @$pb.TagNumber(3)
  set id($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasId() => $_has(2);
  @$pb.TagNumber(3)
  void clearId() => $_clearField(3);
}

class DeleteCustomServerResponse extends $pb.GeneratedMessage {
  factory DeleteCustomServerResponse({
    $1.SoraError? error,
  }) {
    final result = DeleteCustomServerResponse._();
    if (error != null) result.error = error;
    return result;
  }

  DeleteCustomServerResponse._();

  factory DeleteCustomServerResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteCustomServerResponse()..mergeFromBuffer(data, registry);
  factory DeleteCustomServerResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteCustomServerResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeleteCustomServerResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.custom.v1'),
      createEmptyInstance: DeleteCustomServerResponse.$_createMessage)
    ..aOM<$1.SoraError>(1, _omitFieldNames ? '' : 'error', subBuilder: $1.SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteCustomServerResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteCustomServerResponse copyWith(void Function(DeleteCustomServerResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteCustomServerResponse)) as DeleteCustomServerResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DeleteCustomServerResponse() / DeleteCustomServerResponse.new instead')
  static DeleteCustomServerResponse create() => DeleteCustomServerResponse._();
  static $pb.GeneratedMessage $_createMessage() => DeleteCustomServerResponse._();
  @$core.override
  DeleteCustomServerResponse createEmptyInstance() => DeleteCustomServerResponse._();
  @$core.pragma('dart2js:noInline')
  static DeleteCustomServerResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteCustomServerResponse>(DeleteCustomServerResponse.$_createMessage);
  static DeleteCustomServerResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $1.SoraError get error => $_getN(0);
  @$pb.TagNumber(1)
  set error($1.SoraError value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.SoraError ensureError() => $_ensure(0);
}

class TestCustomServerRequest extends $pb.GeneratedMessage {
  factory TestCustomServerRequest({
    $1.ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    $core.String? id,
    $core.int? timeoutMs,
  }) {
    final result = TestCustomServerRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    if (id != null) result.id = id;
    if (timeoutMs != null) result.timeoutMs = timeoutMs;
    return result;
  }

  TestCustomServerRequest._();

  factory TestCustomServerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TestCustomServerRequest()..mergeFromBuffer(data, registry);
  factory TestCustomServerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TestCustomServerRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TestCustomServerRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.custom.v1'),
      createEmptyInstance: TestCustomServerRequest.$_createMessage)
    ..aOM<$1.ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: $1.ApiVersion.$_createMessage)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'id')
    ..aI(4, _omitFieldNames ? '' : 'timeoutMs', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestCustomServerRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestCustomServerRequest copyWith(void Function(TestCustomServerRequest) updates) =>
      super.copyWith((message) => updates(message as TestCustomServerRequest)) as TestCustomServerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TestCustomServerRequest() / TestCustomServerRequest.new instead')
  static TestCustomServerRequest create() => TestCustomServerRequest._();
  static $pb.GeneratedMessage $_createMessage() => TestCustomServerRequest._();
  @$core.override
  TestCustomServerRequest createEmptyInstance() => TestCustomServerRequest._();
  @$core.pragma('dart2js:noInline')
  static TestCustomServerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TestCustomServerRequest>(TestCustomServerRequest.$_createMessage);
  static TestCustomServerRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $1.ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion($1.ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  $1.ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => $_clearField(2);

  /// Id of the stored server to test.
  @$pb.TagNumber(3)
  $core.String get id => $_getSZ(2);
  @$pb.TagNumber(3)
  set id($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasId() => $_has(2);
  @$pb.TagNumber(3)
  void clearId() => $_clearField(3);

  /// Handshake timeout in milliseconds. Clamped to 1000..30000; 0 selects
  /// the 5000ms default.
  @$pb.TagNumber(4)
  $core.int get timeoutMs => $_getIZ(3);
  @$pb.TagNumber(4)
  set timeoutMs($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTimeoutMs() => $_has(3);
  @$pb.TagNumber(4)
  void clearTimeoutMs() => $_clearField(4);
}

class TestCustomServerResponse extends $pb.GeneratedMessage {
  factory TestCustomServerResponse({
    $core.bool? reachable,
    $fixnum.Int64? latencyMs,
    $1.SoraError? error,
  }) {
    final result = TestCustomServerResponse._();
    if (reachable != null) result.reachable = reachable;
    if (latencyMs != null) result.latencyMs = latencyMs;
    if (error != null) result.error = error;
    return result;
  }

  TestCustomServerResponse._();

  factory TestCustomServerResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TestCustomServerResponse()..mergeFromBuffer(data, registry);
  factory TestCustomServerResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      TestCustomServerResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TestCustomServerResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.custom.v1'),
      createEmptyInstance: TestCustomServerResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'reachable')
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'latencyMs', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$1.SoraError>(3, _omitFieldNames ? '' : 'error', subBuilder: $1.SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestCustomServerResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TestCustomServerResponse copyWith(void Function(TestCustomServerResponse) updates) =>
      super.copyWith((message) => updates(message as TestCustomServerResponse)) as TestCustomServerResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use TestCustomServerResponse() / TestCustomServerResponse.new instead')
  static TestCustomServerResponse create() => TestCustomServerResponse._();
  static $pb.GeneratedMessage $_createMessage() => TestCustomServerResponse._();
  @$core.override
  TestCustomServerResponse createEmptyInstance() => TestCustomServerResponse._();
  @$core.pragma('dart2js:noInline')
  static TestCustomServerResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TestCustomServerResponse>(TestCustomServerResponse.$_createMessage);
  static TestCustomServerResponse? _defaultInstance;

  /// True when the TCP handshake completed within the timeout.
  @$pb.TagNumber(1)
  $core.bool get reachable => $_getBF(0);
  @$pb.TagNumber(1)
  set reachable($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReachable() => $_has(0);
  @$pb.TagNumber(1)
  void clearReachable() => $_clearField(1);

  /// Handshake round-trip in milliseconds, rounded down. Zero when
  /// unreachable or when the handshake took under a millisecond.
  @$pb.TagNumber(2)
  $fixnum.Int64 get latencyMs => $_getI64(1);
  @$pb.TagNumber(2)
  set latencyMs($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLatencyMs() => $_has(1);
  @$pb.TagNumber(2)
  void clearLatencyMs() => $_clearField(2);

  @$pb.TagNumber(3)
  $1.SoraError get error => $_getN(2);
  @$pb.TagNumber(3)
  set error($1.SoraError value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasError() => $_has(2);
  @$pb.TagNumber(3)
  void clearError() => $_clearField(3);
  @$pb.TagNumber(3)
  $1.SoraError ensureError() => $_ensure(2);
}

const $core.bool _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
