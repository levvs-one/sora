package xray

import (
	"context"
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"google.golang.org/protobuf/encoding/protowire"
)

func TestIsolatedXrayExternalAssetTraversalFixture(t *testing.T) {
	directory := os.Getenv("SORA_ENGINES_DIR")
	if directory == "" {
		t.Skip("set SORA_ENGINES_DIR to run the isolated native Xray fixture")
	}
	binary, err := filepath.Abs(filepath.Join(directory, "xray"))
	if err != nil {
		t.Fatal(err)
	}
	bwrap, err := exec.LookPath("bwrap")
	if err != nil {
		t.Skip("bubblewrap is required for the native asset fixture")
	}
	fixture := t.TempDir()
	if err := os.Mkdir(filepath.Join(fixture, "assets"), 0o700); err != nil {
		t.Fatal(err)
	}
	// The pinned GeoSiteList schema uses entry=1, country_code=1 and domain=2.
	// This fixture contains a full domain and no user data.
	domain := protowire.AppendVarint(protowire.AppendTag(nil, 1, protowire.VarintType), 3)
	domain = protowire.AppendString(protowire.AppendTag(domain, 2, protowire.BytesType), "fixture.invalid")
	site := protowire.AppendString(protowire.AppendTag(nil, 1, protowire.BytesType), "ZZ")
	site = protowire.AppendBytes(protowire.AppendTag(site, 2, protowire.BytesType), domain)
	data := protowire.AppendBytes(protowire.AppendTag(nil, 1, protowire.BytesType), site)
	for _, name := range []string{"assets/inside.dat", "outside.dat"} {
		if err := os.WriteFile(filepath.Join(fixture, name), data, 0o600); err != nil {
			t.Fatal(err)
		}
	}
	for _, test := range []struct {
		name, reference string
		missing         bool
	}{
		{"in-root-control", "ext:inside.dat:ZZ", false},
		{"fixture-only-escape", "ext:../outside.dat:ZZ", false},
		{"missing-file-control", "ext:../fixture-missing.dat:ZZ", true},
	} {
		t.Run(test.name, func(t *testing.T) {
			raw, err := json.Marshal(obj{
				"inbounds": []any{}, "outbounds": []obj{{"protocol": "freedom", "tag": "direct"}},
				"routing": obj{"rules": []obj{{"network": "tcp,udp", "domain": []string{test.reference}, "outboundTag": "direct"}}},
			})
			if err != nil {
				t.Fatal(err)
			}
			ctx, cancel := context.WithTimeout(t.Context(), 10*time.Second)
			defer cancel()
			// The namespace exposes only the binary and read-only planted files.
			// No host home, network, service, TUN or protected file is available.
			cmd := exec.CommandContext(ctx, bwrap, "--unshare-all", "--die-with-parent", "--new-session", "--clearenv",
				"--ro-bind", binary, "/xray", "--ro-bind", fixture, "/fixture", "--dev", "/dev", "--proc", "/proc", "--tmpfs", "/tmp",
				"--chdir", "/fixture/assets", "--setenv", "XRAY_LOCATION_ASSET", "/fixture/assets",
				"/xray", "run", "-test", "-c", "stdin:")
			cmd.Stdin = strings.NewReader(string(raw))
			output, err := cmd.CombinedOutput()
			if test.missing {
				if err == nil || !strings.Contains(string(output), "fixture-missing.dat") {
					t.Fatalf("missing-file control did not reach Xray's asset reader: %v\n%s", err, output)
				}
				return
			}
			if err != nil {
				t.Fatalf("native fixture failed before proving asset behaviour: %v\n%s", err, output)
			}
		})
	}
}
