// This is a generated file - do not edit.
//
// Generated from sora/ext/v1/ext_host.proto.

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

@$core.Deprecated('Use mintTokenRequestDescriptor instead')
const MintTokenRequest$json = {
  '1': 'MintTokenRequest',
  '2': [
    {'1': 'control_token', '3': 1, '4': 1, '5': 12, '10': 'controlToken'},
    {'1': 'extension_id', '3': 2, '4': 1, '5': 9, '10': 'extensionId'},
    {'1': 'permissions', '3': 3, '4': 3, '5': 9, '10': 'permissions'},
  ],
};

/// Descriptor for `MintTokenRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mintTokenRequestDescriptor =
    $convert.base64Decode('ChBNaW50VG9rZW5SZXF1ZXN0EiMKDWNvbnRyb2xfdG9rZW4YASABKAxSDGNvbnRyb2xUb2tlbh'
        'IhCgxleHRlbnNpb25faWQYAiABKAlSC2V4dGVuc2lvbklkEiAKC3Blcm1pc3Npb25zGAMgAygJ'
        'UgtwZXJtaXNzaW9ucw==');

@$core.Deprecated('Use mintTokenResponseDescriptor instead')
const MintTokenResponse$json = {
  '1': 'MintTokenResponse',
  '2': [
    {'1': 'extension_token', '3': 1, '4': 1, '5': 12, '10': 'extensionToken'},
  ],
};

/// Descriptor for `MintTokenResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mintTokenResponseDescriptor =
    $convert.base64Decode('ChFNaW50VG9rZW5SZXNwb25zZRInCg9leHRlbnNpb25fdG9rZW4YASABKAxSDmV4dGVuc2lvbl'
        'Rva2Vu');

@$core.Deprecated('Use revokeTokenRequestDescriptor instead')
const RevokeTokenRequest$json = {
  '1': 'RevokeTokenRequest',
  '2': [
    {'1': 'control_token', '3': 1, '4': 1, '5': 12, '10': 'controlToken'},
    {'1': 'extension_token', '3': 2, '4': 1, '5': 12, '10': 'extensionToken'},
  ],
};

/// Descriptor for `RevokeTokenRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revokeTokenRequestDescriptor =
    $convert.base64Decode('ChJSZXZva2VUb2tlblJlcXVlc3QSIwoNY29udHJvbF90b2tlbhgBIAEoDFIMY29udHJvbFRva2'
        'VuEicKD2V4dGVuc2lvbl90b2tlbhgCIAEoDFIOZXh0ZW5zaW9uVG9rZW4=');

@$core.Deprecated('Use revokeTokenResponseDescriptor instead')
const RevokeTokenResponse$json = {
  '1': 'RevokeTokenResponse',
};

/// Descriptor for `RevokeTokenResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List revokeTokenResponseDescriptor = $convert.base64Decode('ChNSZXZva2VUb2tlblJlc3BvbnNl');

@$core.Deprecated('Use getConnectionsRequestDescriptor instead')
const GetConnectionsRequest$json = {
  '1': 'GetConnectionsRequest',
  '2': [
    {'1': 'extension_token', '3': 1, '4': 1, '5': 12, '10': 'extensionToken'},
  ],
};

/// Descriptor for `GetConnectionsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getConnectionsRequestDescriptor =
    $convert.base64Decode('ChVHZXRDb25uZWN0aW9uc1JlcXVlc3QSJwoPZXh0ZW5zaW9uX3Rva2VuGAEgASgMUg5leHRlbn'
        'Npb25Ub2tlbg==');

@$core.Deprecated('Use extensionConnectionDescriptor instead')
const ExtensionConnection$json = {
  '1': 'ExtensionConnection',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'process', '3': 2, '4': 1, '5': 9, '10': 'process'},
    {'1': 'host', '3': 3, '4': 1, '5': 9, '10': 'host'},
    {'1': 'up_bytes', '3': 4, '4': 1, '5': 4, '10': 'upBytes'},
    {'1': 'down_bytes', '3': 5, '4': 1, '5': 4, '10': 'downBytes'},
  ],
};

/// Descriptor for `ExtensionConnection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List extensionConnectionDescriptor =
    $convert.base64Decode('ChNFeHRlbnNpb25Db25uZWN0aW9uEg4KAmlkGAEgASgJUgJpZBIYCgdwcm9jZXNzGAIgASgJUg'
        'dwcm9jZXNzEhIKBGhvc3QYAyABKAlSBGhvc3QSGQoIdXBfYnl0ZXMYBCABKARSB3VwQnl0ZXMS'
        'HQoKZG93bl9ieXRlcxgFIAEoBFIJZG93bkJ5dGVz');

@$core.Deprecated('Use getConnectionsResponseDescriptor instead')
const GetConnectionsResponse$json = {
  '1': 'GetConnectionsResponse',
  '2': [
    {'1': 'connections', '3': 1, '4': 3, '5': 11, '6': '.sora.ext.v1.ExtensionConnection', '10': 'connections'},
  ],
};

