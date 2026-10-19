// Hand-written stubs for sora/custom/v1/custom.proto.
//
// protoc is unavailable in this environment, so this client mirrors the
// protoc-gen-dart output by hand and follows the layout of the generated
// sora/core/v1 client. Replace with real generated code once the proto lands.

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

  $grpc.ResponseFuture<$0.ListCustomServersResponse> listCustomServers(
    $0.ListCustomServersRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$listCustomServers, request, options: options);
  }

  $grpc.ResponseFuture<$0.CreateCustomServerResponse> createCustomServer(
    $0.CreateCustomServerRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$createCustomServer, request, options: options);
  }

  $grpc.ResponseFuture<$0.UpdateCustomServerResponse> updateCustomServer(
    $0.UpdateCustomServerRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$updateCustomServer, request, options: options);
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

  static final _$listCustomServers =
      $grpc.ClientMethod<$0.ListCustomServersRequest, $0.ListCustomServersResponse>(
          '/sora.custom.v1.CustomServers/ListCustomServers',
          ($0.ListCustomServersRequest value) => value.writeToBuffer(),
          $0.ListCustomServersResponse.fromBuffer);
  static final _$createCustomServer =
      $grpc.ClientMethod<$0.CreateCustomServerRequest, $0.CreateCustomServerResponse>(
          '/sora.custom.v1.CustomServers/CreateCustomServer',
          ($0.CreateCustomServerRequest value) => value.writeToBuffer(),
          $0.CreateCustomServerResponse.fromBuffer);
  static final _$updateCustomServer =
      $grpc.ClientMethod<$0.UpdateCustomServerRequest, $0.UpdateCustomServerResponse>(
          '/sora.custom.v1.CustomServers/UpdateCustomServer',
          ($0.UpdateCustomServerRequest value) => value.writeToBuffer(),
          $0.UpdateCustomServerResponse.fromBuffer);
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
