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

// ---------------------------------------------------------------------------
// HAND-WRITTEN from proto/sora/leak/v1/leak.proto (protoc-gen-dart has not
// run yet). Client side only: this app never serves the leak service, so
// the generated ServiceBase is deliberately omitted. The method path and
// message codecs match the proto file 1:1.
// ---------------------------------------------------------------------------

/// LeakService runs the core's egress self-tests and streams one
/// LeakTestResult per test as it completes.
@$pb.GrpcServiceName('sora.leak.v1.LeakService')
class LeakServiceClient extends $grpc.Client {
  LeakServiceClient(super.channel, {super.options, super.interceptors});

  /// HAND-WRITTEN (see above). Streams one result per completed test.
  $grpc.ResponseStream<$0.LeakTestResult> runLeakTests(
    $0.RunLeakTestsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$runLeakTests, $async.Stream.fromIterable([request]), options: options);
  }

  // HAND-WRITTEN (see above).
  static final _$runLeakTests = $grpc.ClientMethod<$0.RunLeakTestsRequest, $0.LeakTestResult>(
      '/sora.leak.v1.LeakService/RunLeakTests',
      ($0.RunLeakTestsRequest value) => value.writeToBuffer(),
      $0.LeakTestResult.fromBuffer);
}
