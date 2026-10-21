// This is a generated file - do not edit.
//
// Generated from sora/leak/v1/leak.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use runLeakTestsRequestDescriptor instead')
const RunLeakTestsRequest$json = {
  '1': 'RunLeakTestsRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'test_ids', '3': 4, '4': 3, '5': 9, '10': 'testIds'},
  ],
};

/// Descriptor for `RunLeakTestsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List runLeakTestsRequestDescriptor =
    $convert.base64Decode('ChNSdW5MZWFrVGVzdHNSZXF1ZXN0EjkKC2FwaV92ZXJzaW9uGAEgASgLMhguc29yYS5jb3JlLn'
        'YxLkFwaVZlcnNpb25SCmFwaVZlcnNpb24SMwoVY29udHJvbF9hdXRoZW50aWNhdG9yGAIgASgM'
        'UhRjb250cm9sQXV0aGVudGljYXRvchIdCgpzZXNzaW9uX2lkGAMgASgJUglzZXNzaW9uSWQSGQ'
        'oIdGVzdF9pZHMYBCADKAlSB3Rlc3RJZHM=');

@$core.Deprecated('Use leakTestDescriptor instead')
const LeakTest$json = {
  '1': 'LeakTest',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
  ],
};

/// Descriptor for `LeakTest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List leakTestDescriptor =
    $convert.base64Decode('CghMZWFrVGVzdBIOCgJpZBgBIAEoCVICaWQSFAoFbGFiZWwYAiABKAlSBWxhYmVs');

@$core.Deprecated('Use leakTestResultDescriptor instead')
const LeakTestResult$json = {
  '1': 'LeakTestResult',
  '2': [
    {'1': 'test', '3': 1, '4': 1, '5': 11, '6': '.sora.leak.v1.LeakTest', '10': 'test'},
    {'1': 'pass', '3': 2, '4': 1, '5': 8, '10': 'pass'},
    {'1': 'skipped', '3': 3, '4': 1, '5': 8, '10': 'skipped'},
    {'1': 'details', '3': 4, '4': 1, '5': 9, '10': 'details'},
    {'1': 'duration_ms', '3': 5, '4': 1, '5': 3, '10': 'durationMs'},
  ],
};

/// Descriptor for `LeakTestResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List leakTestResultDescriptor =
    $convert.base64Decode('Cg5MZWFrVGVzdFJlc3VsdBIqCgR0ZXN0GAEgASgLMhYuc29yYS5sZWFrLnYxLkxlYWtUZXN0Ug'
        'R0ZXN0EhIKBHBhc3MYAiABKAhSBHBhc3MSGAoHc2tpcHBlZBgDIAEoCFIHc2tpcHBlZBIYCgdk'
        'ZXRhaWxzGAQgASgJUgdkZXRhaWxzEh8KC2R1cmF0aW9uX21zGAUgASgDUgpkdXJhdGlvbk1z');
