// This is a generated file - do not edit.
//
// Generated from sora/obfs/v1/obfs.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class UtlsProfile extends $pb.ProtobufEnum {
  /// Reserved for obfs.
  static const UtlsProfile UTLS_PROFILE_UNSPECIFIED =
      UtlsProfile._(0, _omitEnumNames ? '' : 'UTLS_PROFILE_UNSPECIFIED');

  static const $core.List<UtlsProfile> values = <UtlsProfile>[
    UTLS_PROFILE_UNSPECIFIED,
  ];

  static final $core.List<UtlsProfile?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 0);
  static UtlsProfile? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const UtlsProfile._(super.value, super.name);
}

class ObfsPreset extends $pb.ProtobufEnum {
  /// Reserved for obfs.
  static const ObfsPreset OBFS_PRESET_UNSPECIFIED =
      ObfsPreset._(0, _omitEnumNames ? '' : 'OBFS_PRESET_UNSPECIFIED');

  static const $core.List<ObfsPreset> values = <ObfsPreset>[
    OBFS_PRESET_UNSPECIFIED,
  ];

  static final $core.List<ObfsPreset?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 0);
  static ObfsPreset? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const ObfsPreset._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
