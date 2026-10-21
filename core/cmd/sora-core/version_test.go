// Package main wires the sora-core service binary.
package main

import (
	"testing"

	"github.com/levvs-one/sora-client/core/control"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

// TestVersionContract pins the wire API version this build serves. Bumping it
// is a deliberate, reviewed act: the Dart client declares its own version in
// app/lib/src/core/link.dart and the minor numbers must agree, because the
// handshake negotiates the highest common minor and rejects mismatches. The
// Dart side carries a higher minSupportedMinor (it drops older cores faster);
// the core stays liberal here so old builds keep serving while clients move
// on.
//
// 1.14 is the Anti-DPI seam: the ExtensionHost bypass RPCs the proto
// and the registry already described as "Since 1.14" ship in this
// build, so the served minor finally matches them (M2).
func TestVersionContract(t *testing.T) {
	want := control.Version{Major: 1, Minor: 14, MinSupportedMinor: 1}
	if Version != want {
		t.Fatalf("served API version = %v, want %v (keep in sync with app/lib/src/core/link.dart)", Version, want)
	}

	// Positive case: the current Dart client (1.14, supports back to 1.6)
	// must negotiate successfully with this build.
	dart := &corev1.ApiVersion{Major: 1, Minor: 14, MinSupportedMinor: 6}
	core := &corev1.ApiVersion{Major: Version.Major, Minor: Version.Minor, MinSupportedMinor: Version.MinSupportedMinor}
	got, err := control.Negotiate(dart, core)
	if err != nil {
		t.Fatalf("Negotiate(current Dart client, core) failed: %v", err)
	}
	if got != 14 {
		t.Fatalf("Negotiate(current Dart client, core) = %d, want 14", got)
	}

	// The previous client (1.13) still negotiates down to 13: the bump
	// adds the 1.14 surface without switching any older feature gate
	// (every Dart gate is a "< threshold" check on the negotiated
	// minor, and the core has no minor gates beyond Negotiate).
	old := &corev1.ApiVersion{Major: 1, Minor: 13, MinSupportedMinor: 6}
	got, err = control.Negotiate(old, core)
	if err != nil {
		t.Fatalf("Negotiate(1.13 Dart client, core) failed: %v", err)
	}
	if got != 13 {
		t.Fatalf("Negotiate(1.13 Dart client, core) = %d, want 13", got)
	}

	// Negative case: a client from a different major must be rejected.
	future := &corev1.ApiVersion{Major: 2, Minor: 0, MinSupportedMinor: 0}
	if _, err := control.Negotiate(future, core); err == nil {
		t.Fatal("Negotiate(major 2 client, core) succeeded, want a version mismatch error")
	}
}
