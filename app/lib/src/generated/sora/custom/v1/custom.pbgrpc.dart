// Hand-written stubs for sora/custom/v1/custom.proto.
//
// protoc is unavailable in this environment, so this client mirrors the
// protoc-gen-dart output by hand and follows the layout of the generated
// sora/core/v1 client. Replace with real generated code once the proto lands.
//
// Service contract (must match proto/sora/custom/v1/custom.proto):
//   service CustomServers {
//     rpc SaveCustomServer(SaveCustomServerRequest) returns (SaveCustomServerResponse);
//     rpc ListCustomServers(ListCustomServersRequest) returns (ListCustomServersResponse);
//     rpc DeleteCustomServer(DeleteCustomServerRequest) returns (DeleteCustomServerResponse);
//     rpc TestCustomServer(TestCustomServerRequest) returns (TestCustomServerResponse);
//   }

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'custom.pb.dart' as $0;

export 'custom.pb.dart';

/// CustomServers manages user-added servers stored by the core outside
/// subscriptions.
@$pb.GrpcServiceName('sora.custom.v1.CustomServers')
class CustomServersClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for this client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  CustomServersClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.SaveCustomServerResponse> saveCustomServer(
    $0.SaveCustomServerRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$saveCustomServer, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListCustomServersResponse> listCustomServers(
    $0.ListCustomServersRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listCustomServers, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteCustomServerResponse> deleteCustomServer(
    $0.DeleteCustomServerRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$deleteCustomServer, request, options: options);
  }

  $grpc.ResponseFuture<$0.TestCustomServerResponse> testCustomServer(
    $0.TestCustomServerRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$testCustomServer, request, options: options);
  }

  static final _$saveCustomServer =
      $grpc.ClientMethod<$0.SaveCustomServerRequest, $0.SaveCustomServerResponse>(
          '/sora.custom.v1.CustomServers/SaveCustomServer',
          ($0.SaveCustomServerRequest value) => value.writeToBuffer(),
          $0.SaveCustomServerResponse.fromBuffer);
  static final _$listCustomServers =
      $grpc.ClientMethod<$0.ListCustomServersRequest, $0.ListCustomServersResponse>(
          '/sora.custom.v1.CustomServers/ListCustomServers',
          ($0.ListCustomServersRequest value) => value.writeToBuffer(),
          $0.ListCustomServersResponse.fromBuffer);
  static final _$deleteCustomServer =
      $grpc.ClientMethod<$0.DeleteCustomServerRequest, $0.DeleteCustomServerResponse>(
          '/sora.custom.v1.CustomServers/DeleteCustomServer',
          ($0.DeleteCustomServerRequest value) => value.writeToBuffer(),
          $0.DeleteCustomServerResponse.fromBuffer);
  static final _$testCustomServer =
      $grpc.ClientMethod<$0.TestCustomServerRequest, $0.TestCustomServerResponse>(
          '/sora.custom.v1.CustomServers/TestCustomServer',
          ($0.TestCustomServerRequest value) => value.writeToBuffer(),
          $0.TestCustomServerResponse.fromBuffer);
}
