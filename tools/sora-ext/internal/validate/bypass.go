package validate

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"strings"

	"google.golang.org/protobuf/encoding/protojson"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

// Descriptors select bounded profiles for known host backends, never paths,
// commands, native binaries or arbitrary engine fragments.
func validateBypassAsset(raw []byte) error {
	if len(raw) > 1<<20 {
		return fmt.Errorf("bypass descriptor exceeds 1 MiB")
	}
	var doc struct {
		Version   int             `json:"hook_version"`
		Backend   json.RawMessage `json:"backend"`
		Profiles  json.RawMessage `json:"profiles"`
		Platforms json.RawMessage `json:"platforms"`
	}
	dec := json.NewDecoder(bytes.NewReader(raw))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&doc); err != nil {
		return err
	}
	if err := dec.Decode(new(any)); err != io.EOF {
		return fmt.Errorf("trailing bypass descriptor data")
	}
	if doc.Version == 2 {
		if len(doc.Platforms) != 0 {
			return fmt.Errorf("version 2 has no platform variants")
		}
		var backend string
		if err := json.Unmarshal(doc.Backend, &backend); err != nil || (backend != "tpws" && backend != "byedpi") {
			return fmt.Errorf("unsupported bypass profile descriptor")
		}
		var profiles map[string]json.RawMessage
		if err := json.Unmarshal(doc.Profiles, &profiles); err != nil {
			return err
		}
		return validateBypassProfiles(backend, profiles)
	}
	if doc.Version != 3 || len(doc.Backend) != 0 || len(doc.Profiles) != 0 {
		return fmt.Errorf("unsupported bypass profile descriptor")
	}
	var platforms map[string]json.RawMessage
	if err := json.Unmarshal(doc.Platforms, &platforms); err != nil {
		return err
	}
	if len(platforms) < 1 || len(platforms) > 2 {
		return fmt.Errorf("bypass descriptor requires 1..2 supported platforms")
	}
	for platform, rawVariant := range platforms {
		var variant struct {
			Backend  string                     `json:"backend"`
			Scope    json.RawMessage            `json:"scope"`
			Profiles map[string]json.RawMessage `json:"profiles"`
		}
		dec := json.NewDecoder(bytes.NewReader(rawVariant))
		dec.DisallowUnknownFields()
		if err := dec.Decode(&variant); err != nil {
			return err
		}
		if (platform == "linux" && variant.Backend != "tpws") ||
			(platform == "windows" && variant.Backend != "winws" && variant.Backend != "byedpi") ||
			(platform != "linux" && platform != "windows") {
			return fmt.Errorf("backend does not match a supported platform")
		}
		if variant.Backend == "winws" {
			var scope string
			if err := json.Unmarshal(variant.Scope, &scope); err != nil || scope != "system-tcp-80-443" {
				return fmt.Errorf("winws requires its explicit system-wide traffic scope")
			}
		} else if len(variant.Scope) != 0 {
			return fmt.Errorf("SOCKS backends have no global traffic scope")
		}
		if err := validateBypassProfiles(variant.Backend, variant.Profiles); err != nil {
			return err
		}
	}
	return nil
}

func validateBypassProfiles(backend string, profiles map[string]json.RawMessage) error {
	if len(profiles) < 1 || len(profiles) > 16 {
		return fmt.Errorf("bypass profiles must contain 1..16 named strategies")
	}
	for name, raw := range profiles {
		raw = bytes.TrimSpace(raw)
		if strings.TrimSpace(name) == "" || len(name) > 64 || len(raw) == 0 || raw[0] != '{' {
			return fmt.Errorf("invalid bypass profile %q", name)
		}
		var strategy corev1.BypassStrategy
		if err := protojson.Unmarshal(raw, &strategy); err != nil {
			return fmt.Errorf("bypass profile %q: %w", name, err)
		}
		if backend == "winws" && (strategy.GetOob() || strategy.GetTlsRecord() != "") {
			return fmt.Errorf("winws profile %q: OOB and TLS-record splitting require the SOCKS backend", name)
		}
	}
	return nil
}
