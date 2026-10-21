// This is a generated file - do not edit.
//
// Generated from sora/leak/v1/leak.proto.

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

import 'leak.pb.dart' as $0;

export 'leak.pb.dart';

/// LeakService runs the core's egress self-tests: active probes that verify
/// no byte leaves the machine outside the tunnel. Since 1.11.
@$pb.GrpcServiceName('sora.leak.v1.LeakService')
class LeakServiceClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  LeakServiceClient(super.channel, {super.options, super.interceptors});

  /// RunLeakTests streams one LeakTestResult per test as it completes.
  /// Requires the control authenticator: the results describe the machine's
  /// network path. Needs an active session; without one the call fails.
  $grpc.ResponseStream<$0.LeakTestResult> runLeakTests(
    $0.RunLeakTestsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$runLeakTests, $async.Stream.fromIterable([request]), options: options);
  }

  // method descriptors

  static final _$runLeakTests = $grpc.ClientMethod<$0.RunLeakTestsRequest, $0.LeakTestResult>(
      '/sora.leak.v1.LeakService/RunLeakTests',
      ($0.RunLeakTestsRequest value) => value.writeToBuffer(),
      $0.LeakTestResult.fromBuffer);
}

@$pb.GrpcServiceName('sora.leak.v1.LeakService')
abstract class LeakServiceBase extends $grpc.Service {
  $core.String get $name => 'sora.leak.v1.LeakService';

  LeakServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.RunLeakTestsRequest, $0.LeakTestResult>(
        'RunLeakTests',
        runLeakTests_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.RunLeakTestsRequest.fromBuffer(value),
        ($0.LeakTestResult value) => value.writeToBuffer()));
  }

  $async.Stream<$0.LeakTestResult> runLeakTests_Pre(
      $grpc.ServiceCall $call, $async.Future<$0.RunLeakTestsRequest> $request) async* {
    yield* runLeakTests($call, await $request);
  }

  $async.Stream<$0.LeakTestResult> runLeakTests($grpc.ServiceCall call, $0.RunLeakTestsRequest request);
}
