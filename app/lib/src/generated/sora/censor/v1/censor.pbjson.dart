// This is a generated file - do not edit.
//
// Generated from sora/censor/v1/censor.proto.

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

@$core.Deprecated('Use censorshipKindDescriptor instead')
const CensorshipKind$json = {
  '1': 'CensorshipKind',
  '2': [
    {'1': 'CENSORSHIP_KIND_UNSPECIFIED', '2': 0},
  ],
  '4': [
    {'1': 1, '2': 1},
    {'1': 2, '2': 2},
    {'1': 3, '2': 3},
    {'1': 4, '2': 4},
    {'1': 5, '2': 5},
    {'1': 6, '2': 6},
    {'1': 7, '2': 7},
    {'1': 8, '2': 8},
  ],
  '5': [
    'CENSORSHIP_KIND_UNKNOWN',
    'CENSORSHIP_KIND_NO_INTERFERENCE',
    'CENSORSHIP_KIND_RST_INJECTION',
    'CENSORSHIP_KIND_HANDSHAKE_TIMEOUT',
    'CENSORSHIP_KIND_DNS_POISONING',
    'CENSORSHIP_KIND_SNI_BLOCKING',
    'CENSORSHIP_KIND_IP_BLOCKING',
    'CENSORSHIP_KIND_DATA_STALL'
  ],
};

/// Descriptor for `CensorshipKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List censorshipKindDescriptor =
    $convert.base64Decode('Cg5DZW5zb3JzaGlwS2luZBIfChtDRU5TT1JTSElQX0tJTkRfVU5TUEVDSUZJRUQQACIECAEQAS'
        'IECAIQAiIECAMQAyIECAQQBCIECAUQBSIECAYQBiIECAcQByIECAgQCCoXQ0VOU09SU0hJUF9L'
        'SU5EX1VOS05PV04qH0NFTlNPUlNISVBfS0lORF9OT19JTlRFUkZFUkVOQ0UqHUNFTlNPUlNISV'
        'BfS0lORF9SU1RfSU5KRUNUSU9OKiFDRU5TT1JTSElQX0tJTkRfSEFORFNIQUtFX1RJTUVPVVQq'
        'HUNFTlNPUlNISVBfS0lORF9ETlNfUE9JU09OSU5HKhxDRU5TT1JTSElQX0tJTkRfU05JX0JMT0'
        'NLSU5HKhtDRU5TT1JTSElQX0tJTkRfSVBfQkxPQ0tJTkcqGkNFTlNPUlNISVBfS0lORF9EQVRB'
        'X1NUQUxM');

@$core.Deprecated('Use attemptStageDescriptor instead')
const AttemptStage$json = {
  '1': 'AttemptStage',
  '2': [
    {'1': 'ATTEMPT_STAGE_UNSPECIFIED', '2': 0},
  ],
  '4': [
    {'1': 1, '2': 1},
    {'1': 2, '2': 2},
    {'1': 3, '2': 3},
    {'1': 4, '2': 4},
    {'1': 5, '2': 5},
  ],
  '5': ['ATTEMPT_STAGE_DNS', 'ATTEMPT_STAGE_TCP', 'ATTEMPT_STAGE_TLS', 'ATTEMPT_STAGE_APP', 'ATTEMPT_STAGE_DATA'],
};

/// Descriptor for `AttemptStage`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List attemptStageDescriptor =
    $convert.base64Decode('CgxBdHRlbXB0U3RhZ2USHQoZQVRURU1QVF9TVEFHRV9VTlNQRUNJRklFRBAAIgQIARABIgQIAh'
        'ACIgQIAxADIgQIBBAEIgQIBRAFKhFBVFRFTVBUX1NUQUdFX0ROUyoRQVRURU1QVF9TVEFHRV9U'
        'Q1AqEUFUVEVNUFRfU1RBR0VfVExTKhFBVFRFTVBUX1NUQUdFX0FQUCoSQVRURU1QVF9TVEFHRV'
        '9EQVRB');

