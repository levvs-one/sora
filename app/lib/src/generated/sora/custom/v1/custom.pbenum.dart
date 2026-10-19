// Hand-written stubs for sora/custom/v1/custom.proto.
//
// protoc is unavailable in this environment, so this enum mirrors the
// protoc-gen-dart output by hand and follows the layout of the generated
// sora/core/v1 files. Replace with real generated code once the proto lands.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

const $core.bool _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');

/// CustomProtocol lists the protocols a manually added server may use.
/// Wire contract (must match proto/sora/custom/v1/custom.proto):
///   CUSTOM_PROTOCOL_UNSPECIFIED = 0
///   CUSTOM_PROTOCOL_VLESS = 1
///   CUSTOM_PROTOCOL_VMESS = 2
///   CUSTOM_PROTOCOL_TROJAN = 3
///   CUSTOM_PROTOCOL_SHADOWSOCKS = 4
///   CUSTOM_PROTOCOL_WIREGUARD = 5
class CustomProtocol extends $pb.ProtobufEnum {
  static const CustomProtocol CUSTOM_PROTOCOL_UNSPECIFIED =
      CustomProtocol._(0, _omitEnumNames ? '' : 'CUSTOM_PROTOCOL_UNSPECIFIED');
  static const CustomProtocol CUSTOM_PROTOCOL_VLESS =
      CustomProtocol._(1, _omitEnumNames ? '' : 'CUSTOM_PROTOCOL_VLESS');
  static const CustomProtocol CUSTOM_PROTOCOL_VMESS =
      CustomProtocol._(2, _omitEnumNames ? '' : 'CUSTOM_PROTOCOL_VMESS');
  static const CustomProtocol CUSTOM_PROTOCOL_TROJAN =
      CustomProtocol._(3, _omitEnumNames ? '' : 'CUSTOM_PROTOCOL_TROJAN');
  static const CustomProtocol CUSTOM_PROTOCOL_SHADOWSOCKS =
      CustomProtocol._(4, _omitEnumNames ? '' : 'CUSTOM_PROTOCOL_SHADOWSOCKS');
  static const CustomProtocol CUSTOM_PROTOCOL_WIREGUARD =
      CustomProtocol._(5, _omitEnumNames ? '' : 'CUSTOM_PROTOCOL_WIREGUARD');

  static const $core.List<CustomProtocol> values = <CustomProtocol>[
    CUSTOM_PROTOCOL_UNSPECIFIED,
    CUSTOM_PROTOCOL_VLESS,
    CUSTOM_PROTOCOL_VMESS,
    CUSTOM_PROTOCOL_TROJAN,
    CUSTOM_PROTOCOL_SHADOWSOCKS,
    CUSTOM_PROTOCOL_WIREGUARD,
  ];

  static final $core.List<CustomProtocol?> _byValue = $pb.ProtobufEnum.$_initByValueList(values, 5);
  static CustomProtocol? valueOf($core.int value) => value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CustomProtocol._(super.value, super.name);
}
