// This is a generated file - do not edit.
//
// Generated from sora/censor/v1/censor.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class CensorshipKind extends $pb.ProtobufEnum {
  /// Reserved for censor.
  static const CensorshipKind CENSORSHIP_KIND_UNSPECIFIED =
      CensorshipKind._(0, _omitEnumNames ? '' : 'CENSORSHIP_KIND_UNSPECIFIED');

  static const $core.List<CensorshipKind> values = <CensorshipKind>[
    CENSORSHIP_KIND_UNSPECIFIED,
  ];

  static final $core.List<CensorshipKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 0);
  static CensorshipKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const CensorshipKind._(super.value, super.name);
}

class AttemptStage extends $pb.ProtobufEnum {
  /// Reserved for censor.
  static const AttemptStage ATTEMPT_STAGE_UNSPECIFIED =
      AttemptStage._(0, _omitEnumNames ? '' : 'ATTEMPT_STAGE_UNSPECIFIED');

  static const $core.List<AttemptStage> values = <AttemptStage>[
    ATTEMPT_STAGE_UNSPECIFIED,
  ];

  static final $core.List<AttemptStage?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 0);
  static AttemptStage? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AttemptStage._(super.value, super.name);
}

class AttemptEventKind extends $pb.ProtobufEnum {
  /// Reserved for censor.
  static const AttemptEventKind ATTEMPT_EVENT_KIND_UNSPECIFIED =
      AttemptEventKind._(
          0, _omitEnumNames ? '' : 'ATTEMPT_EVENT_KIND_UNSPECIFIED');

  static const $core.List<AttemptEventKind> values = <AttemptEventKind>[
    ATTEMPT_EVENT_KIND_UNSPECIFIED,
  ];

  static final $core.List<AttemptEventKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 0);
  static AttemptEventKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AttemptEventKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
