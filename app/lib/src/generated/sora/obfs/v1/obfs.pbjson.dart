// This is a generated file - do not edit.
//
// Generated from sora/obfs/v1/obfs.proto.

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

@$core.Deprecated('Use utlsProfileDescriptor instead')
const UtlsProfile$json = {
  '1': 'UtlsProfile',
  '2': [
    {'1': 'UTLS_PROFILE_UNSPECIFIED', '2': 0},
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
    {'1': 10, '2': 10},
  ],
  '5': [
    'UTLS_PROFILE_CHROME',
    'UTLS_PROFILE_FIREFOX',
    'UTLS_PROFILE_SAFARI',
    'UTLS_PROFILE_IOS',
    'UTLS_PROFILE_ANDROID',
    'UTLS_PROFILE_EDGE',
    'UTLS_PROFILE_360',
    'UTLS_PROFILE_QQ',
    'UTLS_PROFILE_RANDOM',
    'UTLS_PROFILE_RANDOMIZED'
  ],
};

/// Descriptor for `UtlsProfile`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List utlsProfileDescriptor =
    $convert.base64Decode('CgtVdGxzUHJvZmlsZRIcChhVVExTX1BST0ZJTEVfVU5TUEVDSUZJRUQQACIECAEQASIECAIQAi'
        'IECAMQAyIECAQQBCIECAUQBSIECAYQBiIECAcQByIECAgQCCIECAkQCSIECAoQCioTVVRMU19Q'
        'Uk9GSUxFX0NIUk9NRSoUVVRMU19QUk9GSUxFX0ZJUkVGT1gqE1VUTFNfUFJPRklMRV9TQUZBUk'
        'kqEFVUTFNfUFJPRklMRV9JT1MqFFVUTFNfUFJPRklMRV9BTkRST0lEKhFVVExTX1BST0ZJTEVf'
        'RURHRSoQVVRMU19QUk9GSUxFXzM2MCoPVVRMU19QUk9GSUxFX1FRKhNVVExTX1BST0ZJTEVfUk'
        'FORE9NKhdVVExTX1BST0ZJTEVfUkFORE9NSVpFRA==');

@$core.Deprecated('Use obfsPresetDescriptor instead')
const ObfsPreset$json = {
  '1': 'ObfsPreset',
  '2': [
    {'1': 'OBFS_PRESET_UNSPECIFIED', '2': 0},
  ],
  '4': [
    {'1': 1, '2': 1},
    {'1': 2, '2': 2},
    {'1': 3, '2': 3},
    {'1': 4, '2': 4},
  ],
  '5': ['OBFS_PRESET_OFF', 'OBFS_PRESET_LIGHT', 'OBFS_PRESET_BALANCED', 'OBFS_PRESET_AGGRESSIVE'],
};

/// Descriptor for `ObfsPreset`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List obfsPresetDescriptor =
    $convert.base64Decode('CgpPYmZzUHJlc2V0EhsKF09CRlNfUFJFU0VUX1VOU1BFQ0lGSUVEEAAiBAgBEAEiBAgCEAIiBA'
        'gDEAMiBAgEEAQqD09CRlNfUFJFU0VUX09GRioRT0JGU19QUkVTRVRfTElHSFQqFE9CRlNfUFJF'
        'U0VUX0JBTEFOQ0VEKhZPQkZTX1BSRVNFVF9BR0dSRVNTSVZF');

@$core.Deprecated('Use obfuscationProfileDescriptor instead')
const ObfuscationProfile$json = {
  '1': 'ObfuscationProfile',
  '9': [
    {'1': 1, '2': 2},
    {'1': 2, '2': 3},
    {'1': 3, '2': 4},
    {'1': 4, '2': 5},
    {'1': 5, '2': 6},
    {'1': 6, '2': 7},
  ],
  '10': ['preset', 'utls_profile', 'frag_sizes', 'frag_delay_ms', 'jitter_ms', 'fake_sni'],
};

/// Descriptor for `ObfuscationProfile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List obfuscationProfileDescriptor =
    $convert.base64Decode('ChJPYmZ1c2NhdGlvblByb2ZpbGVKBAgBEAJKBAgCEANKBAgDEARKBAgEEAVKBAgFEAZKBAgGEA'
        'dSBnByZXNldFIMdXRsc19wcm9maWxlUgpmcmFnX3NpemVzUg1mcmFnX2RlbGF5X21zUglqaXR0'
        'ZXJfbXNSCGZha2Vfc25p');

