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

/// ExtensionHost runs workers for the app, which owns extension installation,
/// signature verification, grants, settings and revocation enforcement.
/// The control token and transport authenticate the app's delegation.
@$pb.GrpcServiceName('sora.ext.v1.ExtensionHost')
class ExtensionHostClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ExtensionHostClient(super.channel, {super.options, super.interceptors});

  /// Closing the app-owned lifecycle stream unregisters and cancels the worker.
  $grpc.ResponseStream<$0.WorkerHostMessage> runWorker(
    $async.Stream<$0.WorkerClientMessage> request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$runWorker, request, options: options);
  }

  // method descriptors

  static final _$runWorker = $grpc.ClientMethod<$0.WorkerClientMessage, $0.WorkerHostMessage>(
      '/sora.ext.v1.ExtensionHost/RunWorker',
      ($0.WorkerClientMessage value) => value.writeToBuffer(),
      $0.WorkerHostMessage.fromBuffer);
}

@$pb.GrpcServiceName('sora.ext.v1.ExtensionHost')
abstract class ExtensionHostServiceBase extends $grpc.Service {
  $core.String get $name => 'sora.ext.v1.ExtensionHost';

  ExtensionHostServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.WorkerClientMessage, $0.WorkerHostMessage>(
        'RunWorker',
        runWorker,
        true,
        true,
        ($core.List<$core.int> value) => $0.WorkerClientMessage.fromBuffer(value),
        ($0.WorkerHostMessage value) => value.writeToBuffer()));
  }

  $async.Stream<$0.WorkerHostMessage> runWorker($grpc.ServiceCall call, $async.Stream<$0.WorkerClientMessage> request);
}
