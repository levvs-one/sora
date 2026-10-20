// This is a generated file - do not edit.
//
// Generated from sora/ext/v1/ext_host.proto.

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

import 'ext_host.pb.dart' as $0;

export 'ext_host.pb.dart';

/// ExtensionHost is the core-side API for installed extensions. Since 1.10.
///
/// Panels run in a WebView inside the app and talk to the app over a JS
/// bridge. The app forwards the calls an extension is permitted to make to
/// this service. Every extension call carries a per-extension token minted by
/// MintToken; the token is scoped to the extension's granted permissions, so a
/// compromised or malicious panel cannot reach APIs it was not granted.
///
/// MintToken and RevokeToken are app-only: they require the core control
/// token, exactly like Connect and Disconnect on CoreControl.
@$pb.GrpcServiceName('sora.ext.v1.ExtensionHost')
class ExtensionHostClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ExtensionHostClient(super.channel, {super.options, super.interceptors});

  /// MintToken issues a scoped token for an enabled extension. App only.
  $grpc.ResponseFuture<$0.MintTokenResponse> mintToken(
    $0.MintTokenRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$mintToken, request, options: options);
  }

  /// RevokeToken invalidates a previously minted token. App only.
  $grpc.ResponseFuture<$0.RevokeTokenResponse> revokeToken(
    $0.RevokeTokenRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$revokeToken, request, options: options);
  }

  /// GetConnections needs the "connections.read" permission.
  $grpc.ResponseFuture<$0.GetConnectionsResponse> getConnections(
    $0.GetConnectionsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getConnections, request, options: options);
  }

  /// GetServers needs the "servers.read" permission.
  $grpc.ResponseFuture<$0.GetServersResponse> getServers(
    $0.GetServersRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$getServers, request, options: options);
  }

  /// Notify needs the "notifications" permission.
  $grpc.ResponseFuture<$0.NotifyResponse> notify(
    $0.NotifyRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createUnaryCall(_$notify, request, options: options);
  }

  /// WatchExtensionEvents streams lifecycle and network events. It needs no
  /// extra permission beyond a valid token: every enabled extension may know
  /// whether the session is up.
  $grpc.ResponseStream<$0.ExtensionEvent> watchExtensionEvents(
    $0.WatchExtensionEventsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(
        _$watchExtensionEvents, $async.Stream.fromIterable([request]),
        options: options);
  }

  // method descriptors

  static final _$mintToken =
      $grpc.ClientMethod<$0.MintTokenRequest, $0.MintTokenResponse>(
          '/sora.ext.v1.ExtensionHost/MintToken',
          ($0.MintTokenRequest value) => value.writeToBuffer(),
          $0.MintTokenResponse.fromBuffer);
  static final _$revokeToken =
      $grpc.ClientMethod<$0.RevokeTokenRequest, $0.RevokeTokenResponse>(
          '/sora.ext.v1.ExtensionHost/RevokeToken',
          ($0.RevokeTokenRequest value) => value.writeToBuffer(),
          $0.RevokeTokenResponse.fromBuffer);
  static final _$getConnections =
      $grpc.ClientMethod<$0.GetConnectionsRequest, $0.GetConnectionsResponse>(
          '/sora.ext.v1.ExtensionHost/GetConnections',
          ($0.GetConnectionsRequest value) => value.writeToBuffer(),
          $0.GetConnectionsResponse.fromBuffer);
  static final _$getServers =
      $grpc.ClientMethod<$0.GetServersRequest, $0.GetServersResponse>(
          '/sora.ext.v1.ExtensionHost/GetServers',
          ($0.GetServersRequest value) => value.writeToBuffer(),
          $0.GetServersResponse.fromBuffer);
  static final _$notify =
      $grpc.ClientMethod<$0.NotifyRequest, $0.NotifyResponse>(
          '/sora.ext.v1.ExtensionHost/Notify',
          ($0.NotifyRequest value) => value.writeToBuffer(),
          $0.NotifyResponse.fromBuffer);
  static final _$watchExtensionEvents =
      $grpc.ClientMethod<$0.WatchExtensionEventsRequest, $0.ExtensionEvent>(
          '/sora.ext.v1.ExtensionHost/WatchExtensionEvents',
          ($0.WatchExtensionEventsRequest value) => value.writeToBuffer(),
          $0.ExtensionEvent.fromBuffer);
}

