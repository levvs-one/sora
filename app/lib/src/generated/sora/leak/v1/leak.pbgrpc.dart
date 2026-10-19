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
// HAND-WRITTEN per the assumed proto/sora/leak/v1/leak.proto contract
// documented in leak.pb.dart (pending Go protoc codegen). Client side only:
// this app never serves the leak service, so the generated ServiceBase is
// deliberately omitted. RECONCILE BEFORE MERGE together with leak.pb.dart.
// ---------------------------------------------------------------------------

/// LeakService runs the network leak-test suite against the active session
/// and streams one event per completed test.
@$pb.GrpcServiceName('sora.leak.v1.LeakService')
class LeakServiceClient extends $grpc.Client {
  LeakServiceClient(super.channel, {super.options, super.interceptors});

  /// HAND-WRITTEN (see above). Streams test events: started, then one
  /// result per test, then finished.
  $grpc.ResponseStream<$0.LeakTestEvent> runLeakTests(
    $0.RunLeakTestsRequest request, {
    $grpc.CallOptions? options,
  }) {
    return $createStreamingCall(_$runLeakTests, $async.Stream.fromIterable([request]), options: options);
  }

  // HAND-WRITTEN (see above).
  static final _$runLeakTests = $grpc.ClientMethod<$0.RunLeakTestsRequest, $0.LeakTestEvent>(
      '/sora.leak.v1.LeakService/RunLeakTests',
      ($0.RunLeakTestsRequest value) => value.writeToBuffer(),
      $0.LeakTestEvent.fromBuffer);
}
