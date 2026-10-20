// Obfuscation model and wire tests (sora.obfs.v1, hand-written stubs in
// lib/src/obfs.dart): the Light preset reaches the wire, and the
// mux_disabled axis (field 7) round-trips through ObfsSettings.

import 'package:flutter_test/flutter_test.dart';
import 'package:sora/src/obfs.dart';

ObfsSettings settingsOn(Map<String, String> store) =>
    ObfsSettings(() => store['obfs'] ?? '', (v) => store['obfs'] = v);

void main() {
  group('presets', () {
    test('light travels to the wire as OBFS_PRESET_LIGHT', () {
      final settings = settingsOn({});
      settings.applyPreset(obfsPresetLight);
      expect(settings.toProfile().preset, ObfsPreset.OBFS_PRESET_LIGHT);
    });

    test('every model preset maps to a wire preset or custom fields', () {
      final settings = settingsOn({});
      settings.applyPreset(obfsPresetBalanced);
      expect(settings.toProfile().preset, ObfsPreset.OBFS_PRESET_BALANCED);
      settings.applyPreset(obfsPresetAggressive);
      expect(settings.toProfile().preset, ObfsPreset.OBFS_PRESET_AGGRESSIVE);
      settings.applyPreset(obfsPresetOff);
      expect(settings.toProfile().preset, ObfsPreset.OBFS_PRESET_OFF);
    });
  });

  group('mux axis', () {
    test('muxDisabled persists and flips the profile custom', () {
      final store = <String, String>{};
      final settings = settingsOn(store);
      settings.applyPreset(obfsPresetBalanced);
      settings.muxDisabled = true;
      expect(settings.preset, obfsPresetCustom);
      expect(settingsOn(store).muxDisabled, isTrue);
    });

    test('a mux-only profile carries mux_disabled and nothing else', () {
      final settings = settingsOn({});
      settings.muxDisabled = true;
      final profile = settings.toProfile();
      expect(profile.muxDisabled, isTrue);
      expect(profile.preset, ObfsPreset.OBFS_PRESET_UNSPECIFIED);
      expect(profile.fragSizes, isEmpty);
    });

    test('mux_disabled rides along with a stored named preset', () {
      final store = <String, String>{
        'obfs': '{"preset":"balanced","utls":"","fragment":false,"jitter":false,"muxDisabled":true}',
      };
      final profile = settingsOn(store).toProfile();
      expect(profile.preset, ObfsPreset.OBFS_PRESET_BALANCED);
      expect(profile.muxDisabled, isTrue);
    });

    test('OFF never carries mux_disabled: it must arrive alone', () {
      final store = <String, String>{
        'obfs': '{"preset":"off","utls":"","fragment":false,"jitter":false,"muxDisabled":true}',
      };
      final profile = settingsOn(store).toProfile();
      expect(profile.preset, ObfsPreset.OBFS_PRESET_OFF);
      expect(profile.muxDisabled, isFalse);
    });

    test('mux_disabled is wire field 7, varint', () {
      final bytes = ObfuscationProfile(muxDisabled: true).writeToBuffer();
      // Tag (7 << 3) | 0 = 56, then the bool value.
      expect(bytes.sublist(0, 2), [56, 1]);
      expect(ObfuscationProfile.fromBuffer(bytes).muxDisabled, isTrue);
      // A buffer without the field decodes to the default policy (mux on).
      expect(ObfuscationProfile.fromBuffer(const []).muxDisabled, isFalse);
    });
  });
}
