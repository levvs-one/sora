// This is a generated file - do not edit.
//
// Generated from sora/leak/v1/leak.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import '../../core/v1/core_control.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

// ---------------------------------------------------------------------------
// HAND-WRITTEN per the assumed proto/sora/leak/v1/leak.proto contract below
// (the Go agent authors the proto in parallel; protoc-gen-dart has not run
// yet). Follows the generated-code pattern exactly; replace with generated
// output once `protoc-gen-dart` runs against the real proto.
//
// RECONCILE BEFORE MERGE: the wire contract (package, service and method
// names, field numbers and types) must match the Go proto 1:1, otherwise the
// stream silently mis-decodes.
//
// Assumed proto:
//   syntax = "proto3";
//   package sora.leak.v1;
//   import "sora/core/v1/core_control.proto";
//   service LeakService {
//     rpc RunLeakTests(RunLeakTestsRequest) returns (stream LeakTestEvent);
//   }
//   message RunLeakTestsRequest {
//     sora.core.v1.ApiVersion api_version = 1;
//     bytes control_authenticator = 2;
//     string session_id = 3;
//   }
//   message LeakTestStarted { uint32 total = 1; }
//   message LeakTestResult {
//     string id = 1;       // stable machine id, e.g. "tunnel-dns"
//     string label = 2;    // localization key for the title
//     string expected = 3; // what the core expects
//     string actual = 4;   // what was observed
//     bool passed = 5;     // false = leak found
//     string fix_hint = 6; // localization key for the suggested fix, "" = none
//   }
//   message LeakTestFinished {
//     bool all_passed = 1;
//     sora.core.v1.SoraError error = 2;
//   }
//   message LeakTestEvent {
//     oneof payload {
//       LeakTestStarted started = 1;
//       LeakTestResult result = 2;
//       LeakTestFinished finished = 3;
//     }
//   }
// ---------------------------------------------------------------------------

/// Request to run the full leak-test suite against the active session.
class RunLeakTestsRequest extends $pb.GeneratedMessage {
  factory RunLeakTestsRequest({
    $0.ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    $core.String? sessionId,
  }) {
    final result = RunLeakTestsRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  RunLeakTestsRequest._();

  factory RunLeakTestsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RunLeakTestsRequest()..mergeFromBuffer(data, registry);
  factory RunLeakTestsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RunLeakTestsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RunLeakTestsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.leak.v1'),
      createEmptyInstance: RunLeakTestsRequest.$_createMessage)
    ..aOM<$0.ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: $0.ApiVersion.$_createMessage)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunLeakTestsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunLeakTestsRequest copyWith(void Function(RunLeakTestsRequest) updates) =>
      super.copyWith((message) => updates(message as RunLeakTestsRequest)) as RunLeakTestsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RunLeakTestsRequest() / RunLeakTestsRequest.new instead')
  static RunLeakTestsRequest create() => RunLeakTestsRequest._();
  static $pb.GeneratedMessage $_createMessage() => RunLeakTestsRequest._();
  @$core.override
  RunLeakTestsRequest createEmptyInstance() => RunLeakTestsRequest._();
  @$core.pragma('dart2js:noInline')
  static RunLeakTestsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RunLeakTestsRequest>(RunLeakTestsRequest.$_createMessage);
  static RunLeakTestsRequest? _defaultInstance;

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
  $core.String get sessionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sessionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => $_clearField(3);
}

/// First event of a run: how many tests to expect.
class LeakTestStarted extends $pb.GeneratedMessage {
  factory LeakTestStarted({
    $core.int? total,
  }) {
    final result = LeakTestStarted._();
    if (total != null) result.total = total;
    return result;
  }

  LeakTestStarted._();

  factory LeakTestStarted.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LeakTestStarted()..mergeFromBuffer(data, registry);
  factory LeakTestStarted.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LeakTestStarted()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LeakTestStarted',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.leak.v1'),
      createEmptyInstance: LeakTestStarted.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'total', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeakTestStarted clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeakTestStarted copyWith(void Function(LeakTestStarted) updates) =>
      super.copyWith((message) => updates(message as LeakTestStarted)) as LeakTestStarted;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LeakTestStarted() / LeakTestStarted.new instead')
  static LeakTestStarted create() => LeakTestStarted._();
  static $pb.GeneratedMessage $_createMessage() => LeakTestStarted._();
  @$core.override
  LeakTestStarted createEmptyInstance() => LeakTestStarted._();
  @$core.pragma('dart2js:noInline')
  static LeakTestStarted getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LeakTestStarted>(LeakTestStarted.$_createMessage);
  static LeakTestStarted? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get total => $_getIZ(0);
  @$pb.TagNumber(1)
  set total($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTotal() => $_has(0);
  @$pb.TagNumber(1)
  void clearTotal() => $_clearField(1);
}