@$core.Deprecated('Use applyObfsProfileRequestDescriptor instead')
const ApplyObfsProfileRequest$json = {
  '1': 'ApplyObfsProfileRequest',
  '9': [
    {'1': 1, '2': 2},
    {'1': 2, '2': 3},
  ],
  '10': ['api_version', 'profile'],
};

/// Descriptor for `ApplyObfsProfileRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applyObfsProfileRequestDescriptor =
    $convert.base64Decode('ChdBcHBseU9iZnNQcm9maWxlUmVxdWVzdEoECAEQAkoECAIQA1ILYXBpX3ZlcnNpb25SB3Byb2'
        'ZpbGU=');

@$core.Deprecated('Use applyObfsProfileResponseDescriptor instead')
const ApplyObfsProfileResponse$json = {
  '1': 'ApplyObfsProfileResponse',
  '9': [
    {'1': 1, '2': 2},
    {'1': 2, '2': 3},
    {'1': 3, '2': 4},
    {'1': 4, '2': 5},
  ],
  '10': ['applied', 'compatible_engines', 'warnings', 'error'],
};

/// Descriptor for `ApplyObfsProfileResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applyObfsProfileResponseDescriptor =
    $convert.base64Decode('ChhBcHBseU9iZnNQcm9maWxlUmVzcG9uc2VKBAgBEAJKBAgCEANKBAgDEARKBAgEEAVSB2FwcG'
        'xpZWRSEmNvbXBhdGlibGVfZW5naW5lc1IId2FybmluZ3NSBWVycm9y');

@$core.Deprecated('Use getObfsCapabilitiesRequestDescriptor instead')
const GetObfsCapabilitiesRequest$json = {
  '1': 'GetObfsCapabilitiesRequest',
  '9': [
    {'1': 1, '2': 2},
  ],
  '10': ['api_version'],
};

/// Descriptor for `GetObfsCapabilitiesRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getObfsCapabilitiesRequestDescriptor =
    $convert.base64Decode('ChpHZXRPYmZzQ2FwYWJpbGl0aWVzUmVxdWVzdEoECAEQAlILYXBpX3ZlcnNpb24=');

@$core.Deprecated('Use getObfsCapabilitiesResponseDescriptor instead')
const GetObfsCapabilitiesResponse$json = {
  '1': 'GetObfsCapabilitiesResponse',
  '9': [
    {'1': 1, '2': 2},
    {'1': 2, '2': 3},
  ],
  '10': ['engines', 'error'],
};

/// Descriptor for `GetObfsCapabilitiesResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getObfsCapabilitiesResponseDescriptor =
    $convert.base64Decode('ChtHZXRPYmZzQ2FwYWJpbGl0aWVzUmVzcG9uc2VKBAgBEAJKBAgCEANSB2VuZ2luZXNSBWVycm'
        '9y');

@$core.Deprecated('Use engineObfsCapabilitiesDescriptor instead')
const EngineObfsCapabilities$json = {
  '1': 'EngineObfsCapabilities',
  '9': [
    {'1': 1, '2': 2},
    {'1': 2, '2': 3},
    {'1': 3, '2': 4},
    {'1': 4, '2': 5},
    {'1': 5, '2': 6},
    {'1': 6, '2': 7},
    {'1': 7, '2': 8},
    {'1': 8, '2': 9},
  ],
  '10': [
    'engine',
    'utls',
    'utls_profiles',
    'supports_versioned_parrots',
    'fragmentation',
    'fragment_params',
    'jitter',
    'fake_sni'
  ],
};

/// Descriptor for `EngineObfsCapabilities`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List engineObfsCapabilitiesDescriptor =
    $convert.base64Decode('ChZFbmdpbmVPYmZzQ2FwYWJpbGl0aWVzSgQIARACSgQIAhADSgQIAxAESgQIBBAFSgQIBRAGSg'
        'QIBhAHSgQIBxAISgQICBAJUgZlbmdpbmVSBHV0bHNSDXV0bHNfcHJvZmlsZXNSGnN1cHBvcnRz'
        'X3ZlcnNpb25lZF9wYXJyb3RzUg1mcmFnbWVudGF0aW9uUg9mcmFnbWVudF9wYXJhbXNSBmppdH'
        'RlclIIZmFrZV9zbmk=');
