// Pins the client's declared API version (M2): the Dart client speaks
// contract 1.14 — the Anti-DPI ExtensionHost bypass seam — matching
// the core's served version in core/cmd/sora-core/main.go (whose
// version_test.go pins the Go side and the negotiation outcomes,
// including a 1.13 client still negotiating down to 13).

import 'package:flutter_test/flutter_test.dart';
import 'package:sora/src/core/link.dart';

void main() {
  test('apiVersion declares contract 1.14', () {
    expect(apiVersion.major, 1);
    expect(apiVersion.minor, 14);
    // Unchanged by the bump: the client still works with cores back
    // to 1.6, and every feature gate keys off the *negotiated* minor
    // with a "< threshold" check, so offering 14 enables nothing but
    // the 1.14 surface against a 1.14 core.
    expect(apiVersion.minSupportedMinor, 6);
  });
}
