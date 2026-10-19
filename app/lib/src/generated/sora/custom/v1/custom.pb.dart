// Hand-written stubs for sora/custom/v1/custom.proto.
//
// protoc is unavailable in this environment, so these classes mirror the
// protoc-gen-dart output by hand and follow the layout of the generated
// sora/core/v1 files. Replace with real generated code once the proto lands.
//
// Wire contract (must match proto/sora/custom/v1/custom.proto):
//   package sora.custom.v1; imports sora/core/v1/core_control.proto
//   message CustomServer {
//     string id = 1;        // assigned by the core on create; empty on create requests
//     string name = 2;
//     string protocol = 3;  // vless | vmess | trojan | shadowsocks | wireguard | hysteria2 | tuic
//     string address = 4;   // hostname or IP
//     uint32 port = 5;
//     string username = 6;  // optional
//     string password = 7;  // write-only: accepted on create/update, never returned
//     bool secret_stored = 8;  // response-only: a secret is stored for this server
//   }
//   message ListCustomServersRequest  { ApiVersion api_version = 1; bytes control_authenticator = 2; }
//   message ListCustomServersResponse { SoraError error = 1; repeated CustomServer servers = 2; }
//   message CreateCustomServerRequest  { ApiVersion api_version = 1; bytes control_authenticator = 2; CustomServer server = 3; }
//   message CreateCustomServerResponse { SoraError error = 1; CustomServer server = 2; }
//   message UpdateCustomServerRequest  { ApiVersion api_version = 1; bytes control_authenticator = 2; CustomServer server = 3; }
//   message UpdateCustomServerResponse { SoraError error = 1; CustomServer server = 2; }
//   message DeleteCustomServerRequest  { ApiVersion api_version = 1; bytes control_authenticator = 2; string id = 3; }
//   message DeleteCustomServerResponse { SoraError error = 1; }
//   message TestCustomServerRequest  { ApiVersion api_version = 1; bytes control_authenticator = 2; CustomServer server = 3; }
//   message TestCustomServerResponse { SoraError error = 1; bool ok = 2; uint32 latency_ms = 3; }

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../../core/v1/core_control.pb.dart' as $0;

const $core.bool _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');

/// A user-added server, stored by the core outside subscriptions.
class CustomServer extends $pb.GeneratedMessage {
  factory CustomServer({
    $core.String? id,
    $core.String? name,
    $core.String? protocol,
    $core.String? address,
    $core.int? port,
    $core.String? username,
    $core.String? password,
    $core.bool? secretStored,
  }) {
    final result = CustomServer._();
    if (id != null) result.id = id;
    if (name != null) result.name = name;
    if (protocol != null) result.protocol = protocol;
    if (address != null) result.address = address;
    if (port != null) result.port = port;
    if (username != null) result.username = username;
    if (password != null) result.password = password;
    if (secretStored != null) result.secretStored = secretStored;
    return result;
  }

  CustomServer._();

