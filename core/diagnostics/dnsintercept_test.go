package diagnostics

import (
	"context"
	"errors"
	"testing"
	"time"
)

func fakeQuery(t *testing.T, udp, tcp func() (DNSAnswer, error)) func(context.Context, string, string, string) (DNSAnswer, error) {
	t.Helper()
	return func(_ context.Context, network, _, _ string) (DNSAnswer, error) {
		switch network {
		case "udp":
			return udp()
		case "tcp":
			return tcp()
		default:
			return DNSAnswer{}, errors.New("unknown network " + network)
		}
	}
}

func okAnswer(ips ...string) func() (DNSAnswer, error) {
	return func() (DNSAnswer, error) { return DNSAnswer{IPs: ips}, nil }
}

func TestDetectDNSIntercept(t *testing.T) {
	ctx := context.Background()
	cases := []struct {
		name     string
		udp, tcp func() (DNSAnswer, error)
		want     InterceptVerdict
	}{
		{
			name: "aa NXDOMAIN on udp is the documented intercept",
			udp:  func() (DNSAnswer, error) { return DNSAnswer{NXDomain: true, Authoritative: true}, nil },
			tcp:  okAnswer("142.250.0.1"),
			want: Intercepted,
		},
		{
			name: "censor marker ip is injection",
			udp:  okAnswer("188.186.146.208"),
			tcp:  okAnswer("142.250.0.1"),
			want: Injected,
		},
		{
			name: "loopback answer for a public name is injection",
			udp:  okAnswer("127.0.0.1"),
			tcp:  okAnswer("127.0.0.1"),
			want: Injected,
		},
		{
			name: "udp nxdomain vs tcp addresses diverge",
			udp:  func() (DNSAnswer, error) { return DNSAnswer{NXDomain: true}, nil },
			tcp:  okAnswer("142.250.0.1"),
			want: Intercepted,
		},
		{
			name: "disjoint address sets diverge",
			udp:  okAnswer("10.10.34.34"),
			tcp:  okAnswer("142.250.0.1"),
			want: Intercepted,
		},
		{
			name: "consistent answers are ok",
			udp:  okAnswer("142.250.0.1"),
			tcp:  okAnswer("142.250.0.1", "142.250.0.2"),
			want: InterceptOK,
		},
		{
			name: "both transports failing is an outage not a claim",
			udp:  func() (DNSAnswer, error) { return DNSAnswer{}, errors.New("timeout") },
			tcp:  func() (DNSAnswer, error) { return DNSAnswer{}, errors.New("timeout") },
			want: InterceptUnresolved,
		},
		{
			name: "udp silent while tcp answers matches the udp-only intercept",
			udp:  func() (DNSAnswer, error) { return DNSAnswer{}, errors.New("timeout") },
			tcp:  okAnswer("142.250.0.1"),
			want: Intercepted,
		},
		{
			name: "plain NXDOMAIN on both is consistent, not an intercept claim",
			udp:  func() (DNSAnswer, error) { return DNSAnswer{NXDomain: true}, nil },
			tcp:  func() (DNSAnswer, error) { return DNSAnswer{NXDomain: true}, nil },
			want: InterceptOK,
		},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			rep := DetectDNSIntercept(ctx, InterceptInput{Query: fakeQuery(t, tc.udp, tc.tcp)})
			if rep.Verdict != tc.want {
				t.Errorf("verdict = %v, want %v (evidence: %v)", rep.Verdict, tc.want, rep.Evidence)
			}
			if len(rep.Evidence) == 0 {
				t.Error("report carries no evidence")
			}
		})
	}
}

func TestDetectDNSInterceptDefaults(t *testing.T) {
	rep := DetectDNSIntercept(context.Background(), InterceptInput{
		Query: fakeQuery(t, okAnswer("1.2.3.4"), okAnswer("1.2.3.4")),
	})
	if rep.Verdict != InterceptOK {
		t.Errorf("verdict = %v, want ok", rep.Verdict)
	}
}

// TestDNSWireCodec builds a synthetic response by hand and checks the
// decoder reads flags, rcode and A records, including a compressed name.
func TestDNSWireCodec(t *testing.T) {
	q := encodeDNSQuery("youtube.com")
	if len(q) < 12 {
		t.Fatalf("query too short: %d", len(q))
	}
	// Response: copy ID, flags QR|RD|RA|AA, 1 question, 1 answer.
	raw := []byte{q[0], q[1], 0x85, 0x80, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00}
	raw = append(raw, q[12:]...) // question section
	// Answer: pointer to the question name, A, IN, TTL 300, 4 bytes.
	raw = append(raw, 0xc0, 0x0c, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x01, 0x2c, 0x00, 0x04, 142, 250, 0, 1)
	ans, err := decodeDNSAnswer(raw)
	if err != nil {
		t.Fatalf("decode: %v", err)
	}
	if !ans.Authoritative {
		t.Error("aa flag not decoded")
	}
	if ans.NXDomain {
		t.Error("rcode 0 decoded as NXDOMAIN")
	}
	if len(ans.IPs) != 1 || ans.IPs[0] != "142.250.0.1" {
		t.Errorf("ips = %v, want [142.250.0.1]", ans.IPs)
	}
}

func TestDecodeDNSNXDOMAIN(t *testing.T) {
	q := encodeDNSQuery("youtube.com")
	raw := []byte{q[0], q[1], 0x81, 0x83, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
	raw = append(raw, q[12:]...)
	ans, err := decodeDNSAnswer(raw)
	if err != nil {
		t.Fatalf("decode: %v", err)
	}
	if !ans.NXDomain {
		t.Error("rcode 3 not decoded as NXDOMAIN")
	}
	if ans.Authoritative {
		t.Error("aa flag set on a non-authoritative response")
	}
}

func TestDecodeDNSTruncated(t *testing.T) {
	// A bare 12-byte header is a well-formed empty response, not an error.
	if _, err := decodeDNSAnswer(make([]byte, 12)); err != nil {
		t.Errorf("decode(12 zero bytes) = %v, want nil (valid empty response)", err)
	}
	for _, raw := range [][]byte{
		nil,
		{1, 2, 3},
		// Header claims one question but carries no question bytes.
		{0, 1, 0x01, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
	} {
		if _, err := decodeDNSAnswer(raw); err == nil {
			t.Errorf("decode(%d bytes) = nil error, want truncation error", len(raw))
		}
	}
}

func TestDetectDNSInterceptRespectsTimeout(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 50*time.Millisecond)
	defer cancel()
	rep := DetectDNSIntercept(ctx, InterceptInput{
		Timeout: time.Hour, // the query ignores it; ctx must still bound the probe
		Query: func(ctx context.Context, _, _, _ string) (DNSAnswer, error) {
			<-ctx.Done()
			return DNSAnswer{}, ctx.Err()
		},
	})
	if rep.Verdict != InterceptUnresolved {
		t.Errorf("verdict = %v, want unresolved on cancelled context", rep.Verdict)
	}
}