@$pb.GrpcServiceName('sora.ext.v1.ExtensionHost')
abstract class ExtensionHostServiceBase extends $grpc.Service {
  $core.String get $name => 'sora.ext.v1.ExtensionHost';

  ExtensionHostServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.MintTokenRequest, $0.MintTokenResponse>(
        'MintToken',
        mintToken_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.MintTokenRequest.fromBuffer(value),
        ($0.MintTokenResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.RevokeTokenRequest, $0.RevokeTokenResponse>(
            'RevokeToken',
            revokeToken_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.RevokeTokenRequest.fromBuffer(value),
            ($0.RevokeTokenResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetConnectionsRequest,
            $0.GetConnectionsResponse>(
        'GetConnections',
        getConnections_Pre,
        false,
        false,
        ($core.List<$core.int> value) =>
            $0.GetConnectionsRequest.fromBuffer(value),
        ($0.GetConnectionsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetServersRequest, $0.GetServersResponse>(
        'GetServers',
        getServers_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetServersRequest.fromBuffer(value),
        ($0.GetServersResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.NotifyRequest, $0.NotifyResponse>(
        'Notify',
        notify_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.NotifyRequest.fromBuffer(value),
        ($0.NotifyResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.WatchExtensionEventsRequest, $0.ExtensionEvent>(
            'WatchExtensionEvents',
            watchExtensionEvents_Pre,
            false,
            true,
            ($core.List<$core.int> value) =>
                $0.WatchExtensionEventsRequest.fromBuffer(value),
            ($0.ExtensionEvent value) => value.writeToBuffer()));
  }

  $async.Future<$0.MintTokenResponse> mintToken_Pre($grpc.ServiceCall $call,
      $async.Future<$0.MintTokenRequest> $request) async {
    return mintToken($call, await $request);
  }

  $async.Future<$0.MintTokenResponse> mintToken(
      $grpc.ServiceCall call, $0.MintTokenRequest request);

  $async.Future<$0.RevokeTokenResponse> revokeToken_Pre($grpc.ServiceCall $call,
      $async.Future<$0.RevokeTokenRequest> $request) async {
    return revokeToken($call, await $request);
  }

  $async.Future<$0.RevokeTokenResponse> revokeToken(
      $grpc.ServiceCall call, $0.RevokeTokenRequest request);

  $async.Future<$0.GetConnectionsResponse> getConnections_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.GetConnectionsRequest> $request) async {
    return getConnections($call, await $request);
  }

  $async.Future<$0.GetConnectionsResponse> getConnections(
      $grpc.ServiceCall call, $0.GetConnectionsRequest request);

  $async.Future<$0.GetServersResponse> getServers_Pre($grpc.ServiceCall $call,
      $async.Future<$0.GetServersRequest> $request) async {
    return getServers($call, await $request);
  }

  $async.Future<$0.GetServersResponse> getServers(
      $grpc.ServiceCall call, $0.GetServersRequest request);

  $async.Future<$0.NotifyResponse> notify_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.NotifyRequest> $request) async {
    return notify($call, await $request);
  }

  $async.Future<$0.NotifyResponse> notify(
      $grpc.ServiceCall call, $0.NotifyRequest request);

  $async.Stream<$0.ExtensionEvent> watchExtensionEvents_Pre(
      $grpc.ServiceCall $call,
      $async.Future<$0.WatchExtensionEventsRequest> $request) async* {
    yield* watchExtensionEvents($call, await $request);
  }

  $async.Stream<$0.ExtensionEvent> watchExtensionEvents(
      $grpc.ServiceCall call, $0.WatchExtensionEventsRequest request);
}