/// One completed test. Label and fixHint are localization keys for the UI,
/// never free text; expected and actual carry raw values.
class LeakTestResult extends $pb.GeneratedMessage {
  factory LeakTestResult({
    $core.String? id,
    $core.String? label,
    $core.String? expected,
    $core.String? actual,
    $core.bool? passed,
    $core.String? fixHint,
  }) {
    final result = LeakTestResult._();
    if (id != null) result.id = id;
    if (label != null) result.label = label;
    if (expected != null) result.expected = expected;
    if (actual != null) result.actual = actual;
    if (passed != null) result.passed = passed;
    if (fixHint != null) result.fixHint = fixHint;
    return result;
  }

  LeakTestResult._();

  factory LeakTestResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LeakTestResult()..mergeFromBuffer(data, registry);
  factory LeakTestResult.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LeakTestResult()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LeakTestResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.leak.v1'),
      createEmptyInstance: LeakTestResult.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..aOS(3, _omitFieldNames ? '' : 'expected')
    ..aOS(4, _omitFieldNames ? '' : 'actual')
    ..aOB(5, _omitFieldNames ? '' : 'passed')
    ..aOS(6, _omitFieldNames ? '' : 'fixHint')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeakTestResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeakTestResult copyWith(void Function(LeakTestResult) updates) =>
      super.copyWith((message) => updates(message as LeakTestResult)) as LeakTestResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LeakTestResult() / LeakTestResult.new instead')
  static LeakTestResult create() => LeakTestResult._();
  static $pb.GeneratedMessage $_createMessage() => LeakTestResult._();
  @$core.override
  LeakTestResult createEmptyInstance() => LeakTestResult._();
  @$core.pragma('dart2js:noInline')
  static LeakTestResult getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LeakTestResult>(LeakTestResult.$_createMessage);
  static LeakTestResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get label => $_getSZ(1);
  @$pb.TagNumber(2)
  set label($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLabel() => $_has(1);
  @$pb.TagNumber(2)
  void clearLabel() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get expected => $_getSZ(2);
  @$pb.TagNumber(3)
  set expected($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasExpected() => $_has(2);
  @$pb.TagNumber(3)
  void clearExpected() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get actual => $_getSZ(3);
  @$pb.TagNumber(4)
  set actual($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasActual() => $_has(3);
  @$pb.TagNumber(4)
  void clearActual() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get passed => $_getBF(4);
  @$pb.TagNumber(5)
  set passed($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPassed() => $_has(4);
  @$pb.TagNumber(5)
  void clearPassed() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get fixHint => $_getSZ(5);
  @$pb.TagNumber(6)
  set fixHint($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasFixHint() => $_has(5);
  @$pb.TagNumber(6)
  void clearFixHint() => $_clearField(6);
}

/// Terminal event of a run. Carries a core error instead of results when the
/// suite itself failed.
class LeakTestFinished extends $pb.GeneratedMessage {
  factory LeakTestFinished({
    $core.bool? allPassed,
    $0.SoraError? error,
  }) {
    final result = LeakTestFinished._();
    if (allPassed != null) result.allPassed = allPassed;
    if (error != null) result.error = error;
    return result;
  }

  LeakTestFinished._();

  factory LeakTestFinished.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LeakTestFinished()..mergeFromBuffer(data, registry);
  factory LeakTestFinished.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LeakTestFinished()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LeakTestFinished',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.leak.v1'),
      createEmptyInstance: LeakTestFinished.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'allPassed')
    ..aOM<$0.SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: $0.SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeakTestFinished clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeakTestFinished copyWith(void Function(LeakTestFinished) updates) =>
      super.copyWith((message) => updates(message as LeakTestFinished)) as LeakTestFinished;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LeakTestFinished() / LeakTestFinished.new instead')
  static LeakTestFinished create() => LeakTestFinished._();
  static $pb.GeneratedMessage $_createMessage() => LeakTestFinished._();
  @$core.override
  LeakTestFinished createEmptyInstance() => LeakTestFinished._();
  @$core.pragma('dart2js:noInline')
  static LeakTestFinished getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LeakTestFinished>(LeakTestFinished.$_createMessage);
  static LeakTestFinished? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get allPassed => $_getBF(0);
  @$pb.TagNumber(1)
  set allPassed($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAllPassed() => $_has(0);
  @$pb.TagNumber(1)
  void clearAllPassed() => $_clearField(1);

  @$pb.TagNumber(2)
  $0.SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($0.SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  $0.SoraError ensureError() => $_ensure(1);
}

enum LeakTestEvent_Payload { started, result, finished, notSet }

/// One streamed event of a leak-test run: the start marker, one completed
/// test, or the terminal marker.
class LeakTestEvent extends $pb.GeneratedMessage {
  factory LeakTestEvent({
    LeakTestStarted? started,
    LeakTestResult? result,
    LeakTestFinished? finished,
  }) {
    final $result = LeakTestEvent._();
    if (started != null) $result.started = started;
    if (result != null) $result.result = result;
    if (finished != null) $result.finished = finished;
    return $result;
  }

  LeakTestEvent._();

  factory LeakTestEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LeakTestEvent()..mergeFromBuffer(data, registry);
  factory LeakTestEvent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LeakTestEvent()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, LeakTestEvent_Payload> _LeakTestEvent_PayloadByTag = {
    1: LeakTestEvent_Payload.started,
    2: LeakTestEvent_Payload.result,
    3: LeakTestEvent_Payload.finished,
    0: LeakTestEvent_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LeakTestEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.leak.v1'),
      createEmptyInstance: LeakTestEvent.$_createMessage)
    ..oo(0, [1, 2, 3])
    ..aOM<LeakTestStarted>(1, _omitFieldNames ? '' : 'started', subBuilder: LeakTestStarted.$_createMessage)
    ..aOM<LeakTestResult>(2, _omitFieldNames ? '' : 'result', subBuilder: LeakTestResult.$_createMessage)
    ..aOM<LeakTestFinished>(3, _omitFieldNames ? '' : 'finished', subBuilder: LeakTestFinished.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeakTestEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeakTestEvent copyWith(void Function(LeakTestEvent) updates) =>
      super.copyWith((message) => updates(message as LeakTestEvent)) as LeakTestEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LeakTestEvent() / LeakTestEvent.new instead')
  static LeakTestEvent create() => LeakTestEvent._();
  static $pb.GeneratedMessage $_createMessage() => LeakTestEvent._();
  @$core.override
  LeakTestEvent createEmptyInstance() => LeakTestEvent._();
  @$core.pragma('dart2js:noInline')
  static LeakTestEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LeakTestEvent>(LeakTestEvent.$_createMessage);
  static LeakTestEvent? _defaultInstance;

  LeakTestEvent_Payload whichPayload() => _LeakTestEvent_PayloadByTag[$_whichOneof(0)]!;
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  LeakTestStarted get started => $_getN(0);
  @$pb.TagNumber(1)
  set started(LeakTestStarted value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStarted() => $_has(0);
  @$pb.TagNumber(1)
  void clearStarted() => $_clearField(1);
  @$pb.TagNumber(1)
  LeakTestStarted ensureStarted() => $_ensure(0);

  @$pb.TagNumber(2)
  LeakTestResult get result => $_getN(1);
  @$pb.TagNumber(2)
  set result(LeakTestResult value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasResult() => $_has(1);
  @$pb.TagNumber(2)
  void clearResult() => $_clearField(2);
  @$pb.TagNumber(2)
  LeakTestResult ensureResult() => $_ensure(1);

  @$pb.TagNumber(3)
  LeakTestFinished get finished => $_getN(2);
  @$pb.TagNumber(3)
  set finished(LeakTestFinished value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasFinished() => $_has(2);
  @$pb.TagNumber(3)
  void clearFinished() => $_clearField(3);
  @$pb.TagNumber(3)
  LeakTestFinished ensureFinished() => $_ensure(2);
}

const $core.bool _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
