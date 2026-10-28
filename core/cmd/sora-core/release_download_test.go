//go:build linux

package main

import (
	"context"
	"encoding/json"
	"encoding/pem"
	"flag"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"path"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"testing"
	"time"
)

// A test subprocess uses the production verifier with a public fixture identity.
// The shipped CLI and its pinned production root are never changed.
func TestInstallerVerifierProcess(_ *testing.T) {
	if os.Getenv("SORA_INSTALLER_VERIFIER_TEST") != "1" {
		return
	}
	var arguments []string
	for i, value := range os.Args {
		if value == "--" {
			arguments = os.Args[i+1:]
			break
		}
	}
	set := flag.NewFlagSet("installer-verifier-test", flag.ContinueOnError)
	directory := set.String("verify-release", "", "")
	version := set.String("release-version", "", "")
	artifact := set.String("release-artifact", "", "")
	target := set.String("release-target", "", "")
	if err := set.Parse(arguments); err != nil {
		os.Exit(2)
	}
	manifest, err := verifyRelease(*directory, *version, os.Getenv("SORA_TEST_PUBLIC_KEY"))
	if err == nil && *artifact != "" {
		var size int64
		size, err = manifest.artifactSize(*artifact, *target, *version)
		if err == nil {
			fmt.Println(size)
		}
	} else if err == nil {
		err = os.WriteFile(os.Getenv("SORA_TEST_VERIFY_MARKER"), []byte("verified"), 0o600)
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
	os.Exit(0)
}

func TestInstallerBoundsChunkedHTTPSDownloads(t *testing.T) {
	if runtime.GOARCH != "amd64" {
		t.Skip("desktop network fixture is amd64; native target parsing covers both architectures")
	}
	data, err := os.ReadFile("../../../app/test/fixtures/releases/metadata.json")
	if err != nil {
		t.Fatal(err)
	}
	var fixtures struct {
		PublicKey string                       `json:"public_key"`
		Releases  map[string]map[string]string `json:"releases"`
	}
	if err := json.Unmarshal(data, &fixtures); err != nil {
		t.Fatal(err)
	}
	original, err := os.ReadFile("../../../packaging/install/install.sh")
	if err != nil {
		t.Fatal(err)
	}
	for _, scenario := range []string{"valid", "package overflow", "package truncated", "metadata overflow", "metadata tamper", "metadata missing", "old curl"} {
		t.Run(scenario, func(t *testing.T) {
			root := t.TempDir()
			verified, installed := filepath.Join(root, "verified"), filepath.Join(root, "installed")
			record := fixtures.Releases["1.0.5"]
			var mutex sync.Mutex
			packageRequests := 0
			server := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				name := path.Base(r.URL.Path)
				body := []byte("abc")
				switch name {
				case "SHA256SUMS":
					body = []byte(record["manifest"])
				case "SHA256SUMS.minisig":
					body = []byte(record["signature"])
				case "release.json":
					body = []byte(record["metadata"])
					switch scenario {
					case "metadata overflow":
						body = make([]byte, 1024*1024+1)
					case "metadata tamper":
						body = append(body, ' ')
					case "metadata missing":
						http.NotFound(w, r)
						return
					}
				default:
					if name != "sora-core_1.0.5_amd64.deb" && name != "sora_1.0.5_amd64.deb" {
						http.NotFound(w, r)
						return
					}
					mutex.Lock()
					packageRequests++
					mutex.Unlock()
					if _, err := os.Stat(verified); err != nil {
						t.Error("package requested before authenticating metadata")
					}
					switch scenario {
					case "package overflow":
						body = append(body, '!')
					case "package truncated":
						body = body[:2]
					}
				}
				w.WriteHeader(http.StatusOK)
				w.(http.Flusher).Flush() // Force chunked transfer without Content-Length.
				_, _ = w.Write(body)     // Size rejection deliberately closes the connection.
			}))
			defer server.Close()
			certificate := filepath.Join(root, "loopback-ca.pem")
			if err := os.WriteFile(certificate, pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: server.Certificate().Raw}), 0o600); err != nil {
				t.Fatal(err)
			}
			script := strings.Replace(string(original), "repo=https://github.com/levvs-one/sora", "repo="+server.URL, 1)
			if script == string(original) {
				t.Fatal("temporary origin substitution did not match")
			}
			files := map[string]string{
				"install.sh": script,
				"id":         "#!/bin/sh\nprintf '0\\n'\n",
				"apt-get":    "#!/bin/sh\nprintf 'installed' >\"$SORA_TEST_INSTALL_MARKER\"\n",
				"verifier":   "#!/bin/sh\nexec \"$SORA_TEST_VERIFIER_BINARY\" -test.run=^TestInstallerVerifierProcess$ -- \"$@\"\n",
			}
			if scenario == "old curl" {
				files["curl"] = "#!/bin/sh\nprintf 'curl 8.3.0\\n'\n"
			}
			for name, contents := range files {
				if err := os.WriteFile(filepath.Join(root, name), []byte(contents), 0o700); err != nil {
					t.Fatal(err)
				}
			}
			ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
			defer cancel()
			command := exec.CommandContext(ctx, "/bin/sh", filepath.Join(root, "install.sh"))
			command.Env = append(os.Environ(), "SORA_DIST=", "SORA_VERSION=1.0.5", "SORA_VERIFIER="+filepath.Join(root, "verifier"),
				"SORA_INSTALLER_VERIFIER_TEST=1", "SORA_TEST_PUBLIC_KEY="+fixtures.PublicKey, "SORA_TEST_VERIFY_MARKER="+verified,
				"SORA_TEST_INSTALL_MARKER="+installed, "SORA_TEST_VERIFIER_BINARY="+os.Args[0], "CURL_CA_BUNDLE="+certificate,
				"NO_PROXY=127.0.0.1", "PATH="+root+":"+os.Getenv("PATH"))
			output, err := command.CombinedOutput()
			if (err == nil) != (scenario == "valid") {
				t.Fatalf("installer: %v\n%s", err, output)
			}
			_, installationError := os.Stat(installed)
			if (installationError == nil) != (scenario == "valid") {
				t.Fatalf("unexpected installation boundary: %v\n%s", installationError, output)
			}
			mutex.Lock()
			defer mutex.Unlock()
			if strings.HasPrefix(scenario, "metadata") || scenario == "old curl" {
				if packageRequests != 0 {
					t.Fatal("untrusted metadata caused a package request")
				}
			}
		})
	}
}