@$core.Deprecated('Use attemptEventKindDescriptor instead')
const AttemptEventKind$json = {
  '1': 'AttemptEventKind',
  '2': [
    {'1': 'ATTEMPT_EVENT_KIND_UNSPECIFIED', '2': 0},
  ],
  '4': [
    {'1': 1, '2': 1},
    {'1': 2, '2': 2},
    {'1': 3, '2': 3},
    {'1': 4, '2': 4},
    {'1': 5, '2': 5},
    {'1': 6, '2': 6},
    {'1': 7, '2': 7},
    {'1': 8, '2': 8},
    {'1': 9, '2': 9},
  ],
  '5': [
    'ATTEMPT_EVENT_KIND_RESOLVED',
    'ATTEMPT_EVENT_KIND_CONNECTED',
    'ATTEMPT_EVENT_KIND_SENT',
    'ATTEMPT_EVENT_KIND_RECEIVED',
    'ATTEMPT_EVENT_KIND_REMOTE_RESET',
    'ATTEMPT_EVENT_KIND_REMOTE_CLOSE',
    'ATTEMPT_EVENT_KIND_LOCAL_TIMEOUT',
    'ATTEMPT_EVENT_KIND_TLS_ALERT',
    'ATTEMPT_EVENT_KIND_ERROR'
  ],
};

/// Descriptor for `AttemptEventKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List attemptEventKindDescriptor =
    $convert.base64Decode('ChBBdHRlbXB0RXZlbnRLaW5kEiIKHkFUVEVNUFRfRVZFTlRfS0lORF9VTlNQRUNJRklFRBAAIg'
        'QIARABIgQIAhACIgQIAxADIgQIBBAEIgQIBRAFIgQIBhAGIgQIBxAHIgQICBAIIgQICRAJKhtB'
        'VFRFTVBUX0VWRU5UX0tJTkRfUkVTT0xWRUQqHEFUVEVNUFRfRVZFTlRfS0lORF9DT05ORUNURU'
        'QqF0FUVEVNUFRfRVZFTlRfS0lORF9TRU5UKhtBVFRFTVBUX0VWRU5UX0tJTkRfUkVDRUlWRUQq'
        'H0FUVEVNUFRfRVZFTlRfS0lORF9SRU1PVEVfUkVTRVQqH0FUVEVNUFRfRVZFTlRfS0lORF9SRU'
        '1PVEVfQ0xPU0UqIEFUVEVNUFRfRVZFTlRfS0lORF9MT0NBTF9USU1FT1VUKhxBVFRFTVBUX0VW'
        'RU5UX0tJTkRfVExTX0FMRVJUKhhBVFRFTVBUX0VWRU5UX0tJTkRfRVJST1I=');

@$core.Deprecated('Use attemptEventDescriptor instead')
const AttemptEvent$json = {
  '1': 'AttemptEvent',
  '9': [
    {'1': 1, '2': 2},
    {'1': 2, '2': 3},
    {'1': 3, '2': 4},
    {'1': 4, '2': 5},
  ],
  '10': ['stage', 'kind', 'offset_ms', 'detail'],
};

/// Descriptor for `AttemptEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List attemptEventDescriptor =
    $convert.base64Decode('CgxBdHRlbXB0RXZlbnRKBAgBEAJKBAgCEANKBAgDEARKBAgEEAVSBXN0YWdlUgRraW5kUglvZm'
        'ZzZXRfbXNSBmRldGFpbA==');

@$core.Deprecated('Use obfuscationProfileRefDescriptor instead')
const ObfuscationProfileRef$json = {
  '1': 'ObfuscationProfileRef',
  '9': [
    {'1': 1, '2': 2},
    {'1': 2, '2': 3},
    {'1': 3, '2': 4},
  ],
  '10': ['preset', 'display_name', 'why'],
};