  factory CustomServer.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CustomServer()..mergeFromBuffer(data, registry);
  factory CustomServer.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CustomServer()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CustomServer',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.custom.v1'),
      createEmptyInstance: CustomServer.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'protocol')
    ..aOS(4, _omitFieldNames ? '' : 'address')
    ..aI(5, _omitFieldNames ? '' : 'port', fieldType: $pb.PbFieldType.OU3)
    ..aOS(6, _omitFieldNames ? '' : 'username')
    ..aOS(7, _omitFieldNames ? '' : 'password')
    ..aOB(8, _omitFieldNames ? '' : 'secretStored')
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
  $core.String get protocol => $_getSZ(2);
  @$pb.TagNumber(3)
  set protocol($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProtocol() => $_has(2);
  @$pb.TagNumber(3)
  void clearProtocol() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get address => $_getSZ(3);
  @$pb.TagNumber(4)
  set address($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAddress() => $_has(3);
  @$pb.TagNumber(4)
  void clearAddress() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get port => $_getIZ(4);
  @$pb.TagNumber(5)
  set port($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPort() => $_has(4);
  @$pb.TagNumber(5)
  void clearPort() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get username => $_getSZ(5);
  @$pb.TagNumber(6)
  set username($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasUsername() => $_has(5);
  @$pb.TagNumber(6)
  void clearUsername() => $_clearField(6);

  /// Write-only: accepted on create/update, never returned by the core.
  @$pb.TagNumber(7)
  $core.String get password => $_getSZ(6);
  @$pb.TagNumber(7)
  set password($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasPassword() => $_has(6);
  @$pb.TagNumber(7)
  void clearPassword() => $_clearField(7);

  /// Response-only: a secret is stored for this server.
  @$pb.TagNumber(8)
  $core.bool get secretStored => $_getBF(7);
  @$pb.TagNumber(8)
  set secretStored($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasSecretStored() => $_has(7);
  @$pb.TagNumber(8)
  void clearSecretStored() => $_clearField(8);
}

class ListCustomServersRequest extends $pb.GeneratedMessage {
  factory ListCustomServersRequest({
    $0.ApiVersion? apiVersion,
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
    ..aOM<$0.ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: $0.ApiVersion.$_createMessage)
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
  $0.ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion($0.ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.ApiVersion ensureApiVersion() => $_ensure(0);

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
    $0.SoraError? error,
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
    ..aOM<$0.SoraError>(1, _omitFieldNames ? '' : 'error', subBuilder: $0.SoraError.$_createMessage)
    ..pPM<CustomServer>(2, _omitFieldNames ? '' : 'servers', subBuilder: CustomServer.$_createMessage)
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
  $0.SoraError get error => $_getN(0);
  @$pb.TagNumber(1)
  set error($0.SoraError value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.SoraError ensureError() => $_ensure(0);

  @$pb.TagNumber(2)
  $pb.PbList<CustomServer> get servers => $_getList(1);
}

class CreateCustomServerRequest extends $pb.GeneratedMessage {
  factory CreateCustomServerRequest({
    $0.ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    CustomServer? server,
  }) {
    final result = CreateCustomServerRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    if (server != null) result.server = server;
    return result;
  }

  CreateCustomServerRequest._();

  factory CreateCustomServerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateCustomServerRequest()..mergeFromBuffer(data, registry);
  factory CreateCustomServerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateCustomServerRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CreateCustomServerRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.custom.v1'),
      createEmptyInstance: CreateCustomServerRequest.$_createMessage)
    ..aOM<$0.ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: $0.ApiVersion.$_createMessage)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOM<CustomServer>(3, _omitFieldNames ? '' : 'server', subBuilder: CustomServer.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateCustomServerRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateCustomServerRequest copyWith(void Function(CreateCustomServerRequest) updates) =>
      super.copyWith((message) => updates(message as CreateCustomServerRequest)) as CreateCustomServerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CreateCustomServerRequest() / CreateCustomServerRequest.new instead')
  static CreateCustomServerRequest create() => CreateCustomServerRequest._();
  static $pb.GeneratedMessage $_createMessage() => CreateCustomServerRequest._();
  @$core.override
  CreateCustomServerRequest createEmptyInstance() => CreateCustomServerRequest._();
  @$core.pragma('dart2js:noInline')
  static CreateCustomServerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateCustomServerRequest>(CreateCustomServerRequest.$_createMessage);
  static CreateCustomServerRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $0.ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion($0.ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.ApiVersion ensureApiVersion() => $_ensure(0);

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

class CreateCustomServerResponse extends $pb.GeneratedMessage {
  factory CreateCustomServerResponse({
    $0.SoraError? error,
    CustomServer? server,
  }) {
    final result = CreateCustomServerResponse._();
    if (error != null) result.error = error;
    if (server != null) result.server = server;
    return result;
  }

  CreateCustomServerResponse._();

  factory CreateCustomServerResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateCustomServerResponse()..mergeFromBuffer(data, registry);
  factory CreateCustomServerResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CreateCustomServerResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CreateCustomServerResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.custom.v1'),
      createEmptyInstance: CreateCustomServerResponse.$_createMessage)
    ..aOM<$0.SoraError>(1, _omitFieldNames ? '' : 'error', subBuilder: $0.SoraError.$_createMessage)
    ..aOM<CustomServer>(2, _omitFieldNames ? '' : 'server', subBuilder: CustomServer.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateCustomServerResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CreateCustomServerResponse copyWith(void Function(CreateCustomServerResponse) updates) =>
      super.copyWith((message) => updates(message as CreateCustomServerResponse)) as CreateCustomServerResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CreateCustomServerResponse() / CreateCustomServerResponse.new instead')
  static CreateCustomServerResponse create() => CreateCustomServerResponse._();
  static $pb.GeneratedMessage $_createMessage() => CreateCustomServerResponse._();
  @$core.override
  CreateCustomServerResponse createEmptyInstance() => CreateCustomServerResponse._();
  @$core.pragma('dart2js:noInline')
  static CreateCustomServerResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CreateCustomServerResponse>(CreateCustomServerResponse.$_createMessage);
  static CreateCustomServerResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $0.SoraError get error => $_getN(0);
  @$pb.TagNumber(1)
  set error($0.SoraError value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.SoraError ensureError() => $_ensure(0);

  @$pb.TagNumber(2)
  CustomServer get server => $_getN(1);
  @$pb.TagNumber(2)
  set server(CustomServer value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasServer() => $_has(1);
  @$pb.TagNumber(2)
  void clearServer() => $_clearField(2);
  @$pb.TagNumber(2)
  CustomServer ensureServer() => $_ensure(1);
}

class UpdateCustomServerRequest extends $pb.GeneratedMessage {
  factory UpdateCustomServerRequest({
    $0.ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    CustomServer? server,
  }) {
    final result = UpdateCustomServerRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    if (server != null) result.server = server;
    return result;
  }

  UpdateCustomServerRequest._();

  factory UpdateCustomServerRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateCustomServerRequest()..mergeFromBuffer(data, registry);
  factory UpdateCustomServerRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateCustomServerRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'UpdateCustomServerRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.custom.v1'),
      createEmptyInstance: UpdateCustomServerRequest.$_createMessage)
    ..aOM<$0.ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: $0.ApiVersion.$_createMessage)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOM<CustomServer>(3, _omitFieldNames ? '' : 'server', subBuilder: CustomServer.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateCustomServerRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateCustomServerRequest copyWith(void Function(UpdateCustomServerRequest) updates) =>
      super.copyWith((message) => updates(message as UpdateCustomServerRequest)) as UpdateCustomServerRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UpdateCustomServerRequest() / UpdateCustomServerRequest.new instead')
  static UpdateCustomServerRequest create() => UpdateCustomServerRequest._();
  static $pb.GeneratedMessage $_createMessage() => UpdateCustomServerRequest._();
  @$core.override
  UpdateCustomServerRequest createEmptyInstance() => UpdateCustomServerRequest._();
  @$core.pragma('dart2js:noInline')
  static UpdateCustomServerRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateCustomServerRequest>(UpdateCustomServerRequest.$_createMessage);
  static UpdateCustomServerRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $0.ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion($0.ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.ApiVersion ensureApiVersion() => $_ensure(0);

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

class UpdateCustomServerResponse extends $pb.GeneratedMessage {
  factory UpdateCustomServerResponse({
    $0.SoraError? error,
    CustomServer? server,
  }) {
    final result = UpdateCustomServerResponse._();
    if (error != null) result.error = error;
    if (server != null) result.server = server;
    return result;
  }

  UpdateCustomServerResponse._();

  factory UpdateCustomServerResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateCustomServerResponse()..mergeFromBuffer(data, registry);
  factory UpdateCustomServerResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      UpdateCustomServerResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'UpdateCustomServerResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.custom.v1'),
      createEmptyInstance: UpdateCustomServerResponse.$_createMessage)
    ..aOM<$0.SoraError>(1, _omitFieldNames ? '' : 'error', subBuilder: $0.SoraError.$_createMessage)
    ..aOM<CustomServer>(2, _omitFieldNames ? '' : 'server', subBuilder: CustomServer.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateCustomServerResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateCustomServerResponse copyWith(void Function(UpdateCustomServerResponse) updates) =>
      super.copyWith((message) => updates(message as UpdateCustomServerResponse)) as UpdateCustomServerResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use UpdateCustomServerResponse() / UpdateCustomServerResponse.new instead')
  static UpdateCustomServerResponse create() => UpdateCustomServerResponse._();
  static $pb.GeneratedMessage $_createMessage() => UpdateCustomServerResponse._();
  @$core.override
  UpdateCustomServerResponse createEmptyInstance() => UpdateCustomServerResponse._();
  @$core.pragma('dart2js:noInline')
  static UpdateCustomServerResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateCustomServerResponse>(UpdateCustomServerResponse.$_createMessage);
  static UpdateCustomServerResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $0.SoraError get error => $_getN(0);
  @$pb.TagNumber(1)
  set error($0.SoraError value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.SoraError ensureError() => $_ensure(0);

  @$pb.TagNumber(2)
  CustomServer get server => $_getN(1);
  @$pb.TagNumber(2)
  set server(CustomServer value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasServer() => $_has(1);
  @$pb.TagNumber(2)
  void clearServer() => $_clearField(2);
  @$pb.TagNumber(2)
  CustomServer ensureServer() => $_ensure(1);
}

class DeleteCustomServerRequest extends $pb.GeneratedMessage {
  factory DeleteCustomServerRequest({
    $0.ApiVersion? apiVersion,
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
    ..aOM<$0.ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: $0.ApiVersion.$_createMessage)
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
  $0.ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion($0.ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.ApiVersion ensureApiVersion() => $_ensure(0);

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
    $0.SoraError? error,
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
    ..aOM<$0.SoraError>(1, _omitFieldNames ? '' : 'error', subBuilder: $0.SoraError.$_createMessage)
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
  $0.SoraError get error => $_getN(0);
  @$pb.TagNumber(1)
  set error($0.SoraError value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.SoraError ensureError() => $_ensure(0);
}

class TestCustomServerRequest extends $pb.GeneratedMessage {
  factory TestCustomServerRequest({
    $0.ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    CustomServer? server,
  }) {
    final result = TestCustomServerRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    if (server != null) result.server = server;
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
    ..aOM<$0.ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: $0.ApiVersion.$_createMessage)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOM<CustomServer>(3, _omitFieldNames ? '' : 'server', subBuilder: CustomServer.$_createMessage)
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
  $0.ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion($0.ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.ApiVersion ensureApiVersion() => $_ensure(0);

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

class TestCustomServerResponse extends $pb.GeneratedMessage {
  factory TestCustomServerResponse({
    $0.SoraError? error,
    $core.bool? ok,
    $core.int? latencyMs,
  }) {
    final result = TestCustomServerResponse._();
    if (error != null) result.error = error;
    if (ok != null) result.ok = ok;
    if (latencyMs != null) result.latencyMs = latencyMs;
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
    ..aOM<$0.SoraError>(1, _omitFieldNames ? '' : 'error', subBuilder: $0.SoraError.$_createMessage)
    ..aOB(2, _omitFieldNames ? '' : 'ok')
    ..aI(3, _omitFieldNames ? '' : 'latencyMs', fieldType: $pb.PbFieldType.OU3)
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

  @$pb.TagNumber(1)
  $0.SoraError get error => $_getN(0);
  @$pb.TagNumber(1)
  set error($0.SoraError value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => $_clearField(1);
  @$pb.TagNumber(1)
  $0.SoraError ensureError() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.bool get ok => $_getBF(1);
  @$pb.TagNumber(2)
  set ok($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOk() => $_has(1);
  @$pb.TagNumber(2)
  void clearOk() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get latencyMs => $_getIZ(2);
  @$pb.TagNumber(3)
  set latencyMs($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLatencyMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearLatencyMs() => $_clearField(3);
}
