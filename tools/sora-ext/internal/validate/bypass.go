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

// The same bounded protobuf profiles consumed by the app; native flags and
// paths are deliberately outside this descriptor.
func validateBypassAsset(raw []byte) error {
	if len(raw) > 1<<20 {
		return fmt.Errorf("bypass descriptor exceeds 1 MiB")
	}
	var doc struct {
		Version  int                        `json:"hook_version"`
		Backend  string                     `json:"backend"`
		Profiles map[string]json.RawMessage `json:"profiles"`
	}
	dec := json.NewDecoder(bytes.NewReader(raw))
	dec.DisallowUnknownFields()
	if err := dec.Decode(&doc); err != nil {
		return err
	}
	if err := dec.Decode(new(any)); err != io.EOF {
		return fmt.Errorf("trailing bypass descriptor data")
	}
	if doc.Version != 2 || (doc.Backend != "tpws" && doc.Backend != "byedpi") {
		return fmt.Errorf("unsupported bypass profile descriptor")
	}
	if len(doc.Profiles) < 1 || len(doc.Profiles) > 16 {
		return fmt.Errorf("bypass profiles must contain 1..16 named strategies")
	}
	for name, rawProfile := range doc.Profiles {
		if strings.TrimSpace(name) == "" || len(name) > 64 || len(rawProfile) == 0 || rawProfile[0] != '{' {
			return fmt.Errorf("invalid bypass profile %q", name)
		}
		if err := protojson.Unmarshal(rawProfile, new(corev1.BypassStrategy)); err != nil {
			return fmt.Errorf("bypass profile %q: %w", name, err)
		}
	}
	return nil
}
