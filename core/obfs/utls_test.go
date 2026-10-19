package obfs

import (
	"crypto/tls"
	"errors"
	"net"
	"strings"
	"testing"

	utls "github.com/refraction-networking/utls"
)

func TestFingerprintID(t *testing.T) {
	cases := map[string]utls.ClientHelloID{
		"chrome":     utls.HelloChrome_Auto,
		"firefox":    utls.HelloFirefox_Auto,
		"safari":     utls.HelloSafari_Auto,
		"randomized": utls.HelloRandomizedALPN,
		"Chrome":     utls.HelloChrome_Auto, // case-insensitive
	}
	for name, want := range cases {
		got, err := Profile{UTLS: name}.FingerprintID()
		if err != nil {
			t.Errorf("%s: %v", name, err)
			continue
		}
		if got != want {
			t.Errorf("%s: got %v, want %v", name, got, want)
		}
	}
	for _, name := range []string{"", "none"} {
		if _, err := (Profile{UTLS: name}).FingerprintID(); !errors.Is(err, ErrUTLSDisabled) {
			t.Errorf("%q: expected ErrUTLSDisabled, got %v", name, err)
		}
	}
	if _, err := (Profile{UTLS: "opera"}).FingerprintID(); err == nil {
		t.Error("expected error for unknown fingerprint")
	}
}

func TestUTLSConfig(t *testing.T) {
	if cfg := (Profile{UTLS: "none"}).UTLSConfig(&tls.Config{ServerName: "x"}); cfg != nil {
		t.Error("disabled profile must return nil config")
	}
	base := &tls.Config{
		ServerName:             "example.com",
		InsecureSkipVerify:     true,
		NextProtos:             []string{"h2"},
		MinVersion:             tls.VersionTLS12,
		SessionTicketsDisabled: true,
	}
	got := Profile{UTLS: "chrome"}.UTLSConfig(base)
	if got == nil {
		t.Fatal("expected non-nil config")
	}
	if got.ServerName != "example.com" || !got.InsecureSkipVerify {
		t.Errorf("fields not copied: %+v", got)
	}
	if len(got.NextProtos) != 1 || got.NextProtos[0] != "h2" {
		t.Errorf("NextProtos not copied: %v", got.NextProtos)
	}
	if got.MinVersion != tls.VersionTLS12 || !got.SessionTicketsDisabled {
		t.Errorf("version/session fields not copied: %+v", got)
	}
	if cfg := (Profile{UTLS: "firefox"}).UTLSConfig(nil); cfg == nil {
		t.Error("nil base must still yield a config")
	}
}

func TestNewUTLSConnErrors(t *testing.T) {
	c, _ := net.Pipe()
	defer c.Close()
	if _, err := (Profile{UTLS: "none"}).NewUTLSConn(c, &utls.Config{}); !errors.Is(err, ErrUTLSDisabled) {
		t.Errorf("expected ErrUTLSDisabled, got %v", err)
	}
	if _, err := (Profile{UTLS: "chrome"}).NewUTLSConn(nil, &utls.Config{}); err == nil {
		t.Error("expected error for nil conn")
	}
	if _, err := (Profile{UTLS: "opera"}).NewUTLSConn(c, &utls.Config{}); err == nil {
		t.Error("expected error for unknown fingerprint")
	}
}

// TestUTLSHandshake performs a real TLS handshake between a uTLS client
// (chrome, then randomized fingerprint) and a stock crypto/tls server over
// net.Pipe.
func TestUTLSHandshake(t *testing.T) {
	for _, fp := range []string{"chrome", "randomized"} {
		t.Run(fp, func(t *testing.T) {
			clientRaw, serverRaw := net.Pipe()
			defer clientRaw.Close()
			defer serverRaw.Close()

			serverErr := make(chan error, 1)
			go func() {
				s := tls.Server(serverRaw, &tls.Config{
					Certificates: []tls.Certificate{testServerCert(t)},
				})
				defer s.Close()
				serverErr <- s.Handshake()
			}()

			p := Profile{UTLS: fp}
			uc, err := p.NewUTLSConn(clientRaw, &utls.Config{
				ServerName:         "example.com",
				InsecureSkipVerify: true,
			})
			if err != nil {
				t.Fatalf("NewUTLSConn: %v", err)
			}
			defer uc.Close()
			if err := uc.Handshake(); err != nil {
				t.Fatalf("uTLS handshake (%s): %v", fp, err)
			}
			if err := <-serverErr; err != nil {
				t.Fatalf("server handshake: %v", err)
			}
			st := uc.ConnectionState()
			if !st.HandshakeComplete {
				t.Fatal("handshake not marked complete")
			}
		})
	}
}

func TestUTLSHandshakeWrongServerNameFails(t *testing.T) {
	// Sanity: the fake-SNI contract — a handshake fails closed when the
	// server cannot present a matching certificate.
	clientRaw, serverRaw := net.Pipe()
	defer clientRaw.Close()
	defer serverRaw.Close()

	go func() {
		s := tls.Server(serverRaw, &tls.Config{
			Certificates: []tls.Certificate{testServerCert(t)},
		})
		defer s.Close()
		s.Handshake()
	}()
	uc, err := Profile{UTLS: "chrome"}.NewUTLSConn(clientRaw, &utls.Config{
		ServerName: "decoy.test", // cert is for example.com
	})
	if err != nil {
		t.Fatalf("NewUTLSConn: %v", err)
	}
	defer uc.Close()
	if err := uc.Handshake(); err == nil || !strings.Contains(err.Error(), "certificate") {
		t.Fatalf("expected certificate error, got %v", err)
	}
}
