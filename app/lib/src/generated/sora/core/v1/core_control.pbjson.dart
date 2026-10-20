// This is a generated file - do not edit.
//
// Generated from sora/core/v1/core_control.proto.

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

@$core.Deprecated('Use groupTypeDescriptor instead')
const GroupType$json = {
  '1': 'GroupType',
  '2': [
    {'1': 'GROUP_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'GROUP_TYPE_SELECT', '2': 1},
    {'1': 'GROUP_TYPE_URL_TEST', '2': 2},
    {'1': 'GROUP_TYPE_FALLBACK', '2': 3},
    {'1': 'GROUP_TYPE_LOAD_BALANCE', '2': 4},
  ],
};

/// Descriptor for `GroupType`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List groupTypeDescriptor =
    $convert.base64Decode('CglHcm91cFR5cGUSGgoWR1JPVVBfVFlQRV9VTlNQRUNJRklFRBAAEhUKEUdST1VQX1RZUEVfU0'
        'VMRUNUEAESFwoTR1JPVVBfVFlQRV9VUkxfVEVTVBACEhcKE0dST1VQX1RZUEVfRkFMTEJBQ0sQ'
        'AxIbChdHUk9VUF9UWVBFX0xPQURfQkFMQU5DRRAE');

@$core.Deprecated('Use tunnelModeDescriptor instead')
const TunnelMode$json = {
  '1': 'TunnelMode',
  '2': [
    {'1': 'TUNNEL_MODE_UNSPECIFIED', '2': 0},
    {'1': 'TUNNEL_MODE_SYSTEM', '2': 1},
    {'1': 'TUNNEL_MODE_APPLICATION', '2': 2},
  ],
};

/// Descriptor for `TunnelMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List tunnelModeDescriptor =
    $convert.base64Decode('CgpUdW5uZWxNb2RlEhsKF1RVTk5FTF9NT0RFX1VOU1BFQ0lGSUVEEAASFgoSVFVOTkVMX01PRE'
        'VfU1lTVEVNEAESGwoXVFVOTkVMX01PREVfQVBQTElDQVRJT04QAg==');

@$core.Deprecated('Use connectionStateValueDescriptor instead')
const ConnectionStateValue$json = {
  '1': 'ConnectionStateValue',
  '2': [
    {'1': 'CONNECTION_STATE_VALUE_UNSPECIFIED', '2': 0},
    {'1': 'CONNECTION_STATE_VALUE_DISCONNECTED', '2': 1},
    {'1': 'CONNECTION_STATE_VALUE_CONNECTING', '2': 2},
    {'1': 'CONNECTION_STATE_VALUE_CONNECTED', '2': 3},
    {'1': 'CONNECTION_STATE_VALUE_RECONNECTING', '2': 4},
    {'1': 'CONNECTION_STATE_VALUE_FAILED', '2': 5},
  ],
};

/// Descriptor for `ConnectionStateValue`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List connectionStateValueDescriptor =
    $convert.base64Decode('ChRDb25uZWN0aW9uU3RhdGVWYWx1ZRImCiJDT05ORUNUSU9OX1NUQVRFX1ZBTFVFX1VOU1BFQ0'
        'lGSUVEEAASJwojQ09OTkVDVElPTl9TVEFURV9WQUxVRV9ESVNDT05ORUNURUQQARIlCiFDT05O'
        'RUNUSU9OX1NUQVRFX1ZBTFVFX0NPTk5FQ1RJTkcQAhIkCiBDT05ORUNUSU9OX1NUQVRFX1ZBTF'
        'VFX0NPTk5FQ1RFRBADEicKI0NPTk5FQ1RJT05fU1RBVEVfVkFMVUVfUkVDT05ORUNUSU5HEAQS'
        'IQodQ09OTkVDVElPTl9TVEFURV9WQUxVRV9GQUlMRUQQBQ==');

@$core.Deprecated('Use probeMethodDescriptor instead')
const ProbeMethod$json = {
  '1': 'ProbeMethod',
  '2': [
    {'1': 'PROBE_METHOD_UNSPECIFIED', '2': 0},
    {'1': 'PROBE_METHOD_ENGINE', '2': 1},
    {'1': 'PROBE_METHOD_CONNECT', '2': 2},
  ],
};

/// Descriptor for `ProbeMethod`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List probeMethodDescriptor =
    $convert.base64Decode('CgtQcm9iZU1ldGhvZBIcChhQUk9CRV9NRVRIT0RfVU5TUEVDSUZJRUQQABIXChNQUk9CRV9NRV'
        'RIT0RfRU5HSU5FEAESGAoUUFJPQkVfTUVUSE9EX0NPTk5FQ1QQAg==');

@$core.Deprecated('Use diagnosticFormatDescriptor instead')
const DiagnosticFormat$json = {
  '1': 'DiagnosticFormat',
  '2': [
    {'1': 'DIAGNOSTIC_FORMAT_UNSPECIFIED', '2': 0},
    {'1': 'DIAGNOSTIC_FORMAT_PCAPNG', '2': 1},
    {'1': 'DIAGNOSTIC_FORMAT_EVTX', '2': 2},
  ],
};

/// Descriptor for `DiagnosticFormat`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List diagnosticFormatDescriptor =
    $convert.base64Decode('ChBEaWFnbm9zdGljRm9ybWF0EiEKHURJQUdOT1NUSUNfRk9STUFUX1VOU1BFQ0lGSUVEEAASHA'
        'oYRElBR05PU1RJQ19GT1JNQVRfUENBUE5HEAESGgoWRElBR05PU1RJQ19GT1JNQVRfRVZUWBAC');

@$core.Deprecated('Use soraErrorCodeDescriptor instead')
const SoraErrorCode$json = {
  '1': 'SoraErrorCode',
  '2': [
    {'1': 'SORA_ERROR_CODE_UNSPECIFIED', '2': 0},
    {'1': 'SORA_ERROR_CODE_VERSION_MISMATCH', '2': 1},
    {'1': 'SORA_ERROR_CODE_UNAUTHENTICATED', '2': 2},
    {'1': 'SORA_ERROR_CODE_INVALID_ARGUMENT', '2': 3},
    {'1': 'SORA_ERROR_CODE_FAILED_PRECONDITION', '2': 4},
    {'1': 'SORA_ERROR_CODE_NOT_FOUND', '2': 5},
    {'1': 'SORA_ERROR_CODE_RESOURCE_EXHAUSTED', '2': 6},
    {'1': 'SORA_ERROR_CODE_DEADLINE_EXCEEDED', '2': 7},
    {'1': 'SORA_ERROR_CODE_UNAVAILABLE', '2': 8},
    {'1': 'SORA_ERROR_CODE_INTERNAL', '2': 9},
    {'1': 'SORA_ERROR_CODE_PERMISSION_DENIED', '2': 10},
    {'1': 'SORA_ERROR_CODE_CANCELLED', '2': 11},
  ],
};

/// Descriptor for `SoraErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List soraErrorCodeDescriptor =
    $convert.base64Decode('Cg1Tb3JhRXJyb3JDb2RlEh8KG1NPUkFfRVJST1JfQ09ERV9VTlNQRUNJRklFRBAAEiQKIFNPUk'
        'FfRVJST1JfQ09ERV9WRVJTSU9OX01JU01BVENIEAESIwofU09SQV9FUlJPUl9DT0RFX1VOQVVU'
        'SEVOVElDQVRFRBACEiQKIFNPUkFfRVJST1JfQ09ERV9JTlZBTElEX0FSR1VNRU5UEAMSJwojU0'
        '9SQV9FUlJPUl9DT0RFX0ZBSUxFRF9QUkVDT05ESVRJT04QBBIdChlTT1JBX0VSUk9SX0NPREVf'
        'Tk9UX0ZPVU5EEAUSJgoiU09SQV9FUlJPUl9DT0RFX1JFU09VUkNFX0VYSEFVU1RFRBAGEiUKIV'
        'NPUkFfRVJST1JfQ09ERV9ERUFETElORV9FWENFRURFRBAHEh8KG1NPUkFfRVJST1JfQ09ERV9V'
        'TkFWQUlMQUJMRRAIEhwKGFNPUkFfRVJST1JfQ09ERV9JTlRFUk5BTBAJEiUKIVNPUkFfRVJST1'
        'JfQ09ERV9QRVJNSVNTSU9OX0RFTklFRBAKEh0KGVNPUkFfRVJST1JfQ09ERV9DQU5DRUxMRUQQ'
        'Cw==');

@$core.Deprecated('Use logLevelDescriptor instead')
const LogLevel$json = {
  '1': 'LogLevel',
  '2': [
    {'1': 'LOG_LEVEL_UNSPECIFIED', '2': 0},
    {'1': 'LOG_LEVEL_DEBUG', '2': 1},
    {'1': 'LOG_LEVEL_INFO', '2': 2},
    {'1': 'LOG_LEVEL_WARNING', '2': 3},
    {'1': 'LOG_LEVEL_ERROR', '2': 4},
  ],
};

/// Descriptor for `LogLevel`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List logLevelDescriptor =
    $convert.base64Decode('CghMb2dMZXZlbBIZChVMT0dfTEVWRUxfVU5TUEVDSUZJRUQQABITCg9MT0dfTEVWRUxfREVCVU'
        'cQARISCg5MT0dfTEVWRUxfSU5GTxACEhUKEUxPR19MRVZFTF9XQVJOSU5HEAMSEwoPTE9HX0xF'
        'VkVMX0VSUk9SEAQ=');

@$core.Deprecated('Use logExportFormatDescriptor instead')
const LogExportFormat$json = {
  '1': 'LogExportFormat',
  '2': [
    {'1': 'LOG_EXPORT_FORMAT_UNSPECIFIED', '2': 0},
    {'1': 'LOG_EXPORT_FORMAT_JSON_LINES', '2': 1},
    {'1': 'LOG_EXPORT_FORMAT_CSV', '2': 2},
    {'1': 'LOG_EXPORT_FORMAT_LOG', '2': 3},
    {'1': 'LOG_EXPORT_FORMAT_JSON', '2': 4},
    {'1': 'LOG_EXPORT_FORMAT_XML', '2': 5},
    {'1': 'LOG_EXPORT_FORMAT_ZIP', '2': 6},
    {'1': 'LOG_EXPORT_FORMAT_GZIP', '2': 7},
  ],
};

/// Descriptor for `LogExportFormat`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List logExportFormatDescriptor =
    $convert.base64Decode('Cg9Mb2dFeHBvcnRGb3JtYXQSIQodTE9HX0VYUE9SVF9GT1JNQVRfVU5TUEVDSUZJRUQQABIgCh'
        'xMT0dfRVhQT1JUX0ZPUk1BVF9KU09OX0xJTkVTEAESGQoVTE9HX0VYUE9SVF9GT1JNQVRfQ1NW'
        'EAISGQoVTE9HX0VYUE9SVF9GT1JNQVRfTE9HEAMSGgoWTE9HX0VYUE9SVF9GT1JNQVRfSlNPTh'
        'AEEhkKFUxPR19FWFBPUlRfRk9STUFUX1hNTBAFEhkKFUxPR19FWFBPUlRfRk9STUFUX1pJUBAG'
        'EhoKFkxPR19FWFBPUlRfRk9STUFUX0daSVAQBw==');

@$core.Deprecated('Use apiVersionDescriptor instead')
const ApiVersion$json = {
  '1': 'ApiVersion',
  '2': [
    {'1': 'major', '3': 1, '4': 1, '5': 13, '10': 'major'},
    {'1': 'minor', '3': 2, '4': 1, '5': 13, '10': 'minor'},
    {'1': 'min_supported_minor', '3': 3, '4': 1, '5': 13, '10': 'minSupportedMinor'},
    {'1': 'capabilities', '3': 4, '4': 3, '5': 9, '10': 'capabilities'},
  ],
};

/// Descriptor for `ApiVersion`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List apiVersionDescriptor =
    $convert.base64Decode('CgpBcGlWZXJzaW9uEhQKBW1ham9yGAEgASgNUgVtYWpvchIUCgVtaW5vchgCIAEoDVIFbWlub3'
        'ISLgoTbWluX3N1cHBvcnRlZF9taW5vchgDIAEoDVIRbWluU3VwcG9ydGVkTWlub3ISIgoMY2Fw'
        'YWJpbGl0aWVzGAQgAygJUgxjYXBhYmlsaXRpZXM=');

@$core.Deprecated('Use connectRequestDescriptor instead')
const ConnectRequest$json = {
  '1': 'ConnectRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'session_plan', '3': 4, '4': 1, '5': 11, '6': '.sora.core.v1.SessionPlan', '10': 'sessionPlan'},
    {'1': 'control_authenticator', '3': 5, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'kill_switch', '3': 6, '4': 1, '5': 8, '10': 'killSwitch'},
  ],
};

/// Descriptor for `ConnectRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectRequestDescriptor =
    $convert.base64Decode('Cg5Db25uZWN0UmVxdWVzdBI5CgthcGlfdmVyc2lvbhgBIAEoCzIYLnNvcmEuY29yZS52MS5BcG'
        'lWZXJzaW9uUgphcGlWZXJzaW9uEh0KCnJlcXVlc3RfaWQYAiABKAlSCXJlcXVlc3RJZBIdCgpz'
        'ZXNzaW9uX2lkGAMgASgJUglzZXNzaW9uSWQSPAoMc2Vzc2lvbl9wbGFuGAQgASgLMhkuc29yYS'
        '5jb3JlLnYxLlNlc3Npb25QbGFuUgtzZXNzaW9uUGxhbhIzChVjb250cm9sX2F1dGhlbnRpY2F0'
        'b3IYBSABKAxSFGNvbnRyb2xBdXRoZW50aWNhdG9yEh8KC2tpbGxfc3dpdGNoGAYgASgIUgpraW'
        'xsU3dpdGNo');

@$core.Deprecated('Use connectResponseDescriptor instead')
const ConnectResponse$json = {
  '1': 'ConnectResponse',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.SessionStatus', '10': 'status'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `ConnectResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectResponseDescriptor =
    $convert.base64Decode('Cg9Db25uZWN0UmVzcG9uc2USMwoGc3RhdHVzGAEgASgLMhsuc29yYS5jb3JlLnYxLlNlc3Npb2'
        '5TdGF0dXNSBnN0YXR1cxItCgVlcnJvchgCIAEoCzIXLnNvcmEuY29yZS52MS5Tb3JhRXJyb3JS'
        'BWVycm9y');

@$core.Deprecated('Use disconnectRequestDescriptor instead')
const DisconnectRequest$json = {
  '1': 'DisconnectRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'control_authenticator', '3': 4, '4': 1, '5': 12, '10': 'controlAuthenticator'},
  ],
};

/// Descriptor for `DisconnectRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List disconnectRequestDescriptor =
    $convert.base64Decode('ChFEaXNjb25uZWN0UmVxdWVzdBI5CgthcGlfdmVyc2lvbhgBIAEoCzIYLnNvcmEuY29yZS52MS'
        '5BcGlWZXJzaW9uUgphcGlWZXJzaW9uEh0KCnJlcXVlc3RfaWQYAiABKAlSCXJlcXVlc3RJZBId'
        'CgpzZXNzaW9uX2lkGAMgASgJUglzZXNzaW9uSWQSMwoVY29udHJvbF9hdXRoZW50aWNhdG9yGA'
        'QgASgMUhRjb250cm9sQXV0aGVudGljYXRvcg==');

