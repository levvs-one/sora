package diagnostics_test

import (
	"context"
	"errors"
	"net"
	"testing"

	"github.com/levvs-one/sora-client/core/diagnostics"
)

// spoofResolve builds a fake resolver: answers maps resolver address to
// the IPs it returns, nx marks the resolvers answering NXDOMAIN.
func spoofResolve(answers map[string][]string, nx map[string]bool) func(context.Context, string, string) ([]string, error) {
	return func(ctx context.Context, resolverAddr, host string) ([]string, error) {
		if nx[resolverAddr] {
			return nil, &net.DNSError{Err: "no such host", Name: host, IsNotFound: true}
		}
		if ips, ok := answers[resolverAddr]; ok {
			return ips, nil
		}
		return nil, errors.New("network unreachable")
	}
}

func spoofInput(resolve func(context.Context, string, string) ([]string, error)) diagnostics.SpoofInput {
	return diagnostics.SpoofInput{
		Host:            "probe.example",
		SystemResolvers: []string{"9.9.9.9", "8.8.8.8"},
		TunnelResolvers: []diagnostics.TunnelResolver{{Address: "10.64.0.1", Transport: "udp"}},
		Resolve:         resolve,
	}
}

func TestDetectDnsSpoof_Agree(t *testing.T) {
	ips := map[string][]string{
		"9.9.9.9":   {"93.184.216.34"},
		"8.8.8.8":   {"93.184.216.34"},
		"10.64.0.1": {"93.184.216.34"},
	}
	report := diagnostics.DetectDnsSpoof(context.Background(), spoofInput(spoofResolve(ips, nil)))
	if report.Verdict != diagnostics.SpoofOK {
		t.Errorf("expected ok, got %s (%s)", report.Verdict, report.Detail)
	}
	if len(report.Answers) != 3 {
		t.Errorf("expected 3 answers, got %d", len(report.Answers))
	}
}

func TestDetectDnsSpoof_Inconsistent(t *testing.T) {
	ips := map[string][]string{
		"9.9.9.9":   {"93.184.216.34"},
		"10.64.0.1": {"93.184.216.34"},
		"8.8.8.8":   {"203.0.113.99"},
	}
	report := diagnostics.DetectDnsSpoof(context.Background(), spoofInput(spoofResolve(ips, nil)))
	if report.Verdict != diagnostics.SpoofInconsistent {
		t.Errorf("expected inconsistent, got %s (%s)", report.Verdict, report.Detail)
	}
}

// An injected fake IP next to the real one is not a subset difference:
// round-robin rotation never adds addresses.
func TestDetectDnsSpoof_PartialInjection(t *testing.T) {
	ips := map[string][]string{
		"9.9.9.9":   {"93.184.216.34"},
		"10.64.0.1": {"93.184.216.34"},
		"8.8.8.8":   {"93.184.216.34", "203.0.113.99"},
	}
	report := diagnostics.DetectDnsSpoof(context.Background(), spoofInput(spoofResolve(ips, nil)))
	if report.Verdict != diagnostics.SpoofInconsistent {
		t.Errorf("expected inconsistent for injected answer, got %s (%s)", report.Verdict, report.Detail)
	}
}

// A subset difference is benign: anycast rotation returns slices of the
// same set.
func TestDetectDnsSpoof_SubsetIsOK(t *testing.T) {
	ips := map[string][]string{
		"9.9.9.9":   {"93.184.216.34", "93.184.216.35"},
		"8.8.8.8":   {"93.184.216.34"},
		"10.64.0.1": {"93.184.216.35", "93.184.216.34"},
	}
	report := diagnostics.DetectDnsSpoof(context.Background(), spoofInput(spoofResolve(ips, nil)))
	if report.Verdict != diagnostics.SpoofOK {
		t.Errorf("expected ok for subset answers, got %s (%s)", report.Verdict, report.Detail)
	}
}

func TestDetectDnsSpoof_Bogus(t *testing.T) {
	ips := map[string][]string{
		"9.9.9.9":   {"10.10.10.10"},
		"8.8.8.8":   {"10.10.10.10"},
		"10.64.0.1": {"93.184.216.34"},
	}
	report := diagnostics.DetectDnsSpoof(context.Background(), spoofInput(spoofResolve(ips, nil)))
	if report.Verdict != diagnostics.SpoofBogus {
		t.Errorf("expected bogus, got %s (%s)", report.Verdict, report.Detail)
	}
}

func TestDetectDnsSpoof_NXDomain(t *testing.T) {
	ips := map[string][]string{
		"9.9.9.9":   {"93.184.216.34"},
		"10.64.0.1": {"93.184.216.34"},
	}
	nx := map[string]bool{"8.8.8.8": true}
	report := diagnostics.DetectDnsSpoof(context.Background(), spoofInput(spoofResolve(ips, nx)))
	if report.Verdict != diagnostics.SpoofNXDomain {
		t.Errorf("expected nxdomain, got %s (%s)", report.Verdict, report.Detail)
	}
}

func TestDetectDnsSpoof_Unresolved(t *testing.T) {
	report := diagnostics.DetectDnsSpoof(context.Background(), spoofInput(spoofResolve(nil, nil)))
	if report.Verdict != diagnostics.SpoofUnresolved {
		t.Errorf("expected unresolved, got %s (%s)", report.Verdict, report.Detail)
	}
}

// A unanimous answer outside the documented canary set means every path is
// tampered with, even though no resolver disagrees.
func TestDetectDnsSpoof_CanaryUnexpected(t *testing.T) {
	in := spoofInput(spoofResolve(map[string][]string{
		"9.9.9.9":   {"203.0.113.5"},
		"8.8.8.8":   {"203.0.113.5"},
		"10.64.0.1": {"203.0.113.5"},
	}, nil))
	in.Host = "" // default canary
	report := diagnostics.DetectDnsSpoof(context.Background(), in)
	if report.Verdict != diagnostics.SpoofInconsistent {
		t.Errorf("expected inconsistent for tampered canary, got %s (%s)", report.Verdict, report.Detail)
	}
}

func TestDetectDnsSpoof_CanaryExpected(t *testing.T) {
	in := spoofInput(spoofResolve(map[string][]string{
		"9.9.9.9":   {"1.1.1.1", "1.0.0.1"},
		"8.8.8.8":   {"1.1.1.1"},
		"10.64.0.1": {"1.0.0.1", "1.1.1.1"},
	}, nil))
	in.Host = "" // default canary
	report := diagnostics.DetectDnsSpoof(context.Background(), in)
	if report.Verdict != diagnostics.SpoofOK {
		t.Errorf("expected ok for the documented canary set, got %s (%s)", report.Verdict, report.Detail)
	}
}

func TestSpoofVerdictStrings(t *testing.T) {
	if diagnostics.SpoofOK.String() != "ok" || diagnostics.SpoofBogus.String() != "bogus" ||
		diagnostics.SpoofNXDomain.String() != "nxdomain" {
		t.Error("verdict strings changed")
	}
}
