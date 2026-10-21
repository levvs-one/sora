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

@$core.Deprecated('Use workerClientMessageDescriptor instead')
const WorkerClientMessage$json = {
  '1': 'WorkerClientMessage',
  '2': [
    {'1': 'control_token', '3': 1, '4': 1, '5': 12, '10': 'controlToken'},
    {'1': 'manifest_json', '3': 2, '4': 1, '5': 9, '10': 'manifestJson'},
    {'1': 'source', '3': 3, '4': 1, '5': 9, '10': 'source'},
    {'1': 'config_json', '3': 4, '4': 1, '5': 9, '10': 'configJson'},
    {'1': 'reply_json', '3': 5, '4': 1, '5': 9, '10': 'replyJson'},
  ],
};

/// Descriptor for `WorkerClientMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List workerClientMessageDescriptor =
    $convert.base64Decode('ChNXb3JrZXJDbGllbnRNZXNzYWdlEiMKDWNvbnRyb2xfdG9rZW4YASABKAxSDGNvbnRyb2xUb2'
        'tlbhIjCg1tYW5pZmVzdF9qc29uGAIgASgJUgxtYW5pZmVzdEpzb24SFgoGc291cmNlGAMgASgJ'
        'UgZzb3VyY2USHwoLY29uZmlnX2pzb24YBCABKAlSCmNvbmZpZ0pzb24SHQoKcmVwbHlfanNvbh'
        'gFIAEoCVIJcmVwbHlKc29u');

@$core.Deprecated('Use workerHostMessageDescriptor instead')
const WorkerHostMessage$json = {
  '1': 'WorkerHostMessage',
  '2': [
    {'1': 'call_json', '3': 1, '4': 1, '5': 9, '10': 'callJson'},
    {'1': 'log', '3': 2, '4': 1, '5': 9, '10': 'log'},
    {'1': 'failed', '3': 3, '4': 1, '5': 8, '10': 'failed'},
  ],
};

/// Descriptor for `WorkerHostMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List workerHostMessageDescriptor =
    $convert.base64Decode('ChFXb3JrZXJIb3N0TWVzc2FnZRIbCgljYWxsX2pzb24YASABKAlSCGNhbGxKc29uEhAKA2xvZx'
        'gCIAEoCVIDbG9nEhYKBmZhaWxlZBgDIAEoCFIGZmFpbGVk');
