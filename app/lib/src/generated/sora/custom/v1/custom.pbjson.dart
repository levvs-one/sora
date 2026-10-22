// This is a generated file - do not edit.
//
// Generated from sora/custom/v1/custom.proto.

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

@$core.Deprecated('Use customProtocolDescriptor instead')
const CustomProtocol$json = {
  '1': 'CustomProtocol',
  '2': [
    {'1': 'CUSTOM_PROTOCOL_UNSPECIFIED', '2': 0},
    {'1': 'CUSTOM_PROTOCOL_VLESS', '2': 1},
    {'1': 'CUSTOM_PROTOCOL_VMESS', '2': 2},
    {'1': 'CUSTOM_PROTOCOL_TROJAN', '2': 3},
    {'1': 'CUSTOM_PROTOCOL_SHADOWSOCKS', '2': 4},
    {'1': 'CUSTOM_PROTOCOL_WIREGUARD', '2': 5},
  ],
};

/// Descriptor for `CustomProtocol`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List customProtocolDescriptor =
    $convert.base64Decode('Cg5DdXN0b21Qcm90b2NvbBIfChtDVVNUT01fUFJPVE9DT0xfVU5TUEVDSUZJRUQQABIZChVDVV'
        'NUT01fUFJPVE9DT0xfVkxFU1MQARIZChVDVVNUT01fUFJPVE9DT0xfVk1FU1MQAhIaChZDVVNU'
        'T01fUFJPVE9DT0xfVFJPSkFOEAMSHwobQ1VTVE9NX1BST1RPQ09MX1NIQURPV1NPQ0tTEAQSHQ'
        'oZQ1VTVE9NX1BST1RPQ09MX1dJUkVHVUFSRBAF');

@$core.Deprecated('Use customServerDescriptor instead')
const CustomServer$json = {
  '1': 'CustomServer',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'protocol', '3': 3, '4': 1, '5': 14, '6': '.sora.custom.v1.CustomProtocol', '10': 'protocol'},
    {'1': 'address', '3': 4, '4': 1, '5': 9, '10': 'address'},
    {'1': 'port', '3': 5, '4': 1, '5': 13, '10': 'port'},
    {'1': 'credentials', '3': 6, '4': 1, '5': 9, '10': 'credentials'},
    {'1': 'has_credentials', '3': 7, '4': 1, '5': 8, '10': 'hasCredentials'},
    {'1': 'protocol_name', '3': 8, '4': 1, '5': 9, '10': 'protocolName'},
    {'1': 'transport', '3': 9, '4': 1, '5': 9, '10': 'transport'},
    {'1': 'security', '3': 10, '4': 1, '5': 9, '10': 'security'},
    {'1': 'outbound', '3': 11, '4': 1, '5': 11, '6': '.sora.core.v1.OutboundSpec', '10': 'outbound'},
  ],
};

/// Descriptor for `CustomServer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List customServerDescriptor =
    $convert.base64Decode('CgxDdXN0b21TZXJ2ZXISDgoCaWQYASABKAlSAmlkEhIKBG5hbWUYAiABKAlSBG5hbWUSOgoIcH'
        'JvdG9jb2wYAyABKA4yHi5zb3JhLmN1c3RvbS52MS5DdXN0b21Qcm90b2NvbFIIcHJvdG9jb2wS'
        'GAoHYWRkcmVzcxgEIAEoCVIHYWRkcmVzcxISCgRwb3J0GAUgASgNUgRwb3J0EiAKC2NyZWRlbn'
        'RpYWxzGAYgASgJUgtjcmVkZW50aWFscxInCg9oYXNfY3JlZGVudGlhbHMYByABKAhSDmhhc0Ny'
        'ZWRlbnRpYWxzEiMKDXByb3RvY29sX25hbWUYCCABKAlSDHByb3RvY29sTmFtZRIcCgl0cmFuc3'
        'BvcnQYCSABKAlSCXRyYW5zcG9ydBIaCghzZWN1cml0eRgKIAEoCVIIc2VjdXJpdHkSNgoIb3V0'
        'Ym91bmQYCyABKAsyGi5zb3JhLmNvcmUudjEuT3V0Ym91bmRTcGVjUghvdXRib3VuZA==');

@$core.Deprecated('Use saveCustomServerRequestDescriptor instead')
const SaveCustomServerRequest$json = {
  '1': 'SaveCustomServerRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'server', '3': 3, '4': 1, '5': 11, '6': '.sora.custom.v1.CustomServer', '10': 'server'},
    {'1': 'replace_credentials', '3': 4, '4': 1, '5': 8, '10': 'replaceCredentials'},
  ],
};

