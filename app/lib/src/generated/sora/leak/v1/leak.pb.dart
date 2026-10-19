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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../core/v1/core_control.pb.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

// ---------------------------------------------------------------------------
// HAND-WRITTEN from proto/sora/leak/v1/leak.proto (protoc-gen-dart has not
// run yet). Follows the generated-code pattern exactly; replace with
// generated output once `protoc-gen-dart` runs against the proto.
//
// The wire contract below is copied verbatim from the proto file; field
// numbers and types must stay in sync with it.
//
//   syntax = "proto3";
//   package sora.leak.v1;
//   import "sora/core/v1/core_control.proto";
//   service LeakService {
//     rpc RunLeakTests(RunLeakTestsRequest) returns (stream LeakTestResult);
//   }
//   message RunLeakTestsRequest {
//     sora.core.v1.ApiVersion api_version = 1;
//     bytes control_authenticator = 2;
//     string session_id = 3;
//     repeated string test_ids = 4;
//   }
//   message LeakTest {
//     string id = 1;
//     string label = 2;
//   }
//   message LeakTestResult {
//     LeakTest test = 1;
//     bool pass = 2;
//     bool skipped = 3;
//     string details = 4;
//     int64 duration_ms = 5;
//   }
// ---------------------------------------------------------------------------

/// Request to run the leak-test suite against the active session. Empty
/// test_ids runs every test.
class RunLeakTestsRequest extends $pb.GeneratedMessage {
  factory RunLeakTestsRequest({
    $0.ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    $core.String? sessionId,
    $core.Iterable<$core.String>? testIds,
  }) {
    final result = RunLeakTestsRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    if (sessionId != null) result.sessionId = sessionId;
    if (testIds != null) result.testIds.addAll(testIds);
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
    ..pPS(4, _omitFieldNames ? '' : 'testIds')
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

  @$pb.TagNumber(4)
  $core.List<$core.String> get testIds => $_getList(3);
}

/// One self-test: a stable machine id and a localization key for its title.
/// The ids are a stable contract with the UI; the UI switches on them,
/// never on free text.
class LeakTest extends $pb.GeneratedMessage {
  factory LeakTest({
    $core.String? id,
    $core.String? label,
  }) {
    final result = LeakTest._();
    if (id != null) result.id = id;
    if (label != null) result.label = label;
    return result;
  }

  LeakTest._();

  factory LeakTest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LeakTest()..mergeFromBuffer(data, registry);
  factory LeakTest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LeakTest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LeakTest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.leak.v1'),
      createEmptyInstance: LeakTest.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'label')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeakTest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LeakTest copyWith(void Function(LeakTest) updates) =>
      super.copyWith((message) => updates(message as LeakTest)) as LeakTest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LeakTest() / LeakTest.new instead')
  static LeakTest create() => LeakTest._();
  static $pb.GeneratedMessage $_createMessage() => LeakTest._();
  @$core.override
  LeakTest createEmptyInstance() => LeakTest._();
  @$core.pragma('dart2js:noInline')
  static LeakTest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LeakTest>(LeakTest.$_createMessage);
  static LeakTest? _defaultInstance;

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
}

/// The verdict of one self-test. Details describe what the probe observed
/// in plain words and never carry secrets. Skipped tests always pass.
class LeakTestResult extends $pb.GeneratedMessage {
  factory LeakTestResult({
    LeakTest? test,
    $core.bool? pass,
    $core.bool? skipped,
    $core.String? details,
    $fixnum.Int64? durationMs,
  }) {
    final result = LeakTestResult._();
    if (test != null) result.test = test;
    if (pass != null) result.pass = pass;
    if (skipped != null) result.skipped = skipped;
    if (details != null) result.details = details;
    if (durationMs != null) result.durationMs = durationMs;
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
    ..aOM<LeakTest>(1, _omitFieldNames ? '' : 'test', subBuilder: LeakTest.$_createMessage)
    ..aOB(2, _omitFieldNames ? '' : 'pass')
    ..aOB(3, _omitFieldNames ? '' : 'skipped')
    ..aOS(4, _omitFieldNames ? '' : 'details')
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'durationMs', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
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
  LeakTest get test => $_getN(0);
  @$pb.TagNumber(1)
  set test(LeakTest value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTest() => $_has(0);
  @$pb.TagNumber(1)
  void clearTest() => $_clearField(1);
  @$pb.TagNumber(1)
  LeakTest ensureTest() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.bool get pass => $_getBF(1);
  @$pb.TagNumber(2)
  set pass($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPass() => $_has(1);
  @$pb.TagNumber(2)
  void clearPass() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get skipped => $_getBF(2);
  @$pb.TagNumber(3)
  set skipped($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSkipped() => $_has(2);
  @$pb.TagNumber(3)
  void clearSkipped() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get details => $_getSZ(3);
  @$pb.TagNumber(4)
  set details($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDetails() => $_has(3);
  @$pb.TagNumber(4)
  void clearDetails() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get durationMs => $_getI64(4);
  @$pb.TagNumber(5)
  set durationMs($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDurationMs() => $_has(4);
  @$pb.TagNumber(5)
  void clearDurationMs() => $_clearField(5);
}

const $core.bool _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
