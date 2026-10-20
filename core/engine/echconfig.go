package engine

import (
	"encoding/base64"
	"fmt"
	"strings"
)

// ECHConfigList handling as data (CENSOR-FP).
//
// A plan pins ECH as PEM lines (TLS.ECH.Config) — the shape sing-box
// takes. The three engines spell the same list three ways, all probed
// on the pinned binaries (2026-10-20, wire captures in
// reports/CENSOR-FP.md):
//
//   - sing-box wants PEM armor whose label is exactly "ECH CONFIGS":
//     the label sora used historically, "ECHCONFIG", makes the pinned
//     lx.22 binary refuse the whole config at startup ("invalid ECH
//     configs pem"). ECHConfigPEM canonicalizes to the probed label.
//   - mihomo wants ONE base64 string (ech-opts.config).
//   - Xray wants ONE base64 string (tlsSettings.echConfigList) — its
//     loader does not parse the list at config-test time (garbage is
//     accepted by `xray run -test`), but on the wire the pinned list
//     is real: the outer SNI becomes the list's public_name.
//
// Both helpers accept any armor label and bare base64 lines, and fail
// closed on data that is not a single ECHConfigList: two PEM blocks
// are two lists, and concatenating them is not a list.

// ECHConfigListBytes decodes a plan's pinned ECH config (PEM lines or
// bare base64) to the raw ECHConfigList bytes.
func ECHConfigListBytes(lines []string) ([]byte, error) {
	if len(lines) == 0 {
		return nil, nil
	}
	blocks, ends := 0, 0
	var body strings.Builder
	for _, ln := range lines {
		ln = strings.TrimSpace(ln)
		switch {
		case strings.HasPrefix(ln, "-----BEGIN"):
			blocks++
		case strings.HasPrefix(ln, "-----END"):
			ends++
		case ln == "":
			// Blank line: no payload.
		default:
			body.WriteString(ln)
		}
	}
	if blocks > 1 {
		return nil, fmt.Errorf("ech: %d pinned ECH configs cannot be merged into one ECHConfigList", blocks)
	}
	if blocks != ends {
		return nil, fmt.Errorf("ech: the pinned ECH config has unterminated PEM armor (%d BEGIN, %d END)", blocks, ends)
	}
	raw, err := base64.StdEncoding.DecodeString(body.String())
	if err != nil || len(raw) == 0 {
		return nil, fmt.Errorf("ech: the pinned ECH config is not PEM/base64 ECHConfigList data")
	}
	return raw, nil
}

// ECHConfigListBase64 renders the pinned list the way mihomo and Xray
// take it: one canonical base64 string.
func ECHConfigListBase64(lines []string) (string, error) {
	raw, err := ECHConfigListBytes(lines)
	if err != nil || len(raw) == 0 {
		return "", err
	}
	return base64.StdEncoding.EncodeToString(raw), nil
}

// ECHConfigPEM renders the pinned list the way sing-box takes it: PEM
// lines under the probed "ECH CONFIGS" label, wrapped at 64 columns.
// A plan whose armor used any other label is normalized here, at the
// renderer boundary, instead of failing the engine's startup.
func ECHConfigPEM(lines []string) ([]string, error) {
	raw, err := ECHConfigListBytes(lines)
	if err != nil || len(raw) == 0 {
		return nil, err
	}
	b64 := base64.StdEncoding.EncodeToString(raw)
	out := []string{"-----BEGIN ECH CONFIGS-----"}
	for len(b64) > 64 {
		out = append(out, b64[:64])
		b64 = b64[64:]
	}
	out = append(out, b64, "-----END ECH CONFIGS-----")
	return out, nil
}