/// Descriptor for `GetConnectionsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getConnectionsResponseDescriptor =
    $convert.base64Decode('ChZHZXRDb25uZWN0aW9uc1Jlc3BvbnNlEkIKC2Nvbm5lY3Rpb25zGAEgAygLMiAuc29yYS5leH'
        'QudjEuRXh0ZW5zaW9uQ29ubmVjdGlvblILY29ubmVjdGlvbnM=');

@$core.Deprecated('Use getServersRequestDescriptor instead')
const GetServersRequest$json = {
  '1': 'GetServersRequest',
  '2': [
    {'1': 'extension_token', '3': 1, '4': 1, '5': 12, '10': 'extensionToken'},
  ],
};

/// Descriptor for `GetServersRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getServersRequestDescriptor =
    $convert.base64Decode('ChFHZXRTZXJ2ZXJzUmVxdWVzdBInCg9leHRlbnNpb25fdG9rZW4YASABKAxSDmV4dGVuc2lvbl'
        'Rva2Vu');

@$core.Deprecated('Use extensionServerDescriptor instead')
const ExtensionServer$json = {
  '1': 'ExtensionServer',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'country', '3': 3, '4': 1, '5': 9, '10': 'country'},
    {'1': 'latency_ms', '3': 4, '4': 1, '5': 3, '10': 'latencyMs'},
  ],
};

/// Descriptor for `ExtensionServer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List extensionServerDescriptor =
    $convert.base64Decode('Cg9FeHRlbnNpb25TZXJ2ZXISDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSGA'
        'oHY291bnRyeRgDIAEoCVIHY291bnRyeRIdCgpsYXRlbmN5X21zGAQgASgDUglsYXRlbmN5TXM=');

@$core.Deprecated('Use getServersResponseDescriptor instead')
const GetServersResponse$json = {
  '1': 'GetServersResponse',
  '2': [
    {'1': 'servers', '3': 1, '4': 3, '5': 11, '6': '.sora.ext.v1.ExtensionServer', '10': 'servers'},
  ],
};

/// Descriptor for `GetServersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getServersResponseDescriptor =
    $convert.base64Decode('ChJHZXRTZXJ2ZXJzUmVzcG9uc2USNgoHc2VydmVycxgBIAMoCzIcLnNvcmEuZXh0LnYxLkV4dG'
        'Vuc2lvblNlcnZlclIHc2VydmVycw==');

@$core.Deprecated('Use notifyRequestDescriptor instead')
const NotifyRequest$json = {
  '1': 'NotifyRequest',
  '2': [
    {'1': 'extension_token', '3': 1, '4': 1, '5': 12, '10': 'extensionToken'},
    {'1': 'title', '3': 2, '4': 1, '5': 9, '10': 'title'},
    {'1': 'body', '3': 3, '4': 1, '5': 9, '10': 'body'},
  ],
};

/// Descriptor for `NotifyRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List notifyRequestDescriptor =
    $convert.base64Decode('Cg1Ob3RpZnlSZXF1ZXN0EicKD2V4dGVuc2lvbl90b2tlbhgBIAEoDFIOZXh0ZW5zaW9uVG9rZW'
        '4SFAoFdGl0bGUYAiABKAlSBXRpdGxlEhIKBGJvZHkYAyABKAlSBGJvZHk=');

@$core.Deprecated('Use notifyResponseDescriptor instead')
const NotifyResponse$json = {
  '1': 'NotifyResponse',
};

/// Descriptor for `NotifyResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List notifyResponseDescriptor = $convert.base64Decode('Cg5Ob3RpZnlSZXNwb25zZQ==');

@$core.Deprecated('Use watchExtensionEventsRequestDescriptor instead')
const WatchExtensionEventsRequest$json = {
  '1': 'WatchExtensionEventsRequest',
  '2': [
    {'1': 'extension_token', '3': 1, '4': 1, '5': 12, '10': 'extensionToken'},
  ],
};

/// Descriptor for `WatchExtensionEventsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchExtensionEventsRequestDescriptor =
    $convert.base64Decode('ChtXYXRjaEV4dGVuc2lvbkV2ZW50c1JlcXVlc3QSJwoPZXh0ZW5zaW9uX3Rva2VuGAEgASgMUg'
        '5leHRlbnNpb25Ub2tlbg==');

@$core.Deprecated('Use extensionEventDescriptor instead')
const ExtensionEvent$json = {
  '1': 'ExtensionEvent',
  '2': [
    {'1': 'kind', '3': 1, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'detail', '3': 2, '4': 1, '5': 9, '10': 'detail'},
    {'1': 'at', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'at'},
  ],
};

/// Descriptor for `ExtensionEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List extensionEventDescriptor =
    $convert.base64Decode('Cg5FeHRlbnNpb25FdmVudBISCgRraW5kGAEgASgJUgRraW5kEhYKBmRldGFpbBgCIAEoCVIGZG'
        'V0YWlsEioKAmF0GAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVzdGFtcFICYXQ=');
