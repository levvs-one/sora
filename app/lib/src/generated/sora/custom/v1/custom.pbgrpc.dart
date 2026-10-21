// This is a generated file - do not edit.
//
// Generated from sora/custom/v1/custom.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'custom.pb.dart' as $0;

export 'custom.pb.dart';

/// CustomServers manages servers the user adds manually, outside
/// subscriptions. Every RPC requires control authorization: the shared gRPC
/// interceptors admit only control peers (unknown methods default to
/// control-only), and each request carries the control authenticator plus an
/// API version for the contract check.
///
/// Since 1.11. Older cores answer these methods with UNIMPLEMENTED; clients
/// must treat that as "custom servers unavailable", not as a failure.
///
/// Credentials are write-only: SaveCustomServer accepts them, List and the
/// other RPCs never return them, and TestCustomServer never sends them.
@$pb.GrpcServiceName('sora.custom.v1.CustomServers')
class CustomServersClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  CustomServersClient(super.channel, {super.options, super.interceptors});

  /// SaveCustomServer creates a server (empty id) or updates an existing one.
  $grpc.ResponseFuture<$0.SaveCustomServerResponse> saveCustomServer(
    $0.SaveCustomServerRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveCustomServer, request, options: options);
  }

  /// ListCustomServers returns every stored custom server without credentials.
  $grpc.ResponseFuture<$0.ListCustomServersResponse> listCustomServers(
    $0.ListCustomServersRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listCustomServers, request, options: options);
  }

  /// DeleteCustomServer removes a server together with its stored credentials.
  $grpc.ResponseFuture<$0.DeleteCustomServerResponse> deleteCustomServer(
    $0.DeleteCustomServerRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteCustomServer, request, options: options);
  }

  /// TestCustomServer checks reachability with a TCP handshake and a timeout.
  /// No credentials are sent or returned. The address is resolved with the
  /// system DNS resolver, outside any tunnel: probing a server discloses its
  /// address to the local network, which is expected for a user-initiated
  /// check.
  $grpc.ResponseFuture<$0.TestCustomServerResponse> testCustomServer(
    $0.TestCustomServerRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$testCustomServer, request, options: options);
  }

  // method descriptors

  static final _$saveCustomServer = $grpc.ClientMethod<$0.SaveCustomServerRequest, $0.SaveCustomServerResponse>(
      '/sora.custom.v1.CustomServers/SaveCustomServer',
      ($0.SaveCustomServerRequest value) => value.writeToBuffer(),
      $0.SaveCustomServerResponse.fromBuffer);
  static final _$listCustomServers = $grpc.ClientMethod<$0.ListCustomServersRequest, $0.ListCustomServersResponse>(
      '/sora.custom.v1.CustomServers/ListCustomServers',
      ($0.ListCustomServersRequest value) => value.writeToBuffer(),
      $0.ListCustomServersResponse.fromBuffer);
  static final _$deleteCustomServer = $grpc.ClientMethod<$0.DeleteCustomServerRequest, $0.DeleteCustomServerResponse>(
      '/sora.custom.v1.CustomServers/DeleteCustomServer',
      ($0.DeleteCustomServerRequest value) => value.writeToBuffer(),
      $0.DeleteCustomServerResponse.fromBuffer);
  static final _$testCustomServer = $grpc.ClientMethod<$0.TestCustomServerRequest, $0.TestCustomServerResponse>(
      '/sora.custom.v1.CustomServers/TestCustomServer',
      ($0.TestCustomServerRequest value) => value.writeToBuffer(),
      $0.TestCustomServerResponse.fromBuffer);
}

@$pb.GrpcServiceName('sora.custom.v1.CustomServers')
abstract class CustomServersServiceBase extends $grpc.Service {
  $core.String get $name => 'sora.custom.v1.CustomServers';

  CustomServersServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.SaveCustomServerRequest, $0.SaveCustomServerResponse>(
        'SaveCustomServer',
        saveCustomServer_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SaveCustomServerRequest.fromBuffer(value),
        ($0.SaveCustomServerResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListCustomServersRequest, $0.ListCustomServersResponse>(
        'ListCustomServers',
        listCustomServers_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListCustomServersRequest.fromBuffer(value),
        ($0.ListCustomServersResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteCustomServerRequest, $0.DeleteCustomServerResponse>(
        'DeleteCustomServer',
        deleteCustomServer_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DeleteCustomServerRequest.fromBuffer(value),
        ($0.DeleteCustomServerResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.TestCustomServerRequest, $0.TestCustomServerResponse>(
        'TestCustomServer',
        testCustomServer_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.TestCustomServerRequest.fromBuffer(value),
        ($0.TestCustomServerResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.SaveCustomServerResponse> saveCustomServer_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.SaveCustomServerRequest> $request) async {
    return saveCustomServer($call, await $request);
  }

  $async.Future<$0.SaveCustomServerResponse> saveCustomServer(
      $grpc.ServiceCall call, $0.SaveCustomServerRequest request);

  $async.Future<$0.ListCustomServersResponse> listCustomServers_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.ListCustomServersRequest> $request) async {
    return listCustomServers($call, await $request);
  }

  $async.Future<$0.ListCustomServersResponse> listCustomServers(
      $grpc.ServiceCall call, $0.ListCustomServersRequest request);

  $async.Future<$0.DeleteCustomServerResponse> deleteCustomServer_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.DeleteCustomServerRequest> $request) async {
    return deleteCustomServer($call, await $request);
  }

  $async.Future<$0.DeleteCustomServerResponse> deleteCustomServer(
      $grpc.ServiceCall call, $0.DeleteCustomServerRequest request);

  $async.Future<$0.TestCustomServerResponse> testCustomServer_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.TestCustomServerRequest> $request) async {
    return testCustomServer($call, await $request);
  }

  $async.Future<$0.TestCustomServerResponse> testCustomServer(
      $grpc.ServiceCall call, $0.TestCustomServerRequest request);
}
