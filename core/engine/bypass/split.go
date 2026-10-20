package bypass

import (
	"fmt"
	"strconv"
	"strings"
)

// Precise split-position tuning (T031).
//
// A fixed --split-pos like "1" or "2" cuts at a byte offset from the start
// of the ClientHello. That is blind: the SNI sits at a variable offset
// (cipher suites, extensions and session IDs have variable lengths), so a
// fixed cut may land before the SNI, inside uninteresting bytes, or past
// it entirely — and any change of the uTLS fingerprint moves everything.
//
// tpws resolves the "sniext" marker at runtime by parsing the actual
// ClientHello bytes (see TLSFindExt in the vendored tpws/protocol.c), so a
// marker-based split is fingerprint-agnostic: uTLS reordering extensions
// or REALITY's real handshake do not move it, because the marker is found
// in the bytes on the wire, not assumed. MidSNISplit computes the offset
// that lands the cut in the middle of the hostname for a given SNI.
//
// SNI extension layout from the marker (extension header):
//
//	ext[0:2]  extension type (0x0000)
//	ext[2:4]  extension_data length
//	ext[4:6]  server_name_list length
//	ext[6]    name_type (0 = host_name)
//	ext[7:9]  hostname length
//	ext[9:]   hostname
//
// so the middle of the hostname is at marker + 9 + len(hostname)/2.

// sniExtHeaderLen is the bytes before the hostname inside the SNI
// extension: type + ext length + list length + name type + name length.
const sniExtHeaderLen = 9

// MidSNISplit returns a --split-pos value that cuts the ClientHello in the
// middle of the SNI hostname, e.g. "sniext+14" for "example.com". The sni
// must be the wire-format (ASCII) hostname that will actually be sent; a
// mismatch of a few bytes still lands inside the extension, but garbage in
// gives a garbage cut, so malformed input is refused rather than guessed.
//
// Wired: ResolveStrategy (resolve.go) resolves the MidSNIMarker
// split position through this function against the target SNI, and the
// result flows into both arg builders (tpws --split-pos and nfqws
// --dpi-desync-split-pos share the position syntax).
func MidSNISplit(sni string) (string, error) {
	if sni == "" {
		return "", fmt.Errorf("bypass: cannot align a split to an empty SNI")
	}
	if len(sni) > 253 {
		return "", fmt.Errorf("bypass: SNI %q is longer than 253 bytes", sni)
	}
	for _, c := range sni {
		if c > 127 || c < 33 {
			return "", fmt.Errorf("bypass: SNI %q is not a wire-format hostname", sni)
		}
	}
	// A trailing dot is legal on the wire but the ClientHello SNI never
	// carries one; normalize so the midpoint math matches the bytes.
	sni = strings.TrimSuffix(sni, ".")
	if sni == "" {
		return "", fmt.Errorf("bypass: cannot align a split to an empty SNI")
	}
	cut := sniExtHeaderLen + len(sni)/2
	return "sniext+" + strconv.Itoa(cut), nil
}
