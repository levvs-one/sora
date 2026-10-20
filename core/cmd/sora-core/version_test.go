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
func TestVersionContract(t *testing.T) {
	want := control.Version{Major: 1, Minor: 12, MinSupportedMinor: 1}
	if Version != want {
		t.Fatalf("served API version = %v, want %v (keep in sync with app/lib/src/core/link.dart)", Version, want)
	}

	// Positive case: the current Dart client (1.12, supports back to 1.6)
	// must negotiate successfully with this build.
	dart := &corev1.ApiVersion{Major: 1, Minor: 12, MinSupportedMinor: 6}
	core := &corev1.ApiVersion{Major: Version.Major, Minor: Version.Minor, MinSupportedMinor: Version.MinSupportedMinor}
	got, err := control.Negotiate(dart, core)
	if err != nil {
		t.Fatalf("Negotiate(current Dart client, core) failed: %v", err)
	}
	if got != 12 {
		t.Fatalf("Negotiate(current Dart client, core) = %d, want 12", got)
	}

	// Negative case: a client from a different major must be rejected.
	future := &corev1.ApiVersion{Major: 2, Minor: 0, MinSupportedMinor: 0}
	if _, err := control.Negotiate(future, core); err == nil {
		t.Fatal("Negotiate(major 2 client, core) succeeded, want a version mismatch error")
	}
}