@$core.Deprecated('Use disconnectResponseDescriptor instead')
const DisconnectResponse$json = {
  '1': 'DisconnectResponse',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.SessionStatus', '10': 'status'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `DisconnectResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List disconnectResponseDescriptor =
    $convert.base64Decode('ChJEaXNjb25uZWN0UmVzcG9uc2USMwoGc3RhdHVzGAEgASgLMhsuc29yYS5jb3JlLnYxLlNlc3'
        'Npb25TdGF0dXNSBnN0YXR1cxItCgVlcnJvchgCIAEoCzIXLnNvcmEuY29yZS52MS5Tb3JhRXJy'
        'b3JSBWVycm9y');

@$core.Deprecated('Use getStatusRequestDescriptor instead')
const GetStatusRequest$json = {
  '1': 'GetStatusRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `GetStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStatusRequestDescriptor =
    $convert.base64Decode('ChBHZXRTdGF0dXNSZXF1ZXN0EjkKC2FwaV92ZXJzaW9uGAEgASgLMhguc29yYS5jb3JlLnYxLk'
        'FwaVZlcnNpb25SCmFwaVZlcnNpb24SHQoKc2Vzc2lvbl9pZBgCIAEoCVIJc2Vzc2lvbklk');

@$core.Deprecated('Use getStatusResponseDescriptor instead')
const GetStatusResponse$json = {
  '1': 'GetStatusResponse',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.SessionStatus', '10': 'status'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `GetStatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStatusResponseDescriptor =
    $convert.base64Decode('ChFHZXRTdGF0dXNSZXNwb25zZRIzCgZzdGF0dXMYASABKAsyGy5zb3JhLmNvcmUudjEuU2Vzc2'
        'lvblN0YXR1c1IGc3RhdHVzEi0KBWVycm9yGAIgASgLMhcuc29yYS5jb3JlLnYxLlNvcmFFcnJv'
        'clIFZXJyb3I=');

@$core.Deprecated('Use watchEventsRequestDescriptor instead')
const WatchEventsRequest$json = {
  '1': 'WatchEventsRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'after_sequence', '3': 3, '4': 1, '5': 4, '10': 'afterSequence'},
  ],
};

/// Descriptor for `WatchEventsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchEventsRequestDescriptor =
    $convert.base64Decode('ChJXYXRjaEV2ZW50c1JlcXVlc3QSOQoLYXBpX3ZlcnNpb24YASABKAsyGC5zb3JhLmNvcmUudj'
        'EuQXBpVmVyc2lvblIKYXBpVmVyc2lvbhIdCgpzZXNzaW9uX2lkGAIgASgJUglzZXNzaW9uSWQS'
        'JQoOYWZ0ZXJfc2VxdWVuY2UYAyABKARSDWFmdGVyU2VxdWVuY2U=');

@$core.Deprecated('Use sessionPlanDescriptor instead')
const SessionPlan$json = {
  '1': 'SessionPlan',
  '2': [
    {'1': 'tunnel_mode', '3': 1, '4': 1, '5': 14, '6': '.sora.core.v1.TunnelMode', '10': 'tunnelMode'},
    {'1': 'outbounds', '3': 2, '4': 3, '5': 11, '6': '.sora.core.v1.OutboundSpec', '10': 'outbounds'},
    {'1': 'routes', '3': 3, '4': 3, '5': 11, '6': '.sora.core.v1.RoutingRule', '10': 'routes'},
    {'1': 'dns_policy', '3': 4, '4': 1, '5': 11, '6': '.sora.core.v1.DnsPolicy', '10': 'dnsPolicy'},
    {'1': 'bypass_settings', '3': 5, '4': 1, '5': 11, '6': '.sora.core.v1.BypassSettings', '10': 'bypassSettings'},
    {'1': 'session_identity', '3': 6, '4': 1, '5': 9, '10': 'sessionIdentity'},
    {'1': 'anti_censorship', '3': 7, '4': 1, '5': 11, '6': '.sora.core.v1.AntiCensorship', '10': 'antiCensorship'},
    {'1': 'engines', '3': 8, '4': 3, '5': 9, '10': 'engines'},
    {'1': 'network_control_allowed', '3': 9, '4': 1, '5': 8, '10': 'networkControlAllowed'},
    {'1': 'local_proxy', '3': 10, '4': 1, '5': 11, '6': '.sora.core.v1.LocalProxy', '10': 'localProxy'},
    {'1': 'groups', '3': 11, '4': 3, '5': 11, '6': '.sora.core.v1.GroupSpec', '10': 'groups'},
    {'1': 'routing', '3': 12, '4': 1, '5': 11, '6': '.sora.core.v1.RoutingOptions', '10': 'routing'},
    {'1': 'ipv6', '3': 13, '4': 1, '5': 8, '10': 'ipv6'},
    {'1': 'tun_stack', '3': 14, '4': 1, '5': 9, '10': 'tunStack'},
    {'1': 'chain', '3': 15, '4': 3, '5': 9, '10': 'chain'},
    {'1': 'zapret_with_vpn', '3': 16, '4': 1, '5': 8, '10': 'zapretWithVpn'},
    {'1': 'zapret_strategy', '3': 17, '4': 1, '5': 11, '6': '.sora.core.v1.BypassStrategy', '10': 'zapretStrategy'},
  ],
};

/// Descriptor for `SessionPlan`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionPlanDescriptor =
    $convert.base64Decode('CgtTZXNzaW9uUGxhbhI5Cgt0dW5uZWxfbW9kZRgBIAEoDjIYLnNvcmEuY29yZS52'
        'MS5UdW5uZWxNb2RlUgp0dW5uZWxNb2RlEjgKCW91dGJvdW5kcxgCIAMoCzIaLnNv'
        'cmEuY29yZS52MS5PdXRib3VuZFNwZWNSCW91dGJvdW5kcxIxCgZyb3V0ZXMYAyAD'
        'KAsyGS5zb3JhLmNvcmUudjEuUm91dGluZ1J1bGVSBnJvdXRlcxI2CgpkbnNfcG9s'
        'aWN5GAQgASgLMhcuc29yYS5jb3JlLnYxLkRuc1BvbGljeVIJZG5zUG9saWN5EkUK'
        'D2J5cGFzc19zZXR0aW5ncxgFIAEoCzIcLnNvcmEuY29yZS52MS5CeXBhc3NTZXR0'
        'aW5nc1IOYnlwYXNzU2V0dGluZ3MSKQoQc2Vzc2lvbl9pZGVudGl0eRgGIAEoCVIP'
        'c2Vzc2lvbklkZW50aXR5EkUKD2FudGlfY2Vuc29yc2hpcBgHIAEoCzIcLnNvcmEu'
        'Y29yZS52MS5BbnRpQ2Vuc29yc2hpcFIOYW50aUNlbnNvcnNoaXASGAoHZW5naW5l'
        'cxgIIAMoCVIHZW5naW5lcxI2ChduZXR3b3JrX2NvbnRyb2xfYWxsb3dlZBgJIAEo'
        'CFIVbmV0d29ya0NvbnRyb2xBbGxvd2VkEjkKC2xvY2FsX3Byb3h5GAogASgLMhgu'
        'c29yYS5jb3JlLnYxLkxvY2FsUHJveHlSCmxvY2FsUHJveHkSLwoGZ3JvdXBzGAsg'
        'AygLMhcuc29yYS5jb3JlLnYxLkdyb3VwU3BlY1IGZ3JvdXBzEjYKB3JvdXRpbmcY'
        'DCABKAsyHC5zb3JhLmNvcmUudjEuUm91dGluZ09wdGlvbnNSB3JvdXRpbmcSEgoE'
        'aXB2NhgNIAEoCFIEaXB2NhIbCgl0dW5fc3RhY2sYDiABKAlSCHR1blN0YWNrEhQK'
        'BWNoYWluGA8gAygJUgVjaGFpbhImCg96YXByZXRfd2l0aF92cG4YECABKAhSDXph'
        'cHJldFdpdGhWcG4SRQoPemFwcmV0X3N0cmF0ZWd5GBEgASgLMhwuc29yYS5jb3Jl'
        'LnYxLkJ5cGFzc1N0cmF0ZWd5Ug56YXByZXRTdHJhdGVneQ==');

@$core.Deprecated('Use groupSpecDescriptor instead')
const GroupSpec$json = {
  '1': 'GroupSpec',
  '2': [
    {'1': 'name', '3': 1, '4': 1, '5': 9, '10': 'name'},
    {'1': 'type', '3': 2, '4': 1, '5': 14, '6': '.sora.core.v1.GroupType', '10': 'type'},
    {'1': 'members', '3': 3, '4': 3, '5': 9, '10': 'members'},
    {'1': 'test_url', '3': 4, '4': 1, '5': 9, '10': 'testUrl'},
    {'1': 'test_interval', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'testInterval'},
    {'1': 'tolerance_ms', '3': 6, '4': 1, '5': 13, '10': 'toleranceMs'},
    {'1': 'selected', '3': 7, '4': 1, '5': 9, '10': 'selected'},
  ],
};

/// Descriptor for `GroupSpec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupSpecDescriptor =
    $convert.base64Decode('CglHcm91cFNwZWMSEgoEbmFtZRgBIAEoCVIEbmFtZRIrCgR0eXBlGAIgASgOMhcuc29yYS5jb3Jl'
        'LnYxLkdyb3VwVHlwZVIEdHlwZRIYCgdtZW1iZXJzGAMgAygJUgdtZW1iZXJzEhkKCHRlc3RfdXJs'
        'GAQgASgJUgd0ZXN0VXJsEj4KDXRlc3RfaW50ZXJ2YWwYBSABKAsyGS5nb29nbGUucHJvdG9idWYu'
        'RHVyYXRpb25SDHRlc3RJbnRlcnZhbBIhCgx0b2xlcmFuY2VfbXMYBiABKA1SC3RvbGVyYW5jZU1z'
        'EhoKCHNlbGVjdGVkGAcgASgJUghzZWxlY3RlZA==');

@$core.Deprecated('Use routingOptionsDescriptor instead')
const RoutingOptions$json = {
  '1': 'RoutingOptions',
  '2': [
    {'1': 'preset', '3': 1, '4': 1, '5': 9, '10': 'preset'},
    {'1': 'proxy_target', '3': 2, '4': 1, '5': 9, '10': 'proxyTarget'},
    {'1': 'block_ads', '3': 3, '4': 1, '5': 8, '10': 'blockAds'},
  ],
};

/// Descriptor for `RoutingOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List routingOptionsDescriptor =
    $convert.base64Decode('Cg5Sb3V0aW5nT3B0aW9ucxIWCgZwcmVzZXQYASABKAlSBnByZXNldBIhCgxwcm94eV90YXJnZX'
        'QYAiABKAlSC3Byb3h5VGFyZ2V0EhsKCWJsb2NrX2FkcxgDIAEoCFIIYmxvY2tBZHM=');

@$core.Deprecated('Use localProxyDescriptor instead')
const LocalProxy$json = {
  '1': 'LocalProxy',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {'1': 'password', '3': 3, '4': 1, '5': 9, '10': 'password'},
  ],
};

/// Descriptor for `LocalProxy`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List localProxyDescriptor =
    $convert.base64Decode('CgpMb2NhbFByb3h5EhgKB2VuYWJsZWQYASABKAhSB2VuYWJsZWQSGgoIdXNlcm5hbWUYAiABKA'
        'lSCHVzZXJuYW1lEhoKCHBhc3N3b3JkGAMgASgJUghwYXNzd29yZA==');

@$core.Deprecated('Use antiCensorshipDescriptor instead')
const AntiCensorship$json = {
  '1': 'AntiCensorship',
  '2': [
    {'1': 'tls_fragment', '3': 1, '4': 1, '5': 8, '10': 'tlsFragment'},
    {'1': 'fragment_packets', '3': 2, '4': 1, '5': 9, '10': 'fragmentPackets'},
    {'1': 'fragment_length', '3': 3, '4': 1, '5': 9, '10': 'fragmentLength'},
    {'1': 'fragment_interval', '3': 4, '4': 1, '5': 9, '10': 'fragmentInterval'},
  ],
};

/// Descriptor for `AntiCensorship`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List antiCensorshipDescriptor =
    $convert.base64Decode('Cg5BbnRpQ2Vuc29yc2hpcBIhCgx0bHNfZnJhZ21lbnQYASABKAhSC3Rsc0ZyYWdtZW50EikKEG'
        'ZyYWdtZW50X3BhY2tldHMYAiABKAlSD2ZyYWdtZW50UGFja2V0cxInCg9mcmFnbWVudF9sZW5n'
        'dGgYAyABKAlSDmZyYWdtZW50TGVuZ3RoEisKEWZyYWdtZW50X2ludGVydmFsGAQgASgJUhBmcm'
        'FnbWVudEludGVydmFs');

@$core.Deprecated('Use outboundSpecDescriptor instead')
const OutboundSpec$json = {
  '1': 'OutboundSpec',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'display_name', '3': 2, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'bypass', '3': 8, '4': 1, '5': 11, '6': '.sora.core.v1.BypassStrategy', '10': 'bypass'},
    {'1': 'protocol', '3': 3, '4': 1, '5': 9, '10': 'protocol'},
    {'1': 'transport', '3': 4, '4': 1, '5': 9, '10': 'transport'},
    {'1': 'security', '3': 5, '4': 1, '5': 9, '10': 'security'},
    {'1': 'endpoint', '3': 6, '4': 1, '5': 11, '6': '.sora.core.v1.Endpoint', '10': 'endpoint'},
    {'1': 'credentials', '3': 7, '4': 1, '5': 11, '6': '.sora.core.v1.CredentialsRef', '10': 'credentials'},
    {'1': 'display_protocol', '3': 9, '4': 1, '5': 9, '10': 'displayProtocol'},
    {'1': 'flow', '3': 10, '4': 1, '5': 9, '10': 'flow'},
    {'1': 'flow_auto', '3': 11, '4': 1, '5': 8, '10': 'flowAuto'},
  ],
};

/// Descriptor for `OutboundSpec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outboundSpecDescriptor =
    $convert.base64Decode(
        'CgxPdXRib3VuZFNwZWMSDgoCaWQYASABKAlSAmlkEiEKDGRpc3BsYXlfbmFtZRgCIAEoCVILZGlz'
        'cGxheU5hbWUSNAoGYnlwYXNzGAggASgLMhwuc29yYS5jb3JlLnYxLkJ5cGFzc1N0cmF0ZWd5UgZi'
        'eXBhc3MSGgoIcHJvdG9jb2wYAyABKAlSCHByb3RvY29sEhwKCXRyYW5zcG9ydBgEIAEoCVIJdHJh'
        'bnNwb3J0EhoKCHNlY3VyaXR5GAUgASgJUghzZWN1cml0eRIyCghlbmRwb2ludBgGIAEoCzIWLnNv'
        'cmEuY29yZS52MS5FbmRwb2ludFIIZW5kcG9pbnQSPgoLY3JlZGVudGlhbHMYByABKAsyHC5zb3Jh'
        'LmNvcmUudjEuQ3JlZGVudGlhbHNSZWZSC2NyZWRlbnRpYWxzEikKEGRpc3BsYXlfcHJvdG9jb2wY'
        'CSABKAlSD2Rpc3BsYXlQcm90b2NvbBISCgRmbG93GAogASgJUgRmbG93EhsKCWZsb3dfYXV0bxgL'
        'IAEoCFIIZmxvd0F1dG8='
    );

@$core.Deprecated('Use endpointDescriptor instead')
const Endpoint$json = {
  '1': 'Endpoint',
  '2': [
    {'1': 'host', '3': 1, '4': 1, '5': 9, '10': 'host'},
    {'1': 'port', '3': 2, '4': 1, '5': 13, '10': 'port'},
  ],
};

/// Descriptor for `Endpoint`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List endpointDescriptor =
    $convert.base64Decode('CghFbmRwb2ludBISCgRob3N0GAEgASgJUgRob3N0EhIKBHBvcnQYAiABKA1SBHBvcnQ=');

@$core.Deprecated('Use credentialsRefDescriptor instead')
const CredentialsRef$json = {
  '1': 'CredentialsRef',
  '2': [
    {'1': 'reference', '3': 1, '4': 1, '5': 9, '10': 'reference'},
  ],
};

/// Descriptor for `CredentialsRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List credentialsRefDescriptor =
    $convert.base64Decode('Cg5DcmVkZW50aWFsc1JlZhIcCglyZWZlcmVuY2UYASABKAlSCXJlZmVyZW5jZQ==');

@$core.Deprecated('Use routingRuleDescriptor instead')
const RoutingRule$json = {
  '1': 'RoutingRule',
  '2': [
    {'1': 'destination', '3': 1, '4': 1, '5': 9, '10': 'destination'},
    {'1': 'outbound_id', '3': 2, '4': 1, '5': 9, '10': 'outboundId'},
  ],
};

/// Descriptor for `RoutingRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List routingRuleDescriptor =
    $convert.base64Decode('CgtSb3V0aW5nUnVsZRIgCgtkZXN0aW5hdGlvbhgBIAEoCVILZGVzdGluYXRpb24SHwoLb3V0Ym'
        '91bmRfaWQYAiABKAlSCm91dGJvdW5kSWQ=');

@$core.Deprecated('Use dnsPolicyDescriptor instead')
const DnsPolicy$json = {
  '1': 'DnsPolicy',
  '2': [
    {'1': 'servers', '3': 1, '4': 3, '5': 9, '10': 'servers'},
    {'1': 'block_private', '3': 2, '4': 1, '5': 8, '10': 'blockPrivate'},
  ],
};

/// Descriptor for `DnsPolicy`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dnsPolicyDescriptor =
    $convert.base64Decode('CglEbnNQb2xpY3kSGAoHc2VydmVycxgBIAMoCVIHc2VydmVycxIjCg1ibG9ja19wcml2YXRlGA'
        'IgASgIUgxibG9ja1ByaXZhdGU=');

@$core.Deprecated('Use bypassSettingsDescriptor instead')
const BypassSettings$json = {
  '1': 'BypassSettings',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'rules', '3': 2, '4': 3, '5': 9, '10': 'rules'},
  ],
};

/// Descriptor for `BypassSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bypassSettingsDescriptor =
    $convert.base64Decode('Cg5CeXBhc3NTZXR0aW5ncxIYCgdlbmFibGVkGAEgASgIUgdlbmFibGVkEhQKBXJ1bGVzGAIgAy'
        'gJUgVydWxlcw==');