/// Descriptor for `ObfuscationProfileRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List obfuscationProfileRefDescriptor =
    $convert.base64Decode('ChVPYmZ1c2NhdGlvblByb2ZpbGVSZWZKBAgBEAJKBAgCEANKBAgDEARSBnByZXNldFIMZGlzcG'
        'xheV9uYW1lUgN3aHk=');

@$core.Deprecated('Use censorshipVerdictDescriptor instead')
const CensorshipVerdict$json = {
  '1': 'CensorshipVerdict',
  '9': [
    {'1': 1, '2': 2},
    {'1': 2, '2': 3},
    {'1': 3, '2': 4},
    {'1': 4, '2': 5},
    {'1': 5, '2': 6},
  ],
  '10': ['kind', 'confidence', 'suggested_profile', 'explanation', 'evidence'],
};

/// Descriptor for `CensorshipVerdict`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List censorshipVerdictDescriptor =
    $convert.base64Decode('ChFDZW5zb3JzaGlwVmVyZGljdEoECAEQAkoECAIQA0oECAMQBEoECAQQBUoECAUQBlIEa2luZF'
        'IKY29uZmlkZW5jZVIRc3VnZ2VzdGVkX3Byb2ZpbGVSC2V4cGxhbmF0aW9uUghldmlkZW5jZQ==');

@$core.Deprecated('Use detectCensorshipRequestDescriptor instead')
const DetectCensorshipRequest$json = {
  '1': 'DetectCensorshipRequest',
  '9': [
    {'1': 1, '2': 2},
    {'1': 2, '2': 3},
    {'1': 3, '2': 4},
    {'1': 4, '2': 5},
    {'1': 5, '2': 6},
    {'1': 6, '2': 7},
    {'1': 7, '2': 8},
    {'1': 8, '2': 9},
    {'1': 9, '2': 10},
    {'1': 10, '2': 11},
    {'1': 11, '2': 12},
    {'1': 12, '2': 13},
  ],
  '10': [
    'api_version',
    'control_authenticator',
    'request_id',
    'session_id',
    'server_id',
    'target_host',
    'target_port',
    'sni',
    'protocol',
    'known_good_host',
    'events',
    'run_active_probe'
  ],
};

/// Descriptor for `DetectCensorshipRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List detectCensorshipRequestDescriptor =
    $convert.base64Decode('ChdEZXRlY3RDZW5zb3JzaGlwUmVxdWVzdEoECAEQAkoECAIQA0oECAMQBEoECAQQBUoECAUQBk'
        'oECAYQB0oECAcQCEoECAgQCUoECAkQCkoECAoQC0oECAsQDEoECAwQDVILYXBpX3ZlcnNpb25S'
        'FWNvbnRyb2xfYXV0aGVudGljYXRvclIKcmVxdWVzdF9pZFIKc2Vzc2lvbl9pZFIJc2VydmVyX2'
        'lkUgt0YXJnZXRfaG9zdFILdGFyZ2V0X3BvcnRSA3NuaVIIcHJvdG9jb2xSD2tub3duX2dvb2Rf'
        'aG9zdFIGZXZlbnRzUhBydW5fYWN0aXZlX3Byb2Jl');

@$core.Deprecated('Use detectCensorshipResponseDescriptor instead')
const DetectCensorshipResponse$json = {
  '1': 'DetectCensorshipResponse',
  '9': [
    {'1': 1, '2': 2},
    {'1': 2, '2': 3},
    {'1': 3, '2': 4},
  ],
  '10': ['verdict', 'probe_ran', 'error'],
};

/// Descriptor for `DetectCensorshipResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List detectCensorshipResponseDescriptor =
    $convert.base64Decode('ChhEZXRlY3RDZW5zb3JzaGlwUmVzcG9uc2VKBAgBEAJKBAgCEANKBAgDEARSB3ZlcmRpY3RSCX'
        'Byb2JlX3JhblIFZXJyb3I=');