/// Descriptor for `SaveCustomServerRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveCustomServerRequestDescriptor =
    $convert.base64Decode('ChdTYXZlQ3VzdG9tU2VydmVyUmVxdWVzdBI5CgthcGlfdmVyc2lvbhgBIAEoCzIYLnNvcmEuY2'
        '9yZS52MS5BcGlWZXJzaW9uUgphcGlWZXJzaW9uEjMKFWNvbnRyb2xfYXV0aGVudGljYXRvchgC'
        'IAEoDFIUY29udHJvbEF1dGhlbnRpY2F0b3ISNAoGc2VydmVyGAMgASgLMhwuc29yYS5jdXN0b2'
        '0udjEuQ3VzdG9tU2VydmVyUgZzZXJ2ZXISLwoTcmVwbGFjZV9jcmVkZW50aWFscxgEIAEoCFIS'
        'cmVwbGFjZUNyZWRlbnRpYWxz');

@$core.Deprecated('Use saveCustomServerResponseDescriptor instead')
const SaveCustomServerResponse$json = {
  '1': 'SaveCustomServerResponse',
  '2': [
    {'1': 'server', '3': 1, '4': 1, '5': 11, '6': '.sora.custom.v1.CustomServer', '10': 'server'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `SaveCustomServerResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveCustomServerResponseDescriptor =
    $convert.base64Decode('ChhTYXZlQ3VzdG9tU2VydmVyUmVzcG9uc2USNAoGc2VydmVyGAEgASgLMhwuc29yYS5jdXN0b2'
        '0udjEuQ3VzdG9tU2VydmVyUgZzZXJ2ZXISLQoFZXJyb3IYAiABKAsyFy5zb3JhLmNvcmUudjEu'
        'U29yYUVycm9yUgVlcnJvcg==');

@$core.Deprecated('Use listCustomServersRequestDescriptor instead')
const ListCustomServersRequest$json = {
  '1': 'ListCustomServersRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
  ],
};

/// Descriptor for `ListCustomServersRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listCustomServersRequestDescriptor =
    $convert.base64Decode('ChhMaXN0Q3VzdG9tU2VydmVyc1JlcXVlc3QSOQoLYXBpX3ZlcnNpb24YASABKAsyGC5zb3JhLm'
        'NvcmUudjEuQXBpVmVyc2lvblIKYXBpVmVyc2lvbhIzChVjb250cm9sX2F1dGhlbnRpY2F0b3IY'
        'AiABKAxSFGNvbnRyb2xBdXRoZW50aWNhdG9y');

@$core.Deprecated('Use listCustomServersResponseDescriptor instead')
const ListCustomServersResponse$json = {
  '1': 'ListCustomServersResponse',
  '2': [
    {'1': 'servers', '3': 1, '4': 3, '5': 11, '6': '.sora.custom.v1.CustomServer', '10': 'servers'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
    {'1': 'protocols', '3': 3, '4': 3, '5': 9, '10': 'protocols'},
  ],
};

/// Descriptor for `ListCustomServersResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listCustomServersResponseDescriptor =
    $convert.base64Decode('ChlMaXN0Q3VzdG9tU2VydmVyc1Jlc3BvbnNlEjYKB3NlcnZlcnMYASADKAsyHC5zb3JhLmN1c3'
        'RvbS52MS5DdXN0b21TZXJ2ZXJSB3NlcnZlcnMSLQoFZXJyb3IYAiABKAsyFy5zb3JhLmNvcmUu'
        'djEuU29yYUVycm9yUgVlcnJvchIcCglwcm90b2NvbHMYAyADKAlSCXByb3RvY29scw==');

@$core.Deprecated('Use deleteCustomServerRequestDescriptor instead')
const DeleteCustomServerRequest$json = {
  '1': 'DeleteCustomServerRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'id', '3': 3, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `DeleteCustomServerRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteCustomServerRequestDescriptor =
    $convert.base64Decode('ChlEZWxldGVDdXN0b21TZXJ2ZXJSZXF1ZXN0EjkKC2FwaV92ZXJzaW9uGAEgASgLMhguc29yYS'
        '5jb3JlLnYxLkFwaVZlcnNpb25SCmFwaVZlcnNpb24SMwoVY29udHJvbF9hdXRoZW50aWNhdG9y'
        'GAIgASgMUhRjb250cm9sQXV0aGVudGljYXRvchIOCgJpZBgDIAEoCVICaWQ=');

@$core.Deprecated('Use deleteCustomServerResponseDescriptor instead')
const DeleteCustomServerResponse$json = {
  '1': 'DeleteCustomServerResponse',
  '2': [
    {'1': 'error', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `DeleteCustomServerResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteCustomServerResponseDescriptor =
    $convert.base64Decode('ChpEZWxldGVDdXN0b21TZXJ2ZXJSZXNwb25zZRItCgVlcnJvchgBIAEoCzIXLnNvcmEuY29yZS'
        '52MS5Tb3JhRXJyb3JSBWVycm9y');

@$core.Deprecated('Use testCustomServerRequestDescriptor instead')
const TestCustomServerRequest$json = {
  '1': 'TestCustomServerRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'id', '3': 3, '4': 1, '5': 9, '10': 'id'},
    {'1': 'timeout_ms', '3': 4, '4': 1, '5': 13, '10': 'timeoutMs'},
  ],
};

/// Descriptor for `TestCustomServerRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testCustomServerRequestDescriptor =
    $convert.base64Decode('ChdUZXN0Q3VzdG9tU2VydmVyUmVxdWVzdBI5CgthcGlfdmVyc2lvbhgBIAEoCzIYLnNvcmEuY2'
        '9yZS52MS5BcGlWZXJzaW9uUgphcGlWZXJzaW9uEjMKFWNvbnRyb2xfYXV0aGVudGljYXRvchgC'
        'IAEoDFIUY29udHJvbEF1dGhlbnRpY2F0b3ISDgoCaWQYAyABKAlSAmlkEh0KCnRpbWVvdXRfbX'
        'MYBCABKA1SCXRpbWVvdXRNcw==');

@$core.Deprecated('Use testCustomServerResponseDescriptor instead')
const TestCustomServerResponse$json = {
  '1': 'TestCustomServerResponse',
  '2': [
    {'1': 'reachable', '3': 1, '4': 1, '5': 8, '10': 'reachable'},
    {'1': 'latency_ms', '3': 2, '4': 1, '5': 4, '10': 'latencyMs'},
    {'1': 'error', '3': 3, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `TestCustomServerResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List testCustomServerResponseDescriptor =
    $convert.base64Decode('ChhUZXN0Q3VzdG9tU2VydmVyUmVzcG9uc2USHAoJcmVhY2hhYmxlGAEgASgIUglyZWFjaGFibG'
        'USHQoKbGF0ZW5jeV9tcxgCIAEoBFIJbGF0ZW5jeU1zEi0KBWVycm9yGAMgASgLMhcuc29yYS5j'
        'b3JlLnYxLlNvcmFFcnJvclIFZXJyb3I=');

@$core.Deprecated('Use previewCustomServerRequestDescriptor instead')
const PreviewCustomServerRequest$json = {
  '1': 'PreviewCustomServerRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'link', '3': 3, '4': 1, '5': 9, '10': 'link'},
  ],
};

/// Descriptor for `PreviewCustomServerRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewCustomServerRequestDescriptor =
    $convert.base64Decode('ChpQcmV2aWV3Q3VzdG9tU2VydmVyUmVxdWVzdBI5CgthcGlfdmVyc2lvbhgBIAEoCzIYLnNvcm'
        'EuY29yZS52MS5BcGlWZXJzaW9uUgphcGlWZXJzaW9uEjMKFWNvbnRyb2xfYXV0aGVudGljYXRv'
        'chgCIAEoDFIUY29udHJvbEF1dGhlbnRpY2F0b3ISEgoEbGluaxgDIAEoCVIEbGluaw==');

@$core.Deprecated('Use previewCustomServerResponseDescriptor instead')
const PreviewCustomServerResponse$json = {
  '1': 'PreviewCustomServerResponse',
  '2': [
    {'1': 'server', '3': 1, '4': 1, '5': 11, '6': '.sora.custom.v1.CustomServer', '10': 'server'},
    {'1': 'credential_document', '3': 2, '4': 1, '5': 9, '10': 'credentialDocument'},
    {'1': 'error', '3': 3, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `PreviewCustomServerResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List previewCustomServerResponseDescriptor =
    $convert.base64Decode('ChtQcmV2aWV3Q3VzdG9tU2VydmVyUmVzcG9uc2USNAoGc2VydmVyGAEgASgLMhwuc29yYS5jdX'
        'N0b20udjEuQ3VzdG9tU2VydmVyUgZzZXJ2ZXISLwoTY3JlZGVudGlhbF9kb2N1bWVudBgCIAEo'
        'CVISY3JlZGVudGlhbERvY3VtZW50Ei0KBWVycm9yGAMgASgLMhcuc29yYS5jb3JlLnYxLlNvcm'
        'FFcnJvclIFZXJyb3I=');
