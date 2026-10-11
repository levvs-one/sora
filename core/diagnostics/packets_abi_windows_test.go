//go:build windows

package diagnostics

import (
	"testing"
	"unsafe"
)

func TestPacketMonitorWindowsABI(t *testing.T) {
	if got := unsafe.Offsetof(packetMetadata{}.Timestamp); got != 40 {
		t.Fatalf("LARGE_INTEGER offset = %d, Windows expects 40", got)
	}
	if got := unsafe.Sizeof(packetMetadata{}); got != 48 {
		t.Fatalf("packet metadata size = %d, Windows expects 48", got)
	}
	if got := unsafe.Offsetof(packetSource{}.Detail); got != 408 {
		t.Fatalf("source union offset = %d, Windows expects 408", got)
	}
	if got := unsafe.Sizeof(packetSource{}); got != 424 {
		t.Fatalf("source size = %d, Windows expects 424", got)
	}
}