@$core.Deprecated('Use sessionStatusDescriptor instead')
const SessionStatus$json = {
  '1': 'SessionStatus',
  '2': [
    {'1': 'connection', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ConnectionState', '10': 'connection'},
    {'1': 'negotiated_version', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'negotiatedVersion'},
  ],
};

/// Descriptor for `SessionStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionStatusDescriptor =
    $convert.base64Decode('Cg1TZXNzaW9uU3RhdHVzEj0KCmNvbm5lY3Rpb24YASABKAsyHS5zb3JhLmNvcmUudjEuQ29ubm'
        'VjdGlvblN0YXRlUgpjb25uZWN0aW9uEkcKEm5lZ290aWF0ZWRfdmVyc2lvbhgCIAEoCzIYLnNv'
        'cmEuY29yZS52MS5BcGlWZXJzaW9uUhFuZWdvdGlhdGVkVmVyc2lvbg==');

@$core.Deprecated('Use getStatsRequestDescriptor instead')
const GetStatsRequest$json = {
  '1': 'GetStatsRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `GetStatsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStatsRequestDescriptor =
    $convert.base64Decode('Cg9HZXRTdGF0c1JlcXVlc3QSOQoLYXBpX3ZlcnNpb24YASABKAsyGC5zb3JhLmNvcmUudjEuQX'
        'BpVmVyc2lvblIKYXBpVmVyc2lvbhIdCgpzZXNzaW9uX2lkGAIgASgJUglzZXNzaW9uSWQ=');

@$core.Deprecated('Use getStatsResponseDescriptor instead')
const GetStatsResponse$json = {
  '1': 'GetStatsResponse',
  '2': [
    {'1': 'stats', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.StatsTick', '10': 'stats'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `GetStatsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStatsResponseDescriptor =
    $convert.base64Decode('ChBHZXRTdGF0c1Jlc3BvbnNlEi0KBXN0YXRzGAEgASgLMhcuc29yYS5jb3JlLnYxLlN0YXRzVG'
        'lja1IFc3RhdHMSLQoFZXJyb3IYAiABKAsyFy5zb3JhLmNvcmUudjEuU29yYUVycm9yUgVlcnJv'
        'cg==');

@$core.Deprecated('Use connectionStateDescriptor instead')
const ConnectionState$json = {
  '1': 'ConnectionState',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 14, '6': '.sora.core.v1.ConnectionStateValue', '10': 'value'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'reason', '3': 3, '4': 1, '5': 14, '6': '.sora.core.v1.SoraErrorCode', '10': 'reason'},
    {'1': 'changed_at', '3': 4, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'changedAt'},
    {'1': 'retry_after', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'retryAfter'},
  ],
};

/// Descriptor for `ConnectionState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectionStateDescriptor =
    $convert.base64Decode('Cg9Db25uZWN0aW9uU3RhdGUSOAoFdmFsdWUYASABKA4yIi5zb3JhLmNvcmUudjEuQ29ubmVjdG'
        'lvblN0YXRlVmFsdWVSBXZhbHVlEh0KCnNlc3Npb25faWQYAiABKAlSCXNlc3Npb25JZBIzCgZy'
        'ZWFzb24YAyABKA4yGy5zb3JhLmNvcmUudjEuU29yYUVycm9yQ29kZVIGcmVhc29uEjkKCmNoYW'
        '5nZWRfYXQYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgljaGFuZ2VkQXQSOgoL'
        'cmV0cnlfYWZ0ZXIYBSABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SCnJldHJ5QWZ0ZX'
        'I=');

@$core.Deprecated('Use coreEventDescriptor instead')
const CoreEvent$json = {
  '1': 'CoreEvent',
  '2': [
    {'1': 'sequence', '3': 1, '4': 1, '5': 4, '10': 'sequence'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'emitted_at', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'emittedAt'},
    {'1': 'state_changed', '3': 4, '4': 1, '5': 11, '6': '.sora.core.v1.StateChanged', '9': 0, '10': 'stateChanged'},
    {'1': 'stats_tick', '3': 5, '4': 1, '5': 11, '6': '.sora.core.v1.StatsTick', '9': 0, '10': 'statsTick'},
    {
      '1': 'bypass_strategy_changed',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.sora.core.v1.BypassStrategyChanged',
      '9': 0,
      '10': 'bypassStrategyChanged'
    },
    {'1': 'probe_result', '3': 7, '4': 1, '5': 11, '6': '.sora.core.v1.ProbeResult', '9': 0, '10': 'probeResult'},
    {'1': 'log_batch', '3': 8, '4': 1, '5': 11, '6': '.sora.core.v1.LogBatch', '9': 0, '10': 'logBatch'},
    {'1': 'error', '3': 9, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '9': 0, '10': 'error'},
    {
      '1': 'kill_switch_changed',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.sora.core.v1.KillSwitchChanged',
      '9': 0,
      '10': 'killSwitchChanged'
    },
    {
      '1': 'group_switched',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.sora.core.v1.GroupSwitched',
      '9': 0,
      '10': 'groupSwitched'
    },
    {
      '1': 'profile_matched',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.sora.core.v1.ProfileMatched',
      '9': 0,
      '10': 'profileMatched'
    },
    {
      '1': 'censorship_detected',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.sora.core.v1.CensorshipDetected',
      '9': 0,
      '10': 'censorshipDetected'
    },
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `CoreEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List coreEventDescriptor =
    $convert.base64Decode(
        'CglDb3JlRXZlbnQSGgoIc2VxdWVuY2UYASABKARSCHNlcXVlbmNlEh0KCnNlc3Npb25faWQYAiAB'
        'KAlSCXNlc3Npb25JZBI5CgplbWl0dGVkX2F0GAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz'
        'dGFtcFIJZW1pdHRlZEF0EkEKDXN0YXRlX2NoYW5nZWQYBCABKAsyGi5zb3JhLmNvcmUudjEuU3Rh'
        'dGVDaGFuZ2VkSABSDHN0YXRlQ2hhbmdlZBI4CgpzdGF0c190aWNrGAUgASgLMhcuc29yYS5jb3Jl'
        'LnYxLlN0YXRzVGlja0gAUglzdGF0c1RpY2sSXQoXYnlwYXNzX3N0cmF0ZWd5X2NoYW5nZWQYBiAB'
        'KAsyIy5zb3JhLmNvcmUudjEuQnlwYXNzU3RyYXRlZ3lDaGFuZ2VkSABSFWJ5cGFzc1N0cmF0ZWd5'
        'Q2hhbmdlZBI+Cgxwcm9iZV9yZXN1bHQYByABKAsyGS5zb3JhLmNvcmUudjEuUHJvYmVSZXN1bHRI'
        'AFILcHJvYmVSZXN1bHQSNQoJbG9nX2JhdGNoGAggASgLMhYuc29yYS5jb3JlLnYxLkxvZ0JhdGNo'
        'SABSCGxvZ0JhdGNoEi8KBWVycm9yGAkgASgLMhcuc29yYS5jb3JlLnYxLlNvcmFFcnJvckgAUgVl'
        'cnJvchJRChNraWxsX3N3aXRjaF9jaGFuZ2VkGAogASgLMh8uc29yYS5jb3JlLnYxLktpbGxTd2l0'
        'Y2hDaGFuZ2VkSABSEWtpbGxTd2l0Y2hDaGFuZ2VkEkQKDmdyb3VwX3N3aXRjaGVkGAsgASgLMhsu'
        'c29yYS5jb3JlLnYxLkdyb3VwU3dpdGNoZWRIAFINZ3JvdXBTd2l0Y2hlZBJHCg9wcm9maWxlX21h'
        'dGNoZWQYDCABKAsyHC5zb3JhLmNvcmUudjEuUHJvZmlsZU1hdGNoZWRIAFIOcHJvZmlsZU1hdGNo'
        'ZWQSUwoTY2Vuc29yc2hpcF9kZXRlY3RlZBgNIAEoCzIgLnNvcmEuY29yZS52MS5DZW5zb3JzaGlw'
        'RGV0ZWN0ZWRIAFISY2Vuc29yc2hpcERldGVjdGVkQgkKB3BheWxvYWQ='
);

@$core.Deprecated('Use stateChangedDescriptor instead')
const StateChanged$json = {
  '1': 'StateChanged',
  '2': [
    {'1': 'state', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ConnectionState', '10': 'state'},
  ],
};

/// Descriptor for `StateChanged`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stateChangedDescriptor =
    $convert.base64Decode('CgxTdGF0ZUNoYW5nZWQSMwoFc3RhdGUYASABKAsyHS5zb3JhLmNvcmUudjEuQ29ubmVjdGlvbl'
        'N0YXRlUgVzdGF0ZQ==');

@$core.Deprecated('Use groupSwitchedDescriptor instead')
const GroupSwitched$json = {
  '1': 'GroupSwitched',
  '2': [
    {'1': 'group', '3': 1, '4': 1, '5': 9, '10': 'group'},
    {'1': 'selected', '3': 2, '4': 1, '5': 9, '10': 'selected'},
    {'1': 'previous', '3': 3, '4': 1, '5': 9, '10': 'previous'},
  ],
};

/// Descriptor for `GroupSwitched`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupSwitchedDescriptor =
    $convert.base64Decode('Cg1Hcm91cFN3aXRjaGVkEhQKBWdyb3VwGAEgASgJUgVncm91cBIaCghzZWxlY3RlZBgCIAEoCV'
        'IIc2VsZWN0ZWQSGgoIcHJldmlvdXMYAyABKAlSCHByZXZpb3Vz');

@$core.Deprecated('Use statsTickDescriptor instead')
const StatsTick$json = {
  '1': 'StatsTick',
  '2': [
    {'1': 'bytes_up', '3': 1, '4': 1, '5': 4, '10': 'bytesUp'},
    {'1': 'bytes_down', '3': 2, '4': 1, '5': 4, '10': 'bytesDown'},
    {'1': 'active_connections', '3': 3, '4': 1, '5': 4, '10': 'activeConnections'},
  ],
};

/// Descriptor for `StatsTick`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statsTickDescriptor =
    $convert.base64Decode('CglTdGF0c1RpY2sSGQoIYnl0ZXNfdXAYASABKARSB2J5dGVzVXASHQoKYnl0ZXNfZG93bhgCIA'
        'EoBFIJYnl0ZXNEb3duEi0KEmFjdGl2ZV9jb25uZWN0aW9ucxgDIAEoBFIRYWN0aXZlQ29ubmVj'
        'dGlvbnM=');

@$core.Deprecated('Use bypassStrategyChangedDescriptor instead')
const BypassStrategyChanged$json = {
  '1': 'BypassStrategyChanged',
  '2': [
    {'1': 'strategy', '3': 1, '4': 1, '5': 9, '10': 'strategy'},
  ],
};

/// Descriptor for `BypassStrategyChanged`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bypassStrategyChangedDescriptor =
    $convert.base64Decode('ChVCeXBhc3NTdHJhdGVneUNoYW5nZWQSGgoIc3RyYXRlZ3kYASABKAlSCHN0cmF0ZWd5');

@$core.Deprecated('Use probeResultDescriptor instead')
const ProbeResult$json = {
  '1': 'ProbeResult',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'reachable', '3': 2, '4': 1, '5': 8, '10': 'reachable'},
    {'1': 'latency_ms', '3': 3, '4': 1, '5': 13, '10': 'latencyMs'},
    {'1': 'error', '3': 4, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
    {'1': 'method', '3': 5, '4': 1, '5': 9, '10': 'method'},
    {'1': 'engine', '3': 6, '4': 1, '5': 9, '10': 'engine'},
  ],
};

/// Descriptor for `ProbeResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List probeResultDescriptor =
    $convert.base64Decode('CgtQcm9iZVJlc3VsdBIbCglzZXJ2ZXJfaWQYASABKAlSCHNlcnZlcklkEhwKCXJlYWNoYWJsZR'
        'gCIAEoCFIJcmVhY2hhYmxlEh0KCmxhdGVuY3lfbXMYAyABKA1SCWxhdGVuY3lNcxItCgVlcnJv'
        'chgEIAEoCzIXLnNvcmEuY29yZS52MS5Tb3JhRXJyb3JSBWVycm9yEhYKBm1ldGhvZBgFIAEoCV'
        'IGbWV0aG9kEhYKBmVuZ2luZRgGIAEoCVIGZW5naW5l');

@$core.Deprecated('Use logBatchDescriptor instead')
const LogBatch$json = {
  '1': 'LogBatch',
  '2': [
    {'1': 'lines', '3': 1, '4': 3, '5': 9, '10': 'lines'},
  ],
};

/// Descriptor for `LogBatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logBatchDescriptor = $convert.base64Decode('CghMb2dCYXRjaBIUCgVsaW5lcxgBIAMoCVIFbGluZXM=');

@$core.Deprecated('Use killSwitchChangedDescriptor instead')
const KillSwitchChanged$json = {
  '1': 'KillSwitchChanged',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'enforced', '3': 2, '4': 1, '5': 8, '10': 'enforced'},
  ],
};

/// Descriptor for `KillSwitchChanged`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List killSwitchChangedDescriptor =
    $convert.base64Decode('ChFLaWxsU3dpdGNoQ2hhbmdlZBIYCgdlbmFibGVkGAEgASgIUgdlbmFibGVkEhoKCGVuZm9yY2'
        'VkGAIgASgIUghlbmZvcmNlZA==');

@$core.Deprecated('Use parseImportRequestDescriptor instead')
const ParseImportRequest$json = {
  '1': 'ParseImportRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'payload', '3': 3, '4': 1, '5': 12, '10': 'payload'},
  ],
};

/// Descriptor for `ParseImportRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parseImportRequestDescriptor =
    $convert.base64Decode('ChJQYXJzZUltcG9ydFJlcXVlc3QSOQoLYXBpX3ZlcnNpb24YASABKAsyGC5zb3JhLmNvcmUudj'
        'EuQXBpVmVyc2lvblIKYXBpVmVyc2lvbhIdCgpyZXF1ZXN0X2lkGAIgASgJUglyZXF1ZXN0SWQS'
        'GAoHcGF5bG9hZBgDIAEoDFIHcGF5bG9hZA==');

@$core.Deprecated('Use parseImportResponseDescriptor instead')
const ParseImportResponse$json = {
  '1': 'ParseImportResponse',
  '2': [
    {'1': 'session_plan', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.SessionPlan', '10': 'sessionPlan'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `ParseImportResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parseImportResponseDescriptor =
    $convert.base64Decode('ChNQYXJzZUltcG9ydFJlc3BvbnNlEjwKDHNlc3Npb25fcGxhbhgBIAEoCzIZLnNvcmEuY29yZS'
        '52MS5TZXNzaW9uUGxhblILc2Vzc2lvblBsYW4SLQoFZXJyb3IYAiABKAsyFy5zb3JhLmNvcmUu'
        'djEuU29yYUVycm9yUgVlcnJvcg==');

@$core.Deprecated('Use fetchSubscriptionRequestDescriptor instead')
const FetchSubscriptionRequest$json = {
  '1': 'FetchSubscriptionRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'reference', '3': 3, '4': 1, '5': 9, '10': 'reference'},
    {'1': 'user_agent', '3': 4, '4': 1, '5': 9, '10': 'userAgent'},
  ],
};

/// Descriptor for `FetchSubscriptionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fetchSubscriptionRequestDescriptor =
    $convert.base64Decode('ChhGZXRjaFN1YnNjcmlwdGlvblJlcXVlc3QSOQoLYXBpX3ZlcnNpb24YASABKAsyGC5zb3JhLm'
        'NvcmUudjEuQXBpVmVyc2lvblIKYXBpVmVyc2lvbhIdCgpyZXF1ZXN0X2lkGAIgASgJUglyZXF1'
        'ZXN0SWQSHAoJcmVmZXJlbmNlGAMgASgJUglyZWZlcmVuY2USHQoKdXNlcl9hZ2VudBgEIAEoCV'
        'IJdXNlckFnZW50');

@$core.Deprecated('Use fetchSubscriptionResponseDescriptor instead')
const FetchSubscriptionResponse$json = {
  '1': 'FetchSubscriptionResponse',
  '2': [
    {'1': 'outbounds', '3': 1, '4': 3, '5': 11, '6': '.sora.core.v1.OutboundSpec', '10': 'outbounds'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
    {'1': 'info', '3': 3, '4': 1, '5': 11, '6': '.sora.core.v1.SubscriptionInfo', '10': 'info'},
  ],
};

/// Descriptor for `FetchSubscriptionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fetchSubscriptionResponseDescriptor =
    $convert.base64Decode('ChlGZXRjaFN1YnNjcmlwdGlvblJlc3BvbnNlEjgKCW91dGJvdW5kcxgBIAMoCzIaLnNvcmEuY2'
        '9yZS52MS5PdXRib3VuZFNwZWNSCW91dGJvdW5kcxItCgVlcnJvchgCIAEoCzIXLnNvcmEuY29y'
        'ZS52MS5Tb3JhRXJyb3JSBWVycm9yEjIKBGluZm8YAyABKAsyHi5zb3JhLmNvcmUudjEuU3Vic2'
        'NyaXB0aW9uSW5mb1IEaW5mbw==');

@$core.Deprecated('Use subscriptionInfoDescriptor instead')
const SubscriptionInfo$json = {
  '1': 'SubscriptionInfo',
  '2': [
    {'1': 'title', '3': 1, '4': 1, '5': 9, '10': 'title'},
    {'1': 'update_interval', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'updateInterval'},
    {'1': 'has_usage', '3': 3, '4': 1, '5': 8, '10': 'hasUsage'},
    {'1': 'upload_bytes', '3': 4, '4': 1, '5': 4, '10': 'uploadBytes'},
    {'1': 'download_bytes', '3': 5, '4': 1, '5': 4, '10': 'downloadBytes'},
    {'1': 'total_bytes', '3': 6, '4': 1, '5': 4, '10': 'totalBytes'},
    {'1': 'expire', '3': 7, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'expire'},
    {'1': 'web_page_url', '3': 8, '4': 1, '5': 9, '10': 'webPageUrl'},
    {'1': 'support_url', '3': 9, '4': 1, '5': 9, '10': 'supportUrl'},
    {'1': 'announce', '3': 10, '4': 1, '5': 9, '10': 'announce'},
  ],
};

/// Descriptor for `SubscriptionInfo`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscriptionInfoDescriptor =
    $convert.base64Decode('ChBTdWJzY3JpcHRpb25JbmZvEhQKBXRpdGxlGAEgASgJUgV0aXRsZRJCCg91cGRhdGVfaW50ZX'
        'J2YWwYAiABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SDnVwZGF0ZUludGVydmFsEhsK'
        'CWhhc191c2FnZRgDIAEoCFIIaGFzVXNhZ2USIQoMdXBsb2FkX2J5dGVzGAQgASgEUgt1cGxvYW'
        'RCeXRlcxIlCg5kb3dubG9hZF9ieXRlcxgFIAEoBFINZG93bmxvYWRCeXRlcxIfCgt0b3RhbF9i'
        'eXRlcxgGIAEoBFIKdG90YWxCeXRlcxIyCgZleHBpcmUYByABKAsyGi5nb29nbGUucHJvdG9idW'
        'YuVGltZXN0YW1wUgZleHBpcmUSIAoMd2ViX3BhZ2VfdXJsGAggASgJUgp3ZWJQYWdlVXJsEh8K'
        'C3N1cHBvcnRfdXJsGAkgASgJUgpzdXBwb3J0VXJsEhoKCGFubm91bmNlGAogASgJUghhbm5vdW'
        '5jZQ==');

@$core.Deprecated('Use probeServersRequestDescriptor instead')
const ProbeServersRequest$json = {
  '1': 'ProbeServersRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'endpoints', '3': 3, '4': 3, '5': 11, '6': '.sora.core.v1.Endpoint', '10': 'endpoints'},
    {'1': 'outbounds', '3': 4, '4': 3, '5': 11, '6': '.sora.core.v1.OutboundSpec', '10': 'outbounds'},
    {'1': 'options', '3': 5, '4': 1, '5': 11, '6': '.sora.core.v1.ProbeOptions', '10': 'options'},
  ],
};

/// Descriptor for `ProbeServersRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List probeServersRequestDescriptor =
    $convert.base64Decode('ChNQcm9iZVNlcnZlcnNSZXF1ZXN0EjkKC2FwaV92ZXJzaW9uGAEgASgLMhguc29yYS5jb3JlLn'
        'YxLkFwaVZlcnNpb25SCmFwaVZlcnNpb24SHQoKcmVxdWVzdF9pZBgCIAEoCVIJcmVxdWVzdElk'
        'EjQKCWVuZHBvaW50cxgDIAMoCzIWLnNvcmEuY29yZS52MS5FbmRwb2ludFIJZW5kcG9pbnRzEj'
        'gKCW91dGJvdW5kcxgEIAMoCzIaLnNvcmEuY29yZS52MS5PdXRib3VuZFNwZWNSCW91dGJvdW5k'
        'cxI0CgdvcHRpb25zGAUgASgLMhouc29yYS5jb3JlLnYxLlByb2JlT3B0aW9uc1IHb3B0aW9ucw'
        '==');

@$core.Deprecated('Use probeOptionsDescriptor instead')
const ProbeOptions$json = {
  '1': 'ProbeOptions',
  '2': [
    {'1': 'method', '3': 1, '4': 1, '5': 14, '6': '.sora.core.v1.ProbeMethod', '10': 'method'},
    {'1': 'url', '3': 2, '4': 1, '5': 9, '10': 'url'},
    {'1': 'timeout_ms', '3': 3, '4': 1, '5': 13, '10': 'timeoutMs'},
    {'1': 'concurrency', '3': 4, '4': 1, '5': 13, '10': 'concurrency'},
    {'1': 'engines', '3': 5, '4': 3, '5': 9, '10': 'engines'},
  ],
};

/// Descriptor for `ProbeOptions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List probeOptionsDescriptor =
    $convert.base64Decode('CgxQcm9iZU9wdGlvbnMSMQoGbWV0aG9kGAEgASgOMhkuc29yYS5jb3JlLnYxLlByb2JlTWV0aG'
        '9kUgZtZXRob2QSEAoDdXJsGAIgASgJUgN1cmwSHQoKdGltZW91dF9tcxgDIAEoDVIJdGltZW91'
        'dE1zEiAKC2NvbmN1cnJlbmN5GAQgASgNUgtjb25jdXJyZW5jeRIYCgdlbmdpbmVzGAUgAygJUg'
        'dlbmdpbmVz');

@$core.Deprecated('Use runDiagnosticsRequestDescriptor instead')
const RunDiagnosticsRequest$json = {
  '1': 'RunDiagnosticsRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `RunDiagnosticsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List runDiagnosticsRequestDescriptor =
    $convert.base64Decode('ChVSdW5EaWFnbm9zdGljc1JlcXVlc3QSOQoLYXBpX3ZlcnNpb24YASABKAsyGC5zb3JhLmNvcm'
        'UudjEuQXBpVmVyc2lvblIKYXBpVmVyc2lvbhIdCgpyZXF1ZXN0X2lkGAIgASgJUglyZXF1ZXN0'
        'SWQSHQoKc2Vzc2lvbl9pZBgDIAEoCVIJc2Vzc2lvbklk');

@$core.Deprecated('Use runDiagnosticsResponseDescriptor instead')
const RunDiagnosticsResponse$json = {
  '1': 'RunDiagnosticsResponse',
  '2': [
    {'1': 'report', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.DiagnosticReport', '10': 'report'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `RunDiagnosticsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List runDiagnosticsResponseDescriptor =
    $convert.base64Decode('ChZSdW5EaWFnbm9zdGljc1Jlc3BvbnNlEjYKBnJlcG9ydBgBIAEoCzIeLnNvcmEuY29yZS52MS'
        '5EaWFnbm9zdGljUmVwb3J0UgZyZXBvcnQSLQoFZXJyb3IYAiABKAsyFy5zb3JhLmNvcmUudjEu'
        'U29yYUVycm9yUgVlcnJvcg==');

@$core.Deprecated('Use exportDiagnosticsRequestDescriptor instead')
const ExportDiagnosticsRequest$json = {
  '1': 'ExportDiagnosticsRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'format', '3': 4, '4': 1, '5': 14, '6': '.sora.core.v1.DiagnosticFormat', '10': 'format'},
    {'1': 'control_authenticator', '3': 5, '4': 1, '5': 12, '10': 'controlAuthenticator'},
  ],
};

/// Descriptor for `ExportDiagnosticsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportDiagnosticsRequestDescriptor =
    $convert.base64Decode('ChhFeHBvcnREaWFnbm9zdGljc1JlcXVlc3QSOQoLYXBpX3ZlcnNpb24YASABKAsyGC5zb3JhLm'
        'NvcmUudjEuQXBpVmVyc2lvblIKYXBpVmVyc2lvbhIdCgpyZXF1ZXN0X2lkGAIgASgJUglyZXF1'
        'ZXN0SWQSHQoKc2Vzc2lvbl9pZBgDIAEoCVIJc2Vzc2lvbklkEjYKBmZvcm1hdBgEIAEoDjIeLn'
        'NvcmEuY29yZS52MS5EaWFnbm9zdGljRm9ybWF0UgZmb3JtYXQSMwoVY29udHJvbF9hdXRoZW50'
        'aWNhdG9yGAUgASgMUhRjb250cm9sQXV0aGVudGljYXRvcg==');

@$core.Deprecated('Use exportDiagnosticsResponseDescriptor instead')
const ExportDiagnosticsResponse$json = {
  '1': 'ExportDiagnosticsResponse',
  '2': [
    {'1': 'archive', '3': 1, '4': 1, '5': 12, '10': 'archive'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `ExportDiagnosticsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportDiagnosticsResponseDescriptor =
    $convert.base64Decode('ChlFeHBvcnREaWFnbm9zdGljc1Jlc3BvbnNlEhgKB2FyY2hpdmUYASABKAxSB2FyY2hpdmUSLQ'
        'oFZXJyb3IYAiABKAsyFy5zb3JhLmNvcmUudjEuU29yYUVycm9yUgVlcnJvcg==');

@$core.Deprecated('Use setKillSwitchRequestDescriptor instead')
const SetKillSwitchRequest$json = {
  '1': 'SetKillSwitchRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'enabled', '3': 4, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `SetKillSwitchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setKillSwitchRequestDescriptor =
    $convert.base64Decode('ChRTZXRLaWxsU3dpdGNoUmVxdWVzdBI5CgthcGlfdmVyc2lvbhgBIAEoCzIYLnNvcmEuY29yZS'
        '52MS5BcGlWZXJzaW9uUgphcGlWZXJzaW9uEh0KCnJlcXVlc3RfaWQYAiABKAlSCXJlcXVlc3RJ'
        'ZBIdCgpzZXNzaW9uX2lkGAMgASgJUglzZXNzaW9uSWQSGAoHZW5hYmxlZBgEIAEoCFIHZW5hYm'
        'xlZA==');

@$core.Deprecated('Use setKillSwitchResponseDescriptor instead')
const SetKillSwitchResponse$json = {
  '1': 'SetKillSwitchResponse',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `SetKillSwitchResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setKillSwitchResponseDescriptor =
    $convert.base64Decode('ChVTZXRLaWxsU3dpdGNoUmVzcG9uc2USGAoHZW5hYmxlZBgBIAEoCFIHZW5hYmxlZBItCgVlcn'
        'JvchgCIAEoCzIXLnNvcmEuY29yZS52MS5Tb3JhRXJyb3JSBWVycm9y');

@$core.Deprecated('Use selectServerRequestDescriptor instead')
const SelectServerRequest$json = {
  '1': 'SelectServerRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'request_id', '3': 3, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'session_id', '3': 4, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'group', '3': 5, '4': 1, '5': 9, '10': 'group'},
    {'1': 'target', '3': 6, '4': 1, '5': 9, '10': 'target'},
  ],
};

/// Descriptor for `SelectServerRequest`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN for API 1.12 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List selectServerRequestDescriptor =
    $convert.base64Decode('ChNTZWxlY3RTZXJ2ZXJSZXF1ZXN0EjkKC2FwaV92ZXJzaW9uGAEgASgLMhguc29yYS5jb3JlLnYx'
        'LkFwaVZlcnNpb25SCmFwaVZlcnNpb24SMwoVY29udHJvbF9hdXRoZW50aWNhdG9yGAIgASgMUhRj'
        'b250cm9sQXV0aGVudGljYXRvchIdCgpyZXF1ZXN0X2lkGAMgASgJUglyZXF1ZXN0SWQSHQoKc2Vz'
        'c2lvbl9pZBgEIAEoCVIJc2Vzc2lvbklkEhQKBWdyb3VwGAUgASgJUgVncm91cBIWCgZ0YXJnZXQY'
        'BiABKAlSBnRhcmdldA==');

@$core.Deprecated('Use selectServerResponseDescriptor instead')
const SelectServerResponse$json = {
  '1': 'SelectServerResponse',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.SessionStatus', '10': 'status'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `SelectServerResponse`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN for API 1.12 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List selectServerResponseDescriptor =
    $convert.base64Decode('ChRTZWxlY3RTZXJ2ZXJSZXNwb25zZRIzCgZzdGF0dXMYASABKAsyGy5zb3JhLmNvcmUudjEuU2Vz'
        'c2lvblN0YXR1c1IGc3RhdHVzEi0KBWVycm9yGAIgASgLMhcuc29yYS5jb3JlLnYxLlNvcmFFcnJv'
        'clIFZXJyb3I=');

@$core.Deprecated('Use diagnosticReportDescriptor instead')
const DiagnosticReport$json = {
  '1': 'DiagnosticReport',
  '2': [
    {'1': 'lines', '3': 1, '4': 3, '5': 9, '10': 'lines'},
  ],
};

/// Descriptor for `DiagnosticReport`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diagnosticReportDescriptor =
    $convert.base64Decode('ChBEaWFnbm9zdGljUmVwb3J0EhQKBWxpbmVzGAEgAygJUgVsaW5lcw==');

@$core.Deprecated('Use handshakeRequestDescriptor instead')
const HandshakeRequest$json = {
  '1': 'HandshakeRequest',
  '2': [
    {'1': 'client_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'clientVersion'},
  ],
};

/// Descriptor for `HandshakeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List handshakeRequestDescriptor =
    $convert.base64Decode('ChBIYW5kc2hha2VSZXF1ZXN0Ej8KDmNsaWVudF92ZXJzaW9uGAEgASgLMhguc29yYS5jb3JlLn'
        'YxLkFwaVZlcnNpb25SDWNsaWVudFZlcnNpb24=');

@$core.Deprecated('Use handshakeResponseDescriptor instead')
const HandshakeResponse$json = {
  '1': 'HandshakeResponse',
  '2': [
    {'1': 'negotiated_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'negotiatedVersion'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
    {'1': 'control_authenticator', '3': 3, '4': 1, '5': 12, '10': 'controlAuthenticator'},
  ],
};

/// Descriptor for `HandshakeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List handshakeResponseDescriptor =
    $convert.base64Decode('ChFIYW5kc2hha2VSZXNwb25zZRJHChJuZWdvdGlhdGVkX3ZlcnNpb24YASABKAsyGC5zb3JhLm'
        'NvcmUudjEuQXBpVmVyc2lvblIRbmVnb3RpYXRlZFZlcnNpb24SLQoFZXJyb3IYAiABKAsyFy5z'
        'b3JhLmNvcmUudjEuU29yYUVycm9yUgVlcnJvchIzChVjb250cm9sX2F1dGhlbnRpY2F0b3IYAy'
        'ABKAxSFGNvbnRyb2xBdXRoZW50aWNhdG9y');

@$core.Deprecated('Use putSecretRequestDescriptor instead')
const PutSecretRequest$json = {
  '1': 'PutSecretRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'credentials', '3': 3, '4': 1, '5': 11, '6': '.sora.core.v1.CredentialsRef', '10': 'credentials'},
    {'1': 'material', '3': 4, '4': 1, '5': 12, '10': 'material'},
  ],
};

/// Descriptor for `PutSecretRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List putSecretRequestDescriptor =
    $convert.base64Decode('ChBQdXRTZWNyZXRSZXF1ZXN0EjkKC2FwaV92ZXJzaW9uGAEgASgLMhguc29yYS5jb3JlLnYxLk'
        'FwaVZlcnNpb25SCmFwaVZlcnNpb24SHQoKcmVxdWVzdF9pZBgCIAEoCVIJcmVxdWVzdElkEj4K'
        'C2NyZWRlbnRpYWxzGAMgASgLMhwuc29yYS5jb3JlLnYxLkNyZWRlbnRpYWxzUmVmUgtjcmVkZW'
        '50aWFscxIaCghtYXRlcmlhbBgEIAEoDFIIbWF0ZXJpYWw=');

@$core.Deprecated('Use putSecretResponseDescriptor instead')
const PutSecretResponse$json = {
  '1': 'PutSecretResponse',
  '2': [
    {'1': 'credentials', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.CredentialsRef', '10': 'credentials'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `PutSecretResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List putSecretResponseDescriptor =
    $convert.base64Decode('ChFQdXRTZWNyZXRSZXNwb25zZRI+CgtjcmVkZW50aWFscxgBIAEoCzIcLnNvcmEuY29yZS52MS'
        '5DcmVkZW50aWFsc1JlZlILY3JlZGVudGlhbHMSLQoFZXJyb3IYAiABKAsyFy5zb3JhLmNvcmUu'
        'djEuU29yYUVycm9yUgVlcnJvcg==');

@$core.Deprecated('Use deleteSecretRequestDescriptor instead')
const DeleteSecretRequest$json = {
  '1': 'DeleteSecretRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'credentials', '3': 3, '4': 1, '5': 11, '6': '.sora.core.v1.CredentialsRef', '10': 'credentials'},
  ],
};

/// Descriptor for `DeleteSecretRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteSecretRequestDescriptor =
    $convert.base64Decode('ChNEZWxldGVTZWNyZXRSZXF1ZXN0EjkKC2FwaV92ZXJzaW9uGAEgASgLMhguc29yYS5jb3JlLn'
        'YxLkFwaVZlcnNpb25SCmFwaVZlcnNpb24SHQoKcmVxdWVzdF9pZBgCIAEoCVIJcmVxdWVzdElk'
        'Ej4KC2NyZWRlbnRpYWxzGAMgASgLMhwuc29yYS5jb3JlLnYxLkNyZWRlbnRpYWxzUmVmUgtjcm'
        'VkZW50aWFscw==');

@$core.Deprecated('Use deleteSecretResponseDescriptor instead')
const DeleteSecretResponse$json = {
  '1': 'DeleteSecretResponse',
  '2': [
    {'1': 'error', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `DeleteSecretResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteSecretResponseDescriptor =
    $convert.base64Decode('ChREZWxldGVTZWNyZXRSZXNwb25zZRItCgVlcnJvchgBIAEoCzIXLnNvcmEuY29yZS52MS5Tb3'
        'JhRXJyb3JSBWVycm9y');

@$core.Deprecated('Use soraErrorDescriptor instead')
const SoraError$json = {
  '1': 'SoraError',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 14, '6': '.sora.core.v1.SoraErrorCode', '10': 'code'},
    {'1': 'user_message_key', '3': 2, '4': 1, '5': 9, '10': 'userMessageKey'},
    {'1': 'detail_redacted', '3': 3, '4': 1, '5': 9, '10': 'detailRedacted'},
    {'1': 'retryable', '3': 4, '4': 1, '5': 8, '10': 'retryable'},
    {'1': 'request_id', '3': 5, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'retry_after', '3': 6, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'retryAfter'},
  ],
};

/// Descriptor for `SoraError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List soraErrorDescriptor =
    $convert.base64Decode('CglTb3JhRXJyb3ISLwoEY29kZRgBIAEoDjIbLnNvcmEuY29yZS52MS5Tb3JhRXJyb3JDb2RlUg'
        'Rjb2RlEigKEHVzZXJfbWVzc2FnZV9rZXkYAiABKAlSDnVzZXJNZXNzYWdlS2V5EicKD2RldGFp'
        'bF9yZWRhY3RlZBgDIAEoCVIOZGV0YWlsUmVkYWN0ZWQSHAoJcmV0cnlhYmxlGAQgASgIUglyZX'
        'RyeWFibGUSHQoKcmVxdWVzdF9pZBgFIAEoCVIJcmVxdWVzdElkEjoKC3JldHJ5X2FmdGVyGAYg'
        'ASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUgpyZXRyeUFmdGVy');

@$core.Deprecated('Use logEntryDescriptor instead')
const LogEntry$json = {
  '1': 'LogEntry',
  '2': [
    {'1': 'sequence', '3': 1, '4': 1, '5': 4, '10': 'sequence'},
    {'1': 'time', '3': 2, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'time'},
    {'1': 'level', '3': 3, '4': 1, '5': 14, '6': '.sora.core.v1.LogLevel', '10': 'level'},
    {'1': 'source', '3': 4, '4': 1, '5': 9, '10': 'source'},
    {'1': 'message', '3': 5, '4': 1, '5': 9, '10': 'message'},
    {'1': 'repeat', '3': 6, '4': 1, '5': 13, '10': 'repeat'},
  ],
};

/// Descriptor for `LogEntry`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logEntryDescriptor =
    $convert.base64Decode('CghMb2dFbnRyeRIaCghzZXF1ZW5jZRgBIAEoBFIIc2VxdWVuY2USLgoEdGltZRgCIAEoCzIaLm'
        'dvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSBHRpbWUSLAoFbGV2ZWwYAyABKA4yFi5zb3JhLmNv'
        'cmUudjEuTG9nTGV2ZWxSBWxldmVsEhYKBnNvdXJjZRgEIAEoCVIGc291cmNlEhgKB21lc3NhZ2'
        'UYBSABKAlSB21lc3NhZ2USFgoGcmVwZWF0GAYgASgNUgZyZXBlYXQ=');

@$core.Deprecated('Use logFilterDescriptor instead')
const LogFilter$json = {
  '1': 'LogFilter',
  '2': [
    {'1': 'min_level', '3': 1, '4': 1, '5': 14, '6': '.sora.core.v1.LogLevel', '10': 'minLevel'},
    {'1': 'sources', '3': 2, '4': 3, '5': 9, '10': 'sources'},
    {'1': 'contains', '3': 3, '4': 1, '5': 9, '10': 'contains'},
    {'1': 'pattern', '3': 4, '4': 1, '5': 9, '10': 'pattern'},
    {'1': 'since', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'since'},
    {'1': 'until', '3': 6, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'until'},
  ],
};

/// Descriptor for `LogFilter`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logFilterDescriptor =
    $convert.base64Decode('CglMb2dGaWx0ZXISMwoJbWluX2xldmVsGAEgASgOMhYuc29yYS5jb3JlLnYxLkxvZ0xldmVsUg'
        'htaW5MZXZlbBIYCgdzb3VyY2VzGAIgAygJUgdzb3VyY2VzEhoKCGNvbnRhaW5zGAMgASgJUghj'
        'b250YWlucxIYCgdwYXR0ZXJuGAQgASgJUgdwYXR0ZXJuEjAKBXNpbmNlGAUgASgLMhouZ29vZ2'
        'xlLnByb3RvYnVmLlRpbWVzdGFtcFIFc2luY2USMAoFdW50aWwYBiABKAsyGi5nb29nbGUucHJv'
        'dG9idWYuVGltZXN0YW1wUgV1bnRpbA==');

@$core.Deprecated('Use queryLogsRequestDescriptor instead')
const QueryLogsRequest$json = {
  '1': 'QueryLogsRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'filter', '3': 3, '4': 1, '5': 11, '6': '.sora.core.v1.LogFilter', '10': 'filter'},
    {'1': 'before_sequence', '3': 4, '4': 1, '5': 4, '10': 'beforeSequence'},
    {'1': 'limit', '3': 5, '4': 1, '5': 13, '10': 'limit'},
  ],
};

/// Descriptor for `QueryLogsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryLogsRequestDescriptor =
    $convert.base64Decode('ChBRdWVyeUxvZ3NSZXF1ZXN0EjkKC2FwaV92ZXJzaW9uGAEgASgLMhguc29yYS5jb3JlLnYxLk'
        'FwaVZlcnNpb25SCmFwaVZlcnNpb24SMwoVY29udHJvbF9hdXRoZW50aWNhdG9yGAIgASgMUhRj'
        'b250cm9sQXV0aGVudGljYXRvchIvCgZmaWx0ZXIYAyABKAsyFy5zb3JhLmNvcmUudjEuTG9nRm'
        'lsdGVyUgZmaWx0ZXISJwoPYmVmb3JlX3NlcXVlbmNlGAQgASgEUg5iZWZvcmVTZXF1ZW5jZRIU'
        'CgVsaW1pdBgFIAEoDVIFbGltaXQ=');

@$core.Deprecated('Use queryLogsResponseDescriptor instead')
const QueryLogsResponse$json = {
  '1': 'QueryLogsResponse',
  '2': [
    {'1': 'entries', '3': 1, '4': 3, '5': 11, '6': '.sora.core.v1.LogEntry', '10': 'entries'},
    {'1': 'before_sequence', '3': 2, '4': 1, '5': 4, '10': 'beforeSequence'},
    {'1': 'stats', '3': 3, '4': 1, '5': 11, '6': '.sora.core.v1.LogStats', '10': 'stats'},
    {'1': 'error', '3': 4, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `QueryLogsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List queryLogsResponseDescriptor =
    $convert.base64Decode('ChFRdWVyeUxvZ3NSZXNwb25zZRIwCgdlbnRyaWVzGAEgAygLMhYuc29yYS5jb3JlLnYxLkxvZ0'
        'VudHJ5UgdlbnRyaWVzEicKD2JlZm9yZV9zZXF1ZW5jZRgCIAEoBFIOYmVmb3JlU2VxdWVuY2US'
        'LAoFc3RhdHMYAyABKAsyFi5zb3JhLmNvcmUudjEuTG9nU3RhdHNSBXN0YXRzEi0KBWVycm9yGA'
        'QgASgLMhcuc29yYS5jb3JlLnYxLlNvcmFFcnJvclIFZXJyb3I=');

@$core.Deprecated('Use logStatsDescriptor instead')
const LogStats$json = {
  '1': 'LogStats',
  '2': [
    {'1': 'by_level', '3': 1, '4': 3, '5': 11, '6': '.sora.core.v1.LogLevelCount', '10': 'byLevel'},
    {'1': 'by_source', '3': 2, '4': 3, '5': 11, '6': '.sora.core.v1.LogSourceCount', '10': 'bySource'},
    {'1': 'total', '3': 3, '4': 1, '5': 4, '10': 'total'},
    {'1': 'bytes', '3': 4, '4': 1, '5': 4, '10': 'bytes'},
    {'1': 'max_bytes', '3': 5, '4': 1, '5': 4, '10': 'maxBytes'},
    {'1': 'dropped', '3': 6, '4': 1, '5': 4, '10': 'dropped'},
  ],
};

/// Descriptor for `LogStats`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logStatsDescriptor =
    $convert.base64Decode('CghMb2dTdGF0cxI2CghieV9sZXZlbBgBIAMoCzIbLnNvcmEuY29yZS52MS5Mb2dMZXZlbENvdW'
        '50UgdieUxldmVsEjkKCWJ5X3NvdXJjZRgCIAMoCzIcLnNvcmEuY29yZS52MS5Mb2dTb3VyY2VD'
        'b3VudFIIYnlTb3VyY2USFAoFdG90YWwYAyABKARSBXRvdGFsEhQKBWJ5dGVzGAQgASgEUgVieX'
        'RlcxIbCgltYXhfYnl0ZXMYBSABKARSCG1heEJ5dGVzEhgKB2Ryb3BwZWQYBiABKARSB2Ryb3Bw'
        'ZWQ=');

@$core.Deprecated('Use logLevelCountDescriptor instead')
const LogLevelCount$json = {
  '1': 'LogLevelCount',
  '2': [
    {'1': 'level', '3': 1, '4': 1, '5': 14, '6': '.sora.core.v1.LogLevel', '10': 'level'},
    {'1': 'count', '3': 2, '4': 1, '5': 4, '10': 'count'},
  ],
};

/// Descriptor for `LogLevelCount`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logLevelCountDescriptor =
    $convert.base64Decode('Cg1Mb2dMZXZlbENvdW50EiwKBWxldmVsGAEgASgOMhYuc29yYS5jb3JlLnYxLkxvZ0xldmVsUg'
        'VsZXZlbBIUCgVjb3VudBgCIAEoBFIFY291bnQ=');

@$core.Deprecated('Use logSourceCountDescriptor instead')
const LogSourceCount$json = {
  '1': 'LogSourceCount',
  '2': [
    {'1': 'source', '3': 1, '4': 1, '5': 9, '10': 'source'},
    {'1': 'count', '3': 2, '4': 1, '5': 4, '10': 'count'},
  ],
};

/// Descriptor for `LogSourceCount`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logSourceCountDescriptor =
    $convert.base64Decode('Cg5Mb2dTb3VyY2VDb3VudBIWCgZzb3VyY2UYASABKAlSBnNvdXJjZRIUCgVjb3VudBgCIAEoBF'
        'IFY291bnQ=');

@$core.Deprecated('Use watchLogsRequestDescriptor instead')
const WatchLogsRequest$json = {
  '1': 'WatchLogsRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'filter', '3': 3, '4': 1, '5': 11, '6': '.sora.core.v1.LogFilter', '10': 'filter'},
    {'1': 'after_sequence', '3': 4, '4': 1, '5': 4, '10': 'afterSequence'},
  ],
};

/// Descriptor for `WatchLogsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchLogsRequestDescriptor =
    $convert.base64Decode('ChBXYXRjaExvZ3NSZXF1ZXN0EjkKC2FwaV92ZXJzaW9uGAEgASgLMhguc29yYS5jb3JlLnYxLk'
        'FwaVZlcnNpb25SCmFwaVZlcnNpb24SMwoVY29udHJvbF9hdXRoZW50aWNhdG9yGAIgASgMUhRj'
        'b250cm9sQXV0aGVudGljYXRvchIvCgZmaWx0ZXIYAyABKAsyFy5zb3JhLmNvcmUudjEuTG9nRm'
        'lsdGVyUgZmaWx0ZXISJQoOYWZ0ZXJfc2VxdWVuY2UYBCABKARSDWFmdGVyU2VxdWVuY2U=');

@$core.Deprecated('Use exportLogsRequestDescriptor instead')
const ExportLogsRequest$json = {
  '1': 'ExportLogsRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'filter', '3': 3, '4': 1, '5': 11, '6': '.sora.core.v1.LogFilter', '10': 'filter'},
    {'1': 'format', '3': 4, '4': 1, '5': 14, '6': '.sora.core.v1.LogExportFormat', '10': 'format'},
    {'1': 'category', '3': 5, '4': 1, '5': 9, '10': 'category'},
  ],
};

/// Descriptor for `ExportLogsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportLogsRequestDescriptor =
    $convert.base64Decode('ChFFeHBvcnRMb2dzUmVxdWVzdBI5CgthcGlfdmVyc2lvbhgBIAEoCzIYLnNvcmEuY29yZS52MS'
        '5BcGlWZXJzaW9uUgphcGlWZXJzaW9uEjMKFWNvbnRyb2xfYXV0aGVudGljYXRvchgCIAEoDFIU'
        'Y29udHJvbEF1dGhlbnRpY2F0b3ISLwoGZmlsdGVyGAMgASgLMhcuc29yYS5jb3JlLnYxLkxvZ0'
        'ZpbHRlclIGZmlsdGVyEjUKBmZvcm1hdBgEIAEoDjIdLnNvcmEuY29yZS52MS5Mb2dFeHBvcnRG'
        'b3JtYXRSBmZvcm1hdBIaCghjYXRlZ29yeRgFIAEoCVIIY2F0ZWdvcnk=');

@$core.Deprecated('Use exportLogsResponseDescriptor instead')
const ExportLogsResponse$json = {
  '1': 'ExportLogsResponse',
  '2': [
    {'1': 'data', '3': 1, '4': 1, '5': 12, '10': 'data'},
    {'1': 'file_name', '3': 2, '4': 1, '5': 9, '10': 'fileName'},
    {'1': 'media_type', '3': 3, '4': 1, '5': 9, '10': 'mediaType'},
    {'1': 'error', '3': 4, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `ExportLogsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportLogsResponseDescriptor =
    $convert.base64Decode('ChJFeHBvcnRMb2dzUmVzcG9uc2USEgoEZGF0YRgBIAEoDFIEZGF0YRIbCglmaWxlX25hbWUYAi'
        'ABKAlSCGZpbGVOYW1lEh0KCm1lZGlhX3R5cGUYAyABKAlSCW1lZGlhVHlwZRItCgVlcnJvchgE'
        'IAEoCzIXLnNvcmEuY29yZS52MS5Tb3JhRXJyb3JSBWVycm9y');

@$core.Deprecated('Use clearLogsRequestDescriptor instead')
const ClearLogsRequest$json = {
  '1': 'ClearLogsRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
  ],
};

/// Descriptor for `ClearLogsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clearLogsRequestDescriptor =
    $convert.base64Decode('ChBDbGVhckxvZ3NSZXF1ZXN0EjkKC2FwaV92ZXJzaW9uGAEgASgLMhguc29yYS5jb3JlLnYxLk'
        'FwaVZlcnNpb25SCmFwaVZlcnNpb24SMwoVY29udHJvbF9hdXRoZW50aWNhdG9yGAIgASgMUhRj'
        'b250cm9sQXV0aGVudGljYXRvcg==');

@$core.Deprecated('Use clearLogsResponseDescriptor instead')
const ClearLogsResponse$json = {
  '1': 'ClearLogsResponse',
  '2': [
    {'1': 'error', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `ClearLogsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clearLogsResponseDescriptor =
    $convert.base64Decode('ChFDbGVhckxvZ3NSZXNwb25zZRItCgVlcnJvchgBIAEoCzIXLnNvcmEuY29yZS52MS5Tb3JhRX'
        'Jyb3JSBWVycm9y');

@$core.Deprecated('Use logSettingsDescriptor instead')
const LogSettings$json = {
  '1': 'LogSettings',
  '2': [
    {'1': 'capture_level', '3': 1, '4': 1, '5': 14, '6': '.sora.core.v1.LogLevel', '10': 'captureLevel'},
    {'1': 'record_destinations', '3': 2, '4': 1, '5': 8, '10': 'recordDestinations'},
    {'1': 'max_entries', '3': 3, '4': 1, '5': 13, '10': 'maxEntries'},
    {'1': 'max_bytes', '3': 4, '4': 1, '5': 13, '10': 'maxBytes'},
  ],
};

/// Descriptor for `LogSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logSettingsDescriptor =
    $convert.base64Decode('CgtMb2dTZXR0aW5ncxI7Cg1jYXB0dXJlX2xldmVsGAEgASgOMhYuc29yYS5jb3JlLnYxLkxvZ0'
        'xldmVsUgxjYXB0dXJlTGV2ZWwSLwoTcmVjb3JkX2Rlc3RpbmF0aW9ucxgCIAEoCFIScmVjb3Jk'
        'RGVzdGluYXRpb25zEh8KC21heF9lbnRyaWVzGAMgASgNUgptYXhFbnRyaWVzEhsKCW1heF9ieX'
        'RlcxgEIAEoDVIIbWF4Qnl0ZXM=');

@$core.Deprecated('Use getLogSettingsRequestDescriptor instead')
const GetLogSettingsRequest$json = {
  '1': 'GetLogSettingsRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
  ],
};

/// Descriptor for `GetLogSettingsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getLogSettingsRequestDescriptor =
    $convert.base64Decode('ChVHZXRMb2dTZXR0aW5nc1JlcXVlc3QSOQoLYXBpX3ZlcnNpb24YASABKAsyGC5zb3JhLmNvcm'
        'UudjEuQXBpVmVyc2lvblIKYXBpVmVyc2lvbhIzChVjb250cm9sX2F1dGhlbnRpY2F0b3IYAiAB'
        'KAxSFGNvbnRyb2xBdXRoZW50aWNhdG9y');

@$core.Deprecated('Use getLogSettingsResponseDescriptor instead')
const GetLogSettingsResponse$json = {
  '1': 'GetLogSettingsResponse',
  '2': [
    {'1': 'settings', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.LogSettings', '10': 'settings'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `GetLogSettingsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getLogSettingsResponseDescriptor =
    $convert.base64Decode('ChZHZXRMb2dTZXR0aW5nc1Jlc3BvbnNlEjUKCHNldHRpbmdzGAEgASgLMhkuc29yYS5jb3JlLn'
        'YxLkxvZ1NldHRpbmdzUghzZXR0aW5ncxItCgVlcnJvchgCIAEoCzIXLnNvcmEuY29yZS52MS5T'
        'b3JhRXJyb3JSBWVycm9y');

@$core.Deprecated('Use setLogSettingsRequestDescriptor instead')
const SetLogSettingsRequest$json = {
  '1': 'SetLogSettingsRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'settings', '3': 3, '4': 1, '5': 11, '6': '.sora.core.v1.LogSettings', '10': 'settings'},
  ],
};

/// Descriptor for `SetLogSettingsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setLogSettingsRequestDescriptor =
    $convert.base64Decode('ChVTZXRMb2dTZXR0aW5nc1JlcXVlc3QSOQoLYXBpX3ZlcnNpb24YASABKAsyGC5zb3JhLmNvcm'
        'UudjEuQXBpVmVyc2lvblIKYXBpVmVyc2lvbhIzChVjb250cm9sX2F1dGhlbnRpY2F0b3IYAiAB'
        'KAxSFGNvbnRyb2xBdXRoZW50aWNhdG9yEjUKCHNldHRpbmdzGAMgASgLMhkuc29yYS5jb3JlLn'
        'YxLkxvZ1NldHRpbmdzUghzZXR0aW5ncw==');

@$core.Deprecated('Use setLogSettingsResponseDescriptor instead')
const SetLogSettingsResponse$json = {
  '1': 'SetLogSettingsResponse',
  '2': [
    {'1': 'settings', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.LogSettings', '10': 'settings'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `SetLogSettingsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setLogSettingsResponseDescriptor =
    $convert.base64Decode('ChZTZXRMb2dTZXR0aW5nc1Jlc3BvbnNlEjUKCHNldHRpbmdzGAEgASgLMhkuc29yYS5jb3JlLn'
        'YxLkxvZ1NldHRpbmdzUghzZXR0aW5ncxItCgVlcnJvchgCIAEoCzIXLnNvcmEuY29yZS52MS5T'
        'b3JhRXJyb3JSBWVycm9y');

@$core.Deprecated('Use connectionDescriptor instead')
const Connection$json = {
  '1': 'Connection',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'network', '3': 2, '4': 1, '5': 9, '10': 'network'},
    {'1': 'host', '3': 3, '4': 1, '5': 9, '10': 'host'},
    {'1': 'port', '3': 4, '4': 1, '5': 13, '10': 'port'},
    {'1': 'process', '3': 5, '4': 1, '5': 9, '10': 'process'},
    {'1': 'rule', '3': 6, '4': 1, '5': 9, '10': 'rule'},
    {'1': 'chain', '3': 7, '4': 3, '5': 9, '10': 'chain'},
    {'1': 'upload', '3': 8, '4': 1, '5': 4, '10': 'upload'},
    {'1': 'download', '3': 9, '4': 1, '5': 4, '10': 'download'},
    {'1': 'start', '3': 10, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'start'},
  ],
};

/// Descriptor for `Connection`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectionDescriptor =
    $convert.base64Decode('CgpDb25uZWN0aW9uEg4KAmlkGAEgASgJUgJpZBIYCgduZXR3b3JrGAIgASgJUgduZXR3b3JrEh'
        'IKBGhvc3QYAyABKAlSBGhvc3QSEgoEcG9ydBgEIAEoDVIEcG9ydBIYCgdwcm9jZXNzGAUgASgJ'
        'Ugdwcm9jZXNzEhIKBHJ1bGUYBiABKAlSBHJ1bGUSFAoFY2hhaW4YByADKAlSBWNoYWluEhYKBn'
        'VwbG9hZBgIIAEoBFIGdXBsb2FkEhoKCGRvd25sb2FkGAkgASgEUghkb3dubG9hZBIwCgVzdGFy'
        'dBgKIAEoCzIaLmdvb2dsZS5wcm90b2J1Zi5UaW1lc3RhbXBSBXN0YXJ0');

@$core.Deprecated('Use listConnectionsRequestDescriptor instead')
const ListConnectionsRequest$json = {
  '1': 'ListConnectionsRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `ListConnectionsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listConnectionsRequestDescriptor =
    $convert.base64Decode('ChZMaXN0Q29ubmVjdGlvbnNSZXF1ZXN0EjkKC2FwaV92ZXJzaW9uGAEgASgLMhguc29yYS5jb3'
        'JlLnYxLkFwaVZlcnNpb25SCmFwaVZlcnNpb24SMwoVY29udHJvbF9hdXRoZW50aWNhdG9yGAIg'
        'ASgMUhRjb250cm9sQXV0aGVudGljYXRvchIdCgpzZXNzaW9uX2lkGAMgASgJUglzZXNzaW9uSW'
        'Q=');

@$core.Deprecated('Use listConnectionsResponseDescriptor instead')
const ListConnectionsResponse$json = {
  '1': 'ListConnectionsResponse',
  '2': [
    {'1': 'connections', '3': 1, '4': 3, '5': 11, '6': '.sora.core.v1.Connection', '10': 'connections'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `ListConnectionsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listConnectionsResponseDescriptor =
    $convert.base64Decode('ChdMaXN0Q29ubmVjdGlvbnNSZXNwb25zZRI6Cgtjb25uZWN0aW9ucxgBIAMoCzIYLnNvcmEuY2'
        '9yZS52MS5Db25uZWN0aW9uUgtjb25uZWN0aW9ucxItCgVlcnJvchgCIAEoCzIXLnNvcmEuY29y'
        'ZS52MS5Tb3JhRXJyb3JSBWVycm9y');

@$core.Deprecated('Use closeConnectionRequestDescriptor instead')
const CloseConnectionRequest$json = {
  '1': 'CloseConnectionRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'connection_id', '3': 4, '4': 1, '5': 9, '10': 'connectionId'},
  ],
};

/// Descriptor for `CloseConnectionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List closeConnectionRequestDescriptor =
    $convert.base64Decode('ChZDbG9zZUNvbm5lY3Rpb25SZXF1ZXN0EjkKC2FwaV92ZXJzaW9uGAEgASgLMhguc29yYS5jb3'
        'JlLnYxLkFwaVZlcnNpb25SCmFwaVZlcnNpb24SMwoVY29udHJvbF9hdXRoZW50aWNhdG9yGAIg'
        'ASgMUhRjb250cm9sQXV0aGVudGljYXRvchIdCgpzZXNzaW9uX2lkGAMgASgJUglzZXNzaW9uSW'
        'QSIwoNY29ubmVjdGlvbl9pZBgEIAEoCVIMY29ubmVjdGlvbklk');

@$core.Deprecated('Use closeConnectionResponseDescriptor instead')
const CloseConnectionResponse$json = {
  '1': 'CloseConnectionResponse',
  '2': [
    {'1': 'error', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `CloseConnectionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List closeConnectionResponseDescriptor =
    $convert.base64Decode('ChdDbG9zZUNvbm5lY3Rpb25SZXNwb25zZRItCgVlcnJvchgBIAEoCzIXLnNvcmEuY29yZS52MS'
        '5Tb3JhRXJyb3JSBWVycm9y');

@$core.Deprecated('Use subscriptionSettingsDescriptor instead')
const SubscriptionSettings$json = {
  '1': 'SubscriptionSettings',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'url', '3': 2, '4': 1, '5': 9, '10': 'url'},
    {'1': 'name', '3': 3, '4': 1, '5': 9, '10': 'name'},
    {'1': 'user_agent', '3': 4, '4': 1, '5': 9, '10': 'userAgent'},
    {'1': 'auto_update', '3': 5, '4': 1, '5': 8, '10': 'autoUpdate'},
    {'1': 'update_interval', '3': 6, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'updateInterval'},
  ],
};

/// Descriptor for `SubscriptionSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscriptionSettingsDescriptor =
    $convert.base64Decode('ChRTdWJzY3JpcHRpb25TZXR0aW5ncxIOCgJpZBgBIAEoCVICaWQSEAoDdXJsGAIgASgJUgN1cm'
        'wSEgoEbmFtZRgDIAEoCVIEbmFtZRIdCgp1c2VyX2FnZW50GAQgASgJUgl1c2VyQWdlbnQSHwoL'
        'YXV0b191cGRhdGUYBSABKAhSCmF1dG9VcGRhdGUSQgoPdXBkYXRlX2ludGVydmFsGAYgASgLMh'
        'kuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUg51cGRhdGVJbnRlcnZhbA==');

@$core.Deprecated('Use subscriptionStateDescriptor instead')
const SubscriptionState$json = {
  '1': 'SubscriptionState',
  '2': [
    {'1': 'settings', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.SubscriptionSettings', '10': 'settings'},
    {'1': 'info', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SubscriptionInfo', '10': 'info'},
    {'1': 'outbounds', '3': 3, '4': 3, '5': 11, '6': '.sora.core.v1.OutboundSpec', '10': 'outbounds'},
    {'1': 'last_update', '3': 4, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'lastUpdate'},
    {'1': 'next_update', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'nextUpdate'},
    {'1': 'last_error', '3': 6, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'lastError'},
    {'1': 'updating', '3': 7, '4': 1, '5': 8, '10': 'updating'},
    {'1': 'deleted', '3': 8, '4': 1, '5': 8, '10': 'deleted'},
    {'1': 'display_name', '3': 9, '4': 1, '5': 9, '10': 'displayName'},
  ],
};

/// Descriptor for `SubscriptionState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List subscriptionStateDescriptor =
    $convert.base64Decode('ChFTdWJzY3JpcHRpb25TdGF0ZRI+CghzZXR0aW5ncxgBIAEoCzIiLnNvcmEuY29yZS52MS5TdW'
        'JzY3JpcHRpb25TZXR0aW5nc1IIc2V0dGluZ3MSMgoEaW5mbxgCIAEoCzIeLnNvcmEuY29yZS52'
        'MS5TdWJzY3JpcHRpb25JbmZvUgRpbmZvEjgKCW91dGJvdW5kcxgDIAMoCzIaLnNvcmEuY29yZS'
        '52MS5PdXRib3VuZFNwZWNSCW91dGJvdW5kcxI7CgtsYXN0X3VwZGF0ZRgEIAEoCzIaLmdvb2ds'
        'ZS5wcm90b2J1Zi5UaW1lc3RhbXBSCmxhc3RVcGRhdGUSOwoLbmV4dF91cGRhdGUYBSABKAsyGi'
        '5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgpuZXh0VXBkYXRlEjYKCmxhc3RfZXJyb3IYBiAB'
        'KAsyFy5zb3JhLmNvcmUudjEuU29yYUVycm9yUglsYXN0RXJyb3ISGgoIdXBkYXRpbmcYByABKA'
        'hSCHVwZGF0aW5nEhgKB2RlbGV0ZWQYCCABKAhSB2RlbGV0ZWQSIQoMZGlzcGxheV9uYW1lGAkg'
        'ASgJUgtkaXNwbGF5TmFtZQ==');

@$core.Deprecated('Use saveSubscriptionRequestDescriptor instead')
const SaveSubscriptionRequest$json = {
  '1': 'SaveSubscriptionRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'settings', '3': 3, '4': 1, '5': 11, '6': '.sora.core.v1.SubscriptionSettings', '10': 'settings'},
  ],
};

/// Descriptor for `SaveSubscriptionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveSubscriptionRequestDescriptor =
    $convert.base64Decode('ChdTYXZlU3Vic2NyaXB0aW9uUmVxdWVzdBI5CgthcGlfdmVyc2lvbhgBIAEoCzIYLnNvcmEuY2'
        '9yZS52MS5BcGlWZXJzaW9uUgphcGlWZXJzaW9uEjMKFWNvbnRyb2xfYXV0aGVudGljYXRvchgC'
        'IAEoDFIUY29udHJvbEF1dGhlbnRpY2F0b3ISPgoIc2V0dGluZ3MYAyABKAsyIi5zb3JhLmNvcm'
        'UudjEuU3Vic2NyaXB0aW9uU2V0dGluZ3NSCHNldHRpbmdz');

@$core.Deprecated('Use saveSubscriptionResponseDescriptor instead')
const SaveSubscriptionResponse$json = {
  '1': 'SaveSubscriptionResponse',
  '2': [
    {'1': 'state', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.SubscriptionState', '10': 'state'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `SaveSubscriptionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List saveSubscriptionResponseDescriptor =
    $convert.base64Decode('ChhTYXZlU3Vic2NyaXB0aW9uUmVzcG9uc2USNQoFc3RhdGUYASABKAsyHy5zb3JhLmNvcmUudj'
        'EuU3Vic2NyaXB0aW9uU3RhdGVSBXN0YXRlEi0KBWVycm9yGAIgASgLMhcuc29yYS5jb3JlLnYx'
        'LlNvcmFFcnJvclIFZXJyb3I=');

@$core.Deprecated('Use listSubscriptionsRequestDescriptor instead')
const ListSubscriptionsRequest$json = {
  '1': 'ListSubscriptionsRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
  ],
};

/// Descriptor for `ListSubscriptionsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSubscriptionsRequestDescriptor =
    $convert.base64Decode('ChhMaXN0U3Vic2NyaXB0aW9uc1JlcXVlc3QSOQoLYXBpX3ZlcnNpb24YASABKAsyGC5zb3JhLm'
        'NvcmUudjEuQXBpVmVyc2lvblIKYXBpVmVyc2lvbhIzChVjb250cm9sX2F1dGhlbnRpY2F0b3IY'
        'AiABKAxSFGNvbnRyb2xBdXRoZW50aWNhdG9y');

@$core.Deprecated('Use listSubscriptionsResponseDescriptor instead')
const ListSubscriptionsResponse$json = {
  '1': 'ListSubscriptionsResponse',
  '2': [
    {'1': 'subscriptions', '3': 1, '4': 3, '5': 11, '6': '.sora.core.v1.SubscriptionState', '10': 'subscriptions'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `ListSubscriptionsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List listSubscriptionsResponseDescriptor =
    $convert.base64Decode('ChlMaXN0U3Vic2NyaXB0aW9uc1Jlc3BvbnNlEkUKDXN1YnNjcmlwdGlvbnMYASADKAsyHy5zb3'
        'JhLmNvcmUudjEuU3Vic2NyaXB0aW9uU3RhdGVSDXN1YnNjcmlwdGlvbnMSLQoFZXJyb3IYAiAB'
        'KAsyFy5zb3JhLmNvcmUudjEuU29yYUVycm9yUgVlcnJvcg==');

@$core.Deprecated('Use deleteSubscriptionRequestDescriptor instead')
const DeleteSubscriptionRequest$json = {
  '1': 'DeleteSubscriptionRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'id', '3': 3, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `DeleteSubscriptionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteSubscriptionRequestDescriptor =
    $convert.base64Decode('ChlEZWxldGVTdWJzY3JpcHRpb25SZXF1ZXN0EjkKC2FwaV92ZXJzaW9uGAEgASgLMhguc29yYS'
        '5jb3JlLnYxLkFwaVZlcnNpb25SCmFwaVZlcnNpb24SMwoVY29udHJvbF9hdXRoZW50aWNhdG9y'
        'GAIgASgMUhRjb250cm9sQXV0aGVudGljYXRvchIOCgJpZBgDIAEoCVICaWQ=');

@$core.Deprecated('Use deleteSubscriptionResponseDescriptor instead')
const DeleteSubscriptionResponse$json = {
  '1': 'DeleteSubscriptionResponse',
  '2': [
    {'1': 'error', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `DeleteSubscriptionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List deleteSubscriptionResponseDescriptor =
    $convert.base64Decode('ChpEZWxldGVTdWJzY3JpcHRpb25SZXNwb25zZRItCgVlcnJvchgBIAEoCzIXLnNvcmEuY29yZS'
        '52MS5Tb3JhRXJyb3JSBWVycm9y');

@$core.Deprecated('Use refreshSubscriptionRequestDescriptor instead')
const RefreshSubscriptionRequest$json = {
  '1': 'RefreshSubscriptionRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'id', '3': 3, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `RefreshSubscriptionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshSubscriptionRequestDescriptor =
    $convert.base64Decode('ChpSZWZyZXNoU3Vic2NyaXB0aW9uUmVxdWVzdBI5CgthcGlfdmVyc2lvbhgBIAEoCzIYLnNvcm'
        'EuY29yZS52MS5BcGlWZXJzaW9uUgphcGlWZXJzaW9uEjMKFWNvbnRyb2xfYXV0aGVudGljYXRv'
        'chgCIAEoDFIUY29udHJvbEF1dGhlbnRpY2F0b3ISDgoCaWQYAyABKAlSAmlk');

@$core.Deprecated('Use refreshSubscriptionResponseDescriptor instead')
const RefreshSubscriptionResponse$json = {
  '1': 'RefreshSubscriptionResponse',
  '2': [
    {'1': 'state', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.SubscriptionState', '10': 'state'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `RefreshSubscriptionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List refreshSubscriptionResponseDescriptor =
    $convert.base64Decode('ChtSZWZyZXNoU3Vic2NyaXB0aW9uUmVzcG9uc2USNQoFc3RhdGUYASABKAsyHy5zb3JhLmNvcm'
        'UudjEuU3Vic2NyaXB0aW9uU3RhdGVSBXN0YXRlEi0KBWVycm9yGAIgASgLMhcuc29yYS5jb3Jl'
        'LnYxLlNvcmFFcnJvclIFZXJyb3I=');

@$core.Deprecated('Use watchSubscriptionsRequestDescriptor instead')
const WatchSubscriptionsRequest$json = {
  '1': 'WatchSubscriptionsRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
  ],
};

/// Descriptor for `WatchSubscriptionsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchSubscriptionsRequestDescriptor =
    $convert.base64Decode('ChlXYXRjaFN1YnNjcmlwdGlvbnNSZXF1ZXN0EjkKC2FwaV92ZXJzaW9uGAEgASgLMhguc29yYS'
        '5jb3JlLnYxLkFwaVZlcnNpb25SCmFwaVZlcnNpb24SMwoVY29udHJvbF9hdXRoZW50aWNhdG9y'
        'GAIgASgMUhRjb250cm9sQXV0aGVudGljYXRvcg==');

@$core.Deprecated('Use getSubscriptionLinkRequestDescriptor instead')
const GetSubscriptionLinkRequest$json = {
  '1': 'GetSubscriptionLinkRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'id', '3': 3, '4': 1, '5': 9, '10': 'id'},
  ],
};

/// Descriptor for `GetSubscriptionLinkRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSubscriptionLinkRequestDescriptor =
    $convert.base64Decode('ChpHZXRTdWJzY3JpcHRpb25MaW5rUmVxdWVzdBI5CgthcGlfdmVyc2lvbhgBIAEoCzIYLnNvcm'
        'EuY29yZS52MS5BcGlWZXJzaW9uUgphcGlWZXJzaW9uEjMKFWNvbnRyb2xfYXV0aGVudGljYXRv'
        'chgCIAEoDFIUY29udHJvbEF1dGhlbnRpY2F0b3ISDgoCaWQYAyABKAlSAmlk');

@$core.Deprecated('Use getSubscriptionLinkResponseDescriptor instead')
const GetSubscriptionLinkResponse$json = {
  '1': 'GetSubscriptionLinkResponse',
  '2': [
    {'1': 'url', '3': 1, '4': 1, '5': 9, '10': 'url'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `GetSubscriptionLinkResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSubscriptionLinkResponseDescriptor =
    $convert.base64Decode('ChtHZXRTdWJzY3JpcHRpb25MaW5rUmVzcG9uc2USEAoDdXJsGAEgASgJUgN1cmwSLQoFZXJyb3'
        'IYAiABKAsyFy5zb3JhLmNvcmUudjEuU29yYUVycm9yUgVlcnJvcg==');

@$core.Deprecated('Use getAboutRequestDescriptor instead')
const GetAboutRequest$json = {
  '1': 'GetAboutRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
  ],
};

/// Descriptor for `GetAboutRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAboutRequestDescriptor =
    $convert.base64Decode('Cg9HZXRBYm91dFJlcXVlc3QSOQoLYXBpX3ZlcnNpb24YASABKAsyGC5zb3JhLmNvcmUudjEuQX'
        'BpVmVyc2lvblIKYXBpVmVyc2lvbg==');

@$core.Deprecated('Use getAboutResponseDescriptor instead')
const GetAboutResponse$json = {
  '1': 'GetAboutResponse',
  '2': [
    {'1': 'about', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.About', '10': 'about'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `GetAboutResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getAboutResponseDescriptor =
    $convert.base64Decode('ChBHZXRBYm91dFJlc3BvbnNlEikKBWFib3V0GAEgASgLMhMuc29yYS5jb3JlLnYxLkFib3V0Ug'
        'VhYm91dBItCgVlcnJvchgCIAEoCzIXLnNvcmEuY29yZS52MS5Tb3JhRXJyb3JSBWVycm9y');

@$core.Deprecated('Use aboutDescriptor instead')
const About$json = {
  '1': 'About',
  '2': [
    {'1': 'core_version', '3': 1, '4': 1, '5': 9, '10': 'coreVersion'},
    {'1': 'commit', '3': 2, '4': 1, '5': 9, '10': 'commit'},
    {'1': 'commit_time', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'commitTime'},
    {'1': 'contract', '3': 4, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'contract'},
    {'1': 'platform', '3': 5, '4': 1, '5': 9, '10': 'platform'},
    {'1': 'go_version', '3': 6, '4': 1, '5': 9, '10': 'goVersion'},
    {'1': 'engines', '3': 7, '4': 3, '5': 11, '6': '.sora.core.v1.EngineBuild', '10': 'engines'},
    {'1': 'license', '3': 8, '4': 1, '5': 9, '10': 'license'},
    {'1': 'source_url', '3': 9, '4': 1, '5': 9, '10': 'sourceUrl'},
    {'1': 'local_proxy', '3': 10, '4': 1, '5': 11, '6': '.sora.core.v1.Endpoint', '10': 'localProxy'},
  ],
};

/// Descriptor for `About`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List aboutDescriptor =
    $convert.base64Decode('CgVBYm91dBIhCgxjb3JlX3ZlcnNpb24YASABKAlSC2NvcmVWZXJzaW9uEhYKBmNvbW1pdBgCIA'
        'EoCVIGY29tbWl0EjsKC2NvbW1pdF90aW1lGAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRpbWVz'
        'dGFtcFIKY29tbWl0VGltZRI0Cghjb250cmFjdBgEIAEoCzIYLnNvcmEuY29yZS52MS5BcGlWZX'
        'JzaW9uUghjb250cmFjdBIaCghwbGF0Zm9ybRgFIAEoCVIIcGxhdGZvcm0SHQoKZ29fdmVyc2lv'
        'bhgGIAEoCVIJZ29WZXJzaW9uEjMKB2VuZ2luZXMYByADKAsyGS5zb3JhLmNvcmUudjEuRW5naW'
        '5lQnVpbGRSB2VuZ2luZXMSGAoHbGljZW5zZRgIIAEoCVIHbGljZW5zZRIdCgpzb3VyY2VfdXJs'
        'GAkgASgJUglzb3VyY2VVcmwSNwoLbG9jYWxfcHJveHkYCiABKAsyFi5zb3JhLmNvcmUudjEuRW'
        '5kcG9pbnRSCmxvY2FsUHJveHk=');

@$core.Deprecated('Use engineBuildDescriptor instead')
const EngineBuild$json = {
  '1': 'EngineBuild',
  '2': [
    {'1': 'kind', '3': 1, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'installed', '3': 2, '4': 1, '5': 8, '10': 'installed'},
    {'1': 'version', '3': 3, '4': 1, '5': 9, '10': 'version'},
  ],
};

/// Descriptor for `EngineBuild`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List engineBuildDescriptor =
    $convert.base64Decode('CgtFbmdpbmVCdWlsZBISCgRraW5kGAEgASgJUgRraW5kEhwKCWluc3RhbGxlZBgCIAEoCFIJaW'
        '5zdGFsbGVkEhgKB3ZlcnNpb24YAyABKAlSB3ZlcnNpb24=');

@$core.Deprecated('Use getRoutingPresetsRequestDescriptor instead')
const GetRoutingPresetsRequest$json = {
  '1': 'GetRoutingPresetsRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
  ],
};

/// Descriptor for `GetRoutingPresetsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getRoutingPresetsRequestDescriptor =
    $convert.base64Decode('ChhHZXRSb3V0aW5nUHJlc2V0c1JlcXVlc3QSOQoLYXBpX3ZlcnNpb24YASABKAsyGC5zb3JhLm'
        'NvcmUudjEuQXBpVmVyc2lvblIKYXBpVmVyc2lvbg==');

@$core.Deprecated('Use getRoutingPresetsResponseDescriptor instead')
const GetRoutingPresetsResponse$json = {
  '1': 'GetRoutingPresetsResponse',
  '2': [
    {'1': 'presets', '3': 1, '4': 3, '5': 11, '6': '.sora.core.v1.RoutingPreset', '10': 'presets'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `GetRoutingPresetsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getRoutingPresetsResponseDescriptor =
    $convert.base64Decode('ChlHZXRSb3V0aW5nUHJlc2V0c1Jlc3BvbnNlEjUKB3ByZXNldHMYASADKAsyGy5zb3JhLmNvcm'
        'UudjEuUm91dGluZ1ByZXNldFIHcHJlc2V0cxItCgVlcnJvchgCIAEoCzIXLnNvcmEuY29yZS52'
        'MS5Tb3JhRXJyb3JSBWVycm9y');

@$core.Deprecated('Use routingPresetDescriptor instead')
const RoutingPreset$json = {
  '1': 'RoutingPreset',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'direct', '3': 2, '4': 3, '5': 9, '10': 'direct'},
  ],
};

/// Descriptor for `RoutingPreset`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List routingPresetDescriptor =
    $convert.base64Decode('Cg1Sb3V0aW5nUHJlc2V0Eg4KAmlkGAEgASgJUgJpZBIWCgZkaXJlY3QYAiADKAlSBmRpcmVjdA'
        '==');

@$core.Deprecated('Use bypassStrategyDescriptor instead')
const BypassStrategy$json = {
  '1': 'BypassStrategy',
  '2': [
    {'1': 'split_pos', '3': 1, '4': 3, '5': 9, '10': 'splitPos'},
    {'1': 'disorder', '3': 2, '4': 1, '5': 8, '10': 'disorder'},
    {'1': 'oob', '3': 3, '4': 1, '5': 8, '10': 'oob'},
    {'1': 'tls_record', '3': 4, '4': 1, '5': 9, '10': 'tlsRecord'},
    {'1': 'host_case', '3': 5, '4': 1, '5': 8, '10': 'hostCase'},
    {'1': 'domain_case', '3': 6, '4': 1, '5': 8, '10': 'domainCase'},
    {'1': 'method_eol', '3': 7, '4': 1, '5': 8, '10': 'methodEol'},
    {'1': 'disorder_scope', '3': 8, '4': 1, '5': 9, '10': 'disorderScope'},
    {'1': 'oob_scope', '3': 9, '4': 1, '5': 9, '10': 'oobScope'},
    {'1': 'host_dot', '3': 10, '4': 1, '5': 8, '10': 'hostDot'},
    {'1': 'host_tab', '3': 11, '4': 1, '5': 8, '10': 'hostTab'},
    {'1': 'host_no_space', '3': 12, '4': 1, '5': 8, '10': 'hostNoSpace'},
    {'1': 'method_space', '3': 13, '4': 1, '5': 8, '10': 'methodSpace'},
    {'1': 'unix_eol', '3': 14, '4': 1, '5': 8, '10': 'unixEol'},
    {'1': 'split_any_protocol', '3': 15, '4': 1, '5': 8, '10': 'splitAnyProtocol'},
    {'1': 'tamper_start', '3': 16, '4': 1, '5': 9, '10': 'tamperStart'},
    {'1': 'tamper_cutoff', '3': 17, '4': 1, '5': 9, '10': 'tamperCutoff'},
    {'1': 'oob_data', '3': 18, '4': 1, '5': 9, '10': 'oobData'},
    {'1': 'mss', '3': 19, '4': 1, '5': 9, '10': 'mss'},
    {'1': 'desync', '3': 20, '4': 3, '5': 9, '10': 'desync'},
    {'1': 'fake_tls', '3': 21, '4': 1, '5': 9, '10': 'fakeTls'},
    {'1': 'fake_quic', '3': 22, '4': 1, '5': 9, '10': 'fakeQuic'},
    {'1': 'fooling', '3': 23, '4': 1, '5': 9, '10': 'fooling'},
    {'1': 'ttl', '3': 24, '4': 1, '5': 5, '10': 'ttl'},
    {'1': 'auto_ttl', '3': 25, '4': 1, '5': 8, '10': 'autoTtl'},
    {'1': 'repeats', '3': 26, '4': 1, '5': 5, '10': 'repeats'},
    {'1': 'filter_tcp', '3': 27, '4': 1, '5': 9, '10': 'filterTcp'},
    {'1': 'filter_udp', '3': 28, '4': 1, '5': 9, '10': 'filterUdp'},
    {'1': 'filter_l7', '3': 29, '4': 1, '5': 9, '10': 'filterL7'},
  ],
};

/// Descriptor for `BypassStrategy`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bypassStrategyDescriptor =
    $convert.base64Decode('Cg5CeXBhc3NTdHJhdGVneRIbCglzcGxpdF9wb3MYASADKAlSCHNwbGl0UG9zEhoKCGRpc29yZGVy'
        'GAIgASgIUghkaXNvcmRlchIQCgNvb2IYAyABKAhSA29vYhIdCgp0bHNfcmVjb3JkGAQgASgJUgl0'
        'bHNSZWNvcmQSGwoJaG9zdF9jYXNlGAUgASgIUghob3N0Q2FzZRIfCgtkb21haW5fY2FzZRgGIAEo'
        'CFIKZG9tYWluQ2FzZRIdCgptZXRob2RfZW9sGAcgASgIUgltZXRob2RFb2wSJQoOZGlzb3JkZXJf'
        'c2NvcGUYCCABKAlSDWRpc29yZGVyU2NvcGUSGwoJb29iX3Njb3BlGAkgASgJUghvb2JTY29wZRIZ'
        'Cghob3N0X2RvdBgKIAEoCFIHaG9zdERvdBIZCghob3N0X3RhYhgLIAEoCFIHaG9zdFRhYhIiCg1o'
        'b3N0X25vX3NwYWNlGAwgASgIUgtob3N0Tm9TcGFjZRIhCgxtZXRob2Rfc3BhY2UYDSABKAhSC21l'
        'dGhvZFNwYWNlEhkKCHVuaXhfZW9sGA4gASgIUgd1bml4RW9sEiwKEnNwbGl0X2FueV9wcm90b2Nv'
        'bBgPIAEoCFIQc3BsaXRBbnlQcm90b2NvbBIhCgx0YW1wZXJfc3RhcnQYECABKAlSC3RhbXBlclN0'
        'YXJ0EiMKDXRhbXBlcl9jdXRvZmYYESABKAlSDHRhbXBlckN1dG9mZhIZCghvb2JfZGF0YRgSIAEo'
        'CVIHb29iRGF0YRIQCgNtc3MYEyABKAlSA21zcxIWCgZkZXN5bmMYFCADKAlSBmRlc3luYxIZCghm'
        'YWtlX3RscxgVIAEoCVIHZmFrZVRscxIbCglmYWtlX3F1aWMYFiABKAlSCGZha2VRdWljEhgKB2Zv'
        'b2xpbmcYFyABKAlSB2Zvb2xpbmcSEAoDdHRsGBggASgFUgN0dGwSGQoIYXV0b190dGwYGSABKAhS'
        'B2F1dG9UdGwSGAoHcmVwZWF0cxgaIAEoBVIHcmVwZWF0cxIdCgpmaWx0ZXJfdGNwGBsgASgJUglm'
        'aWx0ZXJUY3ASHQoKZmlsdGVyX3VkcBgcIAEoCVIJZmlsdGVyVWRwEhsKCWZpbHRlcl9sNxgdIAEo'
        'CVIIZmlsdGVyTDc=');

const DnsLeakCheck$json = {
  '1': 'DnsLeakCheck',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'label', '3': 2, '4': 1, '5': 9, '10': 'label'},
    {'1': 'expected', '3': 3, '4': 1, '5': 9, '10': 'expected'},
    {'1': 'actual', '3': 4, '4': 1, '5': 9, '10': 'actual'},
    {'1': 'leaked', '3': 5, '4': 1, '5': 8, '10': 'leaked'},
    {'1': 'fix_hint', '3': 6, '4': 1, '5': 9, '10': 'fixHint'},
  ],
};

/// Descriptor for `DnsLeakCheck`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dnsLeakCheckDescriptor =
    $convert.base64Decode('CgxEbnNMZWFrQ2hlY2sSDgoCaWQYASABKAlSAmlkEhQKBWxhYmVsGAIgASgJUgVsYWJlbBIaCghl'
        'eHBlY3RlZBgDIAEoCVIIZXhwZWN0ZWQSFgoGYWN0dWFsGAQgASgJUgZhY3R1YWwSFgoGbGVha2Vk'
        'GAUgASgIUgZsZWFrZWQSGQoIZml4X2hpbnQYBiABKAlSB2ZpeEhpbnQ=');

const CheckDnsLeaksRequest$json = {
  '1': 'CheckDnsLeaksRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `CheckDnsLeaksRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List checkDnsLeaksRequestDescriptor =
    $convert.base64Decode('ChRDaGVja0Ruc0xlYWtzUmVxdWVzdBI5CgthcGlfdmVyc2lvbhgBIAEoCzIYLnNvcmEuY29yZS52'
        'MS5BcGlWZXJzaW9uUgphcGlWZXJzaW9uEjMKFWNvbnRyb2xfYXV0aGVudGljYXRvchgCIAEoDFIU'
        'Y29udHJvbEF1dGhlbnRpY2F0b3ISHQoKc2Vzc2lvbl9pZBgDIAEoCVIJc2Vzc2lvbklk');

const CheckDnsLeaksResponse$json = {
  '1': 'CheckDnsLeaksResponse',
  '2': [
    {'1': 'checks', '3': 1, '4': 3, '5': 11, '6': '.sora.core.v1.DnsLeakCheck', '10': 'checks'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `CheckDnsLeaksResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List checkDnsLeaksResponseDescriptor =
    $convert.base64Decode('ChVDaGVja0Ruc0xlYWtzUmVzcG9uc2USMgoGY2hlY2tzGAEgAygLMhouc29yYS5jb3JlLnYxLkRu'
        'c0xlYWtDaGVja1IGY2hlY2tzEi0KBWVycm9yGAIgASgLMhcuc29yYS5jb3JlLnYxLlNvcmFFcnJv'
        'clIFZXJyb3I=');

const BenchmarkServersRequest$json = {
  '1': 'BenchmarkServersRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'request_id', '3': 3, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'server_ids', '3': 4, '4': 3, '5': 9, '10': 'serverIds'},
    {'1': 'duration_s', '3': 5, '4': 1, '5': 13, '10': 'durationS'},
    {'1': 'concurrency', '3': 6, '4': 1, '5': 13, '10': 'concurrency'},
    {'1': 'url', '3': 7, '4': 1, '5': 9, '10': 'url'},
  ],
};

/// Descriptor for `BenchmarkServersRequest`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per FEATURE-PLAN.md F2 spec (pending Go protoc codegen).
final $typed_data.Uint8List benchmarkServersRequestDescriptor =
    $convert.base64Decode(
        'ChdCZW5jaG1hcmtTZXJ2ZXJzUmVxdWVzdBI5CgthcGlfdmVyc2lvbhgBIAEoCzIYLnNvcmEuY29y'
        'ZS52MS5BcGlWZXJzaW9uUgphcGlWZXJzaW9uEjMKFWNvbnRyb2xfYXV0aGVudGljYXRvchgCIAEo'
        'DFIUY29udHJvbEF1dGhlbnRpY2F0b3ISHQoKcmVxdWVzdF9pZBgDIAEoCVIJcmVxdWVzdElkEh0K'
        'CnNlcnZlcl9pZHMYBCADKAlSCXNlcnZlcklkcxIdCgpkdXJhdGlvbl9zGAUgASgNUglkdXJhdGlv'
        'blMSIAoLY29uY3VycmVuY3kYBiABKA1SC2NvbmN1cnJlbmN5EhAKA3VybBgHIAEoCVIDdXJs');

const BandwidthSample$json = {
  '1': 'BandwidthSample',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'bytes_per_sec', '3': 2, '4': 1, '5': 4, '10': 'bytesPerSec'},
    {'1': 'progress_pct', '3': 3, '4': 1, '5': 13, '10': 'progressPct'},
    {'1': 'done', '3': 4, '4': 1, '5': 8, '10': 'done'},
    {'1': 'error', '3': 5, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `BandwidthSample`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per FEATURE-PLAN.md F2 spec (pending Go protoc codegen).
final $typed_data.Uint8List bandwidthSampleDescriptor =
    $convert.base64Decode(
        'Cg9CYW5kd2lkdGhTYW1wbGUSGwoJc2VydmVyX2lkGAEgASgJUghzZXJ2ZXJJZBIiCg1ieXRlc19w'
        'ZXJfc2VjGAIgASgEUgtieXRlc1BlclNlYxIhCgxwcm9ncmVzc19wY3QYAyABKA1SC3Byb2dyZXNz'
        'UGN0EhIKBGRvbmUYBCABKAhSBGRvbmUSLQoFZXJyb3IYBSABKAsyFy5zb3JhLmNvcmUudjEuU29y'
        'YUVycm9yUgVlcnJvcg==');

const GetBenchmarksRequest$json = {
  '1': 'GetBenchmarksRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'server_ids', '3': 3, '4': 3, '5': 9, '10': 'serverIds'},
  ],
};

/// Descriptor for `GetBenchmarksRequest`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List getBenchmarksRequestDescriptor =
    $convert.base64Decode(
        'ChRHZXRCZW5jaG1hcmtzUmVxdWVzdBI5CgthcGlfdmVyc2lvbhgBIAEoCzIYLnNvcmEuY29yZS52'
        'MS5BcGlWZXJzaW9uUgphcGlWZXJzaW9uEjMKFWNvbnRyb2xfYXV0aGVudGljYXRvchgCIAEoDFIU'
        'Y29udHJvbEF1dGhlbnRpY2F0b3ISHQoKc2VydmVyX2lkcxgDIAMoCVIJc2VydmVySWRz');

const GetBenchmarksResponse$json = {
  '1': 'GetBenchmarksResponse',
  '2': [
    {'1': 'benchmarks', '3': 1, '4': 3, '5': 11, '6': '.sora.core.v1.BenchmarkRecord', '10': 'benchmarks'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `GetBenchmarksResponse`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List getBenchmarksResponseDescriptor =
    $convert.base64Decode(
        'ChVHZXRCZW5jaG1hcmtzUmVzcG9uc2USPQoKYmVuY2htYXJrcxgBIAMoCzIdLnNvcmEuY29yZS52'
        'MS5CZW5jaG1hcmtSZWNvcmRSCmJlbmNobWFya3MSLQoFZXJyb3IYAiABKAsyFy5zb3JhLmNvcmUu'
        'djEuU29yYUVycm9yUgVlcnJvcg==');

const BenchmarkRecord$json = {
  '1': 'BenchmarkRecord',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'bytes_per_sec', '3': 2, '4': 1, '5': 4, '10': 'bytesPerSec'},
    {'1': 'latency_ms', '3': 3, '4': 1, '5': 13, '10': 'latencyMs'},
    {'1': 'measured_at_unix', '3': 4, '4': 1, '5': 3, '10': 'measuredAtUnix'},
  ],
};

/// Descriptor for `BenchmarkRecord`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List benchmarkRecordDescriptor =
    $convert.base64Decode(
        'Cg9CZW5jaG1hcmtSZWNvcmQSGwoJc2VydmVyX2lkGAEgASgJUghzZXJ2ZXJJZBIiCg1ieXRlc19w'
        'ZXJfc2VjGAIgASgEUgtieXRlc1BlclNlYxIdCgpsYXRlbmN5X21zGAMgASgNUglsYXRlbmN5TXMS'
        'KAoQbWVhc3VyZWRfYXRfdW5peBgEIAEoA1IObWVhc3VyZWRBdFVuaXg=');

const SaveSubscriptionOverrideRequest$json = {
  '1': 'SaveSubscriptionOverrideRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'subscription_id', '3': 3, '4': 1, '5': 9, '10': 'subscriptionId'},
    {'1': 'renames', '3': 4, '4': 3, '5': 11, '6': '.sora.core.v1.SaveSubscriptionOverrideRequest.RenamesEntry', '10': 'renames'},
    {'1': 'hidden', '3': 5, '4': 3, '5': 9, '10': 'hidden'},
    {'1': 'pinned_order', '3': 6, '4': 3, '5': 9, '10': 'pinnedOrder'},
    {'1': 'clear', '3': 7, '4': 1, '5': 8, '10': 'clear'},
  ],
};

/// Descriptor for `SaveSubscriptionOverrideRequest`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List saveSubscriptionOverrideRequestDescriptor =
    $convert.base64Decode(
        'Ch9TYXZlU3Vic2NyaXB0aW9uT3ZlcnJpZGVSZXF1ZXN0EjkKC2FwaV92ZXJzaW9uGAEgASgLMhgu'
        'c29yYS5jb3JlLnYxLkFwaVZlcnNpb25SCmFwaVZlcnNpb24SMwoVY29udHJvbF9hdXRoZW50aWNh'
        'dG9yGAIgASgMUhRjb250cm9sQXV0aGVudGljYXRvchInCg9zdWJzY3JpcHRpb25faWQYAyABKAlS'
        'DnN1YnNjcmlwdGlvbklkElQKB3JlbmFtZXMYBCADKAsyOi5zb3JhLmNvcmUudjEuU2F2ZVN1YnNj'
        'cmlwdGlvbk92ZXJyaWRlUmVxdWVzdC5SZW5hbWVzRW50cnlSB3JlbmFtZXMSFgoGaGlkZGVuGAUg'
        'AygJUgZoaWRkZW4SIQoMcGlubmVkX29yZGVyGAYgAygJUgtwaW5uZWRPcmRlchIUCgVjbGVhchgH'
        'IAEoCFIFY2xlYXIaNgoMUmVuYW1lc0VudHJ5EhAKA2tleRgBIAEoCVIDa2V5EhQKBXZhbHVlGAIg'
        'ASgJUgV2YWx1ZQ==');

const SaveSubscriptionOverrideResponse$json = {
  '1': 'SaveSubscriptionOverrideResponse',
  '2': [
    {'1': 'error', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
    {'1': 'state', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SubscriptionState', '10': 'state'},
  ],
};

/// Descriptor for `SaveSubscriptionOverrideResponse`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List saveSubscriptionOverrideResponseDescriptor =
    $convert.base64Decode(
        'CiBTYXZlU3Vic2NyaXB0aW9uT3ZlcnJpZGVSZXNwb25zZRItCgVlcnJvchgBIAEoCzIXLnNvcmEu'
        'Y29yZS52MS5Tb3JhRXJyb3JSBWVycm9yEjUKBXN0YXRlGAIgASgLMh8uc29yYS5jb3JlLnYxLlN1'
        'YnNjcmlwdGlvblN0YXRlUgVzdGF0ZQ==');

const GetSubscriptionOverrideRequest$json = {
  '1': 'GetSubscriptionOverrideRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'subscription_id', '3': 3, '4': 1, '5': 9, '10': 'subscriptionId'},
  ],
};

/// Descriptor for `GetSubscriptionOverrideRequest`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List getSubscriptionOverrideRequestDescriptor =
    $convert.base64Decode(
        'Ch5HZXRTdWJzY3JpcHRpb25PdmVycmlkZVJlcXVlc3QSOQoLYXBpX3ZlcnNpb24YASABKAsyGC5z'
        'b3JhLmNvcmUudjEuQXBpVmVyc2lvblIKYXBpVmVyc2lvbhIzChVjb250cm9sX2F1dGhlbnRpY2F0'
        'b3IYAiABKAxSFGNvbnRyb2xBdXRoZW50aWNhdG9yEicKD3N1YnNjcmlwdGlvbl9pZBgDIAEoCVIO'
        'c3Vic2NyaXB0aW9uSWQ=');

const GetSubscriptionOverrideResponse$json = {
  '1': 'GetSubscriptionOverrideResponse',
  '2': [
    {'1': 'renames', '3': 1, '4': 3, '5': 11, '6': '.sora.core.v1.GetSubscriptionOverrideResponse.RenamesEntry', '10': 'renames'},
    {'1': 'hidden', '3': 2, '4': 3, '5': 9, '10': 'hidden'},
    {'1': 'pinned_order', '3': 3, '4': 3, '5': 9, '10': 'pinnedOrder'},
    {'1': 'extra_rules', '3': 4, '4': 3, '5': 11, '6': '.sora.core.v1.OverrideRule', '10': 'extraRules'},
    {'1': 'error', '3': 5, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
    {'1': 'provider_routing', '3': 6, '4': 3, '5': 11, '6': '.sora.core.v1.OverrideRule', '10': 'providerRouting'},
  ],
};

/// Descriptor for `GetSubscriptionOverrideResponse`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List getSubscriptionOverrideResponseDescriptor =
    $convert.base64Decode(
        'Ch9HZXRTdWJzY3JpcHRpb25PdmVycmlkZVJlc3BvbnNlElQKB3JlbmFtZXMYASADKAsyOi5zb3Jh'
        'LmNvcmUudjEuR2V0U3Vic2NyaXB0aW9uT3ZlcnJpZGVSZXNwb25zZS5SZW5hbWVzRW50cnlSB3Jl'
        'bmFtZXMSFgoGaGlkZGVuGAIgAygJUgZoaWRkZW4SIQoMcGlubmVkX29yZGVyGAMgAygJUgtwaW5u'
        'ZWRPcmRlchI7CgtleHRyYV9ydWxlcxgEIAMoCzIaLnNvcmEuY29yZS52MS5PdmVycmlkZVJ1bGVS'
        'CmV4dHJhUnVsZXMSLQoFZXJyb3IYBSABKAsyFy5zb3JhLmNvcmUudjEuU29yYUVycm9yUgVlcnJv'
        'chJFChBwcm92aWRlcl9yb3V0aW5nGAYgAygLMhouc29yYS5jb3JlLnYxLk92ZXJyaWRlUnVsZVIP'
        'cHJvdmlkZXJSb3V0aW5nGjgKDFJlbmFtZXNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1'
        'ZRgCIAEoCVIFdmFsdWU6AA=='
);

const OverrideRule$json = {
  '1': 'OverrideRule',
  '2': [
    {'1': 'destination', '3': 1, '4': 1, '5': 9, '10': 'destination'},
    {'1': 'outbound_id', '3': 2, '4': 1, '5': 9, '10': 'outboundId'},
  ],
};

/// Descriptor for `OverrideRule`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List overrideRuleDescriptor =
    $convert.base64Decode(
        'CgxPdmVycmlkZVJ1bGUSIAoLZGVzdGluYXRpb24YASABKAlSC2Rlc3RpbmF0aW9uEh8KC291dGJv'
        'dW5kX2lkGAIgASgJUgpvdXRib3VuZElk');

const ProfileMatched$json = {
  '1': 'ProfileMatched',
  '2': [
    {'1': 'profile_id', '3': 1, '4': 1, '5': 9, '10': 'profileId'},
    {'1': 'profile_name', '3': 2, '4': 1, '5': 9, '10': 'profileName'},
    {'1': 'auto_apply', '3': 3, '4': 1, '5': 8, '10': 'autoApply'},
  ],
};

/// Descriptor for `ProfileMatched`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List profileMatchedDescriptor =
    $convert.base64Decode(
        'Cg5Qcm9maWxlTWF0Y2hlZBIdCgpwcm9maWxlX2lkGAEgASgJUglwcm9maWxlSWQSIQoMcHJvZmls'
        'ZV9uYW1lGAIgASgJUgtwcm9maWxlTmFtZRIdCgphdXRvX2FwcGx5GAMgASgIUglhdXRvQXBwbHk=');

const NetworkProfile$json = {
  '1': 'NetworkProfile',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'triggers', '3': 3, '4': 1, '5': 11, '6': '.sora.core.v1.ProfileTriggers', '10': 'triggers'},
    {'1': 'apply', '3': 4, '4': 1, '5': 11, '6': '.sora.core.v1.ProfileApply', '10': 'apply'},
    {'1': 'auto_apply', '3': 5, '4': 1, '5': 8, '10': 'autoApply'},
  ],
};

/// Descriptor for `NetworkProfile`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List networkProfileDescriptor =
    $convert.base64Decode(
        'Cg5OZXR3b3JrUHJvZmlsZRIOCgJpZBgBIAEoCVICaWQSEgoEbmFtZRgCIAEoCVIEbmFtZRI5Cgh0'
        'cmlnZ2VycxgDIAEoCzIdLnNvcmEuY29yZS52MS5Qcm9maWxlVHJpZ2dlcnNSCHRyaWdnZXJzEjAK'
        'BWFwcGx5GAQgASgLMhouc29yYS5jb3JlLnYxLlByb2ZpbGVBcHBseVIFYXBwbHkSHQoKYXV0b19h'
        'cHBseRgFIAEoCFIJYXV0b0FwcGx5');

const ProfileTriggers$json = {
  '1': 'ProfileTriggers',
  '2': [
    {'1': 'ssids', '3': 1, '4': 3, '5': 9, '10': 'ssids'},
    {'1': 'gateways', '3': 2, '4': 3, '5': 9, '10': 'gateways'},
    {'1': 'asns', '3': 3, '4': 3, '5': 9, '10': 'asns'},
  ],
};

/// Descriptor for `ProfileTriggers`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List profileTriggersDescriptor =
    $convert.base64Decode(
        'Cg9Qcm9maWxlVHJpZ2dlcnMSFAoFc3NpZHMYASADKAlSBXNzaWRzEhoKCGdhdGV3YXlzGAIgAygJ'
        'UghnYXRld2F5cxISCgRhc25zGAMgAygJUgRhc25z');

const ProfileApply$json = {
  '1': 'ProfileApply',
  '2': [
    {'1': 'mode', '3': 1, '4': 1, '5': 9, '10': 'mode'},
    {'1': 'dns', '3': 2, '4': 3, '5': 9, '10': 'dns'},
    {'1': 'rules_preset', '3': 3, '4': 1, '5': 9, '10': 'rulesPreset'},
    {'1': 'server_id', '3': 4, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'engine', '3': 5, '4': 1, '5': 9, '10': 'engine'},
  ],
};

/// Descriptor for `ProfileApply`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List profileApplyDescriptor =
    $convert.base64Decode(
        'CgxQcm9maWxlQXBwbHkSEgoEbW9kZRgBIAEoCVIEbW9kZRIQCgNkbnMYAiADKAlSA2RucxIhCgxy'
        'dWxlc19wcmVzZXQYAyABKAlSC3J1bGVzUHJlc2V0EhsKCXNlcnZlcl9pZBgEIAEoCVIIc2VydmVy'
        'SWQSFgoGZW5naW5lGAUgASgJUgZlbmdpbmU=');

const ListProfilesRequest$json = {
  '1': 'ListProfilesRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
  ],
};

/// Descriptor for `ListProfilesRequest`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List listProfilesRequestDescriptor =
    $convert.base64Decode(
        'ChNMaXN0UHJvZmlsZXNSZXF1ZXN0EjkKC2FwaV92ZXJzaW9uGAEgASgLMhguc29yYS5jb3JlLnYx'
        'LkFwaVZlcnNpb25SCmFwaVZlcnNpb24SMwoVY29udHJvbF9hdXRoZW50aWNhdG9yGAIgASgMUhRj'
        'b250cm9sQXV0aGVudGljYXRvcg==');

const ListProfilesResponse$json = {
  '1': 'ListProfilesResponse',
  '2': [
    {'1': 'profiles', '3': 1, '4': 3, '5': 11, '6': '.sora.core.v1.NetworkProfile', '10': 'profiles'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `ListProfilesResponse`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List listProfilesResponseDescriptor =
    $convert.base64Decode(
        'ChRMaXN0UHJvZmlsZXNSZXNwb25zZRI4Cghwcm9maWxlcxgBIAMoCzIcLnNvcmEuY29yZS52MS5O'
        'ZXR3b3JrUHJvZmlsZVIIcHJvZmlsZXMSLQoFZXJyb3IYAiABKAsyFy5zb3JhLmNvcmUudjEuU29y'
        'YUVycm9yUgVlcnJvcg==');

const SaveProfileRequest$json = {
  '1': 'SaveProfileRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'profile', '3': 3, '4': 1, '5': 11, '6': '.sora.core.v1.NetworkProfile', '10': 'profile'},
  ],
};

/// Descriptor for `SaveProfileRequest`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List saveProfileRequestDescriptor =
    $convert.base64Decode(
        'ChJTYXZlUHJvZmlsZVJlcXVlc3QSOQoLYXBpX3ZlcnNpb24YASABKAsyGC5zb3JhLmNvcmUudjEu'
        'QXBpVmVyc2lvblIKYXBpVmVyc2lvbhIzChVjb250cm9sX2F1dGhlbnRpY2F0b3IYAiABKAxSFGNv'
        'bnRyb2xBdXRoZW50aWNhdG9yEjYKB3Byb2ZpbGUYAyABKAsyHC5zb3JhLmNvcmUudjEuTmV0d29y'
        'a1Byb2ZpbGVSB3Byb2ZpbGU=');

const SaveProfileResponse$json = {
  '1': 'SaveProfileResponse',
  '2': [
    {'1': 'profile', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.NetworkProfile', '10': 'profile'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `SaveProfileResponse`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List saveProfileResponseDescriptor =
    $convert.base64Decode(
        'ChNTYXZlUHJvZmlsZVJlc3BvbnNlEjYKB3Byb2ZpbGUYASABKAsyHC5zb3JhLmNvcmUudjEuTmV0'
        'd29ya1Byb2ZpbGVSB3Byb2ZpbGUSLQoFZXJyb3IYAiABKAsyFy5zb3JhLmNvcmUudjEuU29yYUVy'
        'cm9yUgVlcnJvcg==');

const DeleteProfileRequest$json = {
  '1': 'DeleteProfileRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'profile_id', '3': 3, '4': 1, '5': 9, '10': 'profileId'},
  ],
};

/// Descriptor for `DeleteProfileRequest`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List deleteProfileRequestDescriptor =
    $convert.base64Decode(
        'ChREZWxldGVQcm9maWxlUmVxdWVzdBI5CgthcGlfdmVyc2lvbhgBIAEoCzIYLnNvcmEuY29yZS52'
        'MS5BcGlWZXJzaW9uUgphcGlWZXJzaW9uEjMKFWNvbnRyb2xfYXV0aGVudGljYXRvchgCIAEoDFIU'
        'Y29udHJvbEF1dGhlbnRpY2F0b3ISHQoKcHJvZmlsZV9pZBgDIAEoCVIJcHJvZmlsZUlk');

const DeleteProfileResponse$json = {
  '1': 'DeleteProfileResponse',
  '2': [
    {'1': 'error', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `DeleteProfileResponse`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List deleteProfileResponseDescriptor =
    $convert.base64Decode(
        'ChVEZWxldGVQcm9maWxlUmVzcG9uc2USLQoFZXJyb3IYASABKAsyFy5zb3JhLmNvcmUudjEuU29y'
        'YUVycm9yUgVlcnJvcg==');

const GetNetworkFingerprintRequest$json = {
  '1': 'GetNetworkFingerprintRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
  ],
};

/// Descriptor for `GetNetworkFingerprintRequest`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List getNetworkFingerprintRequestDescriptor =
    $convert.base64Decode(
        'ChxHZXROZXR3b3JrRmluZ2VycHJpbnRSZXF1ZXN0EjkKC2FwaV92ZXJzaW9uGAEgASgLMhguc29y'
        'YS5jb3JlLnYxLkFwaVZlcnNpb25SCmFwaVZlcnNpb24SMwoVY29udHJvbF9hdXRoZW50aWNhdG9y'
        'GAIgASgMUhRjb250cm9sQXV0aGVudGljYXRvcg==');

const GetNetworkFingerprintResponse$json = {
  '1': 'GetNetworkFingerprintResponse',
  '2': [
    {'1': 'fingerprint', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.NetworkFingerprint', '10': 'fingerprint'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `GetNetworkFingerprintResponse`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List getNetworkFingerprintResponseDescriptor =
    $convert.base64Decode(
        'Ch1HZXROZXR3b3JrRmluZ2VycHJpbnRSZXNwb25zZRJCCgtmaW5nZXJwcmludBgBIAEoCzIgLnNv'
        'cmEuY29yZS52MS5OZXR3b3JrRmluZ2VycHJpbnRSC2ZpbmdlcnByaW50Ei0KBWVycm9yGAIgASgL'
        'Mhcuc29yYS5jb3JlLnYxLlNvcmFFcnJvclIFZXJyb3I=');

const NetworkFingerprint$json = {
  '1': 'NetworkFingerprint',
  '2': [
    {'1': 'ssid', '3': 1, '4': 1, '5': 9, '10': 'ssid'},
    {'1': 'gateway', '3': 2, '4': 1, '5': 9, '10': 'gateway'},
    {'1': 'asn', '3': 3, '4': 1, '5': 9, '10': 'asn'},
    {'1': 'fingerprint', '3': 4, '4': 1, '5': 9, '10': 'fingerprint'},
  ],
};

/// Descriptor for `NetworkFingerprint`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List networkFingerprintDescriptor =
    $convert.base64Decode(
        'ChJOZXR3b3JrRmluZ2VycHJpbnQSEgoEc3NpZBgBIAEoCVIEc3NpZBIYCgdnYXRld2F5GAIgASgJ'
        'UgdnYXRld2F5EhAKA2FzbhgDIAEoCVIDYXNuEiAKC2ZpbmdlcnByaW50GAQgASgJUgtmaW5nZXJw'
        'cmludA==');

const ProbeChainRequest$json = {
  '1': 'ProbeChainRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'control_authenticator', '3': 2, '4': 1, '5': 12, '10': 'controlAuthenticator'},
    {'1': 'request_id', '3': 3, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'server_ids', '3': 4, '4': 3, '5': 9, '10': 'serverIds'},
  ],
};

/// Descriptor for `ProbeChainRequest`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List probeChainRequestDescriptor =
    $convert.base64Decode(
        'ChFQcm9iZUNoYWluUmVxdWVzdBI5CgthcGlfdmVyc2lvbhgBIAEoCzIYLnNvcmEuY29yZS52MS5B'
        'cGlWZXJzaW9uUgphcGlWZXJzaW9uEjMKFWNvbnRyb2xfYXV0aGVudGljYXRvchgCIAEoDFIUY29u'
        'dHJvbEF1dGhlbnRpY2F0b3ISHQoKcmVxdWVzdF9pZBgDIAEoCVIJcmVxdWVzdElkEh0KCnNlcnZl'
        'cl9pZHMYBCADKAlSCXNlcnZlcklkcw==');

const ProbeChainResponse$json = {
  '1': 'ProbeChainResponse',
  '2': [
    {'1': 'hops', '3': 1, '4': 3, '5': 11, '6': '.sora.core.v1.ChainHop', '10': 'hops'},
    {'1': 'total_latency_ms', '3': 2, '4': 1, '5': 13, '10': 'totalLatencyMs'},
    {'1': 'engines', '3': 3, '4': 3, '5': 9, '10': 'engines'},
    {'1': 'error', '3': 4, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `ProbeChainResponse`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List probeChainResponseDescriptor =
    $convert.base64Decode(
        'ChJQcm9iZUNoYWluUmVzcG9uc2USKgoEaG9wcxgBIAMoCzIWLnNvcmEuY29yZS52MS5DaGFpbkhv'
        'cFIEaG9wcxIoChB0b3RhbF9sYXRlbmN5X21zGAIgASgNUg50b3RhbExhdGVuY3lNcxIYCgdlbmdp'
        'bmVzGAMgAygJUgdlbmdpbmVzEi0KBWVycm9yGAQgASgLMhcuc29yYS5jb3JlLnYxLlNvcmFFcnJv'
        'clIFZXJyb3I=');

const ChainHop$json = {
  '1': 'ChainHop',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'reachable', '3': 2, '4': 1, '5': 8, '10': 'reachable'},
    {'1': 'latency_ms', '3': 3, '4': 1, '5': 13, '10': 'latencyMs'},
  ],
};

/// Descriptor for `ChainHop`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per detail-hunt D42 (pending protoc-gen-dart codegen).
final $typed_data.Uint8List chainHopDescriptor =
    $convert.base64Decode(
        'CghDaGFpbkhvcBIbCglzZXJ2ZXJfaWQYASABKAlSCHNlcnZlcklkEhwKCXJlYWNoYWJsZRgCIAEo'
        'CFIJcmVhY2hhYmxlEh0KCmxhdGVuY3lfbXMYAyABKA1SCWxhdGVuY3lNcw==');

@$core.Deprecated('Use censorshipDetectedDescriptor instead')
const CensorshipDetected$json = {
  '1': 'CensorshipDetected',
  '2': [
    {'1': 'kind', '3': 1, '4': 1, '5': 9, '10': 'kind'},
    {'1': 'confidence', '3': 2, '4': 1, '5': 1, '10': 'confidence'},
    {'1': 'explanation', '3': 3, '4': 1, '5': 9, '10': 'explanation'},
    {'1': 'evidence', '3': 4, '4': 3, '5': 9, '10': 'evidence'},
  ],
};

/// Descriptor for `CensorshipDetected`. Decode as a `google.protobuf.DescriptorProto`.
/// HAND-WRITTEN per SW4 fix (pending protoc-gen-dart codegen); bytes match
/// core/gen/sora/core/v1 descriptor for the same message.
final $typed_data.Uint8List censorshipDetectedDescriptor =
    $convert.base64Decode(
        'ChJDZW5zb3JzaGlwRGV0ZWN0ZWQSEgoEa2luZBgBIAEoCVIEa2luZBIeCgpjb25maWRlbmNlGAIg'
        'ASgBUgpjb25maWRlbmNlEiAKC2V4cGxhbmF0aW9uGAMgASgJUgtleHBsYW5hdGlvbhIaCghldmlk'
        'ZW5jZRgEIAMoCVIIZXZpZGVuY2U='
    );
