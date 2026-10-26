package parser

import (
	"errors"
	"fmt"
	"strings"
	"sync"
	"testing"
)

func TestYAMLRejectsExcessiveDepthBeforeProjection(t *testing.T) {
	const proxy = "- {name: First, type: socks5, server: a.example, port: 443}\n"
	for name, nested := range map[string]string{
		"flow-sequence": strings.Repeat("[", 256) + "null" + strings.Repeat("]", 256),
		"flow-mapping":  strings.Repeat("{x: ", 256) + "null" + strings.Repeat("}", 256),
		"block-sequence": func() string {
			var b strings.Builder
			for i := range 256 {
				fmt.Fprintf(&b, "\n%s-", strings.Repeat("  ", i+1))
			}
			return b.String() + " null"
		}(),
		"block-mapping": func() string {
			var b strings.Builder
			for i := range 256 {
				fmt.Fprintf(&b, "\n%sx:", strings.Repeat("  ", i+1))
			}
			return b.String() + " null"
		}(),
	} {
		t.Run(name, func(t *testing.T) {
			for placement, raw := range map[string]string{
				"ignored-root":  "proxies:\n" + proxy + "ignored: " + nested,
				"proxy-options": "proxies:\n" + proxy + "- type: socks5\n  server: b.example\n  port: 443\n  extra: " + nested,
			} {
				t.Run(placement, func(t *testing.T) {
					result, err := (LinkParser{MaxItems: 1}).Parse([]byte(raw))
					if !errors.Is(err, ErrInvalid) || result.Format != FormatClash || len(result.Servers) != 0 {
						t.Fatalf("deep input accepted: servers=%d, format=%s, error=%v", len(result.Servers), result.Format, err)
					}
				})
			}
		})
	}
}

func TestYAMLDepthPolicyPreservesProviderFeatures(t *testing.T) {
	const common = "defaults: &defaults {type: socks5, server: a.example, port: 443}\nproxies:\n"
	raw := common + "- <<: *defaults\n  name: 'Quoted [value] {with: brackets}'\n  password: on\n" +
		"  extra: " + strings.Repeat("[", 32) + "null" + strings.Repeat("]", 32) + "\n" +
		"- <<: *defaults\n  name: Duplicate\n" +
		"- {type: socks5, server: b.example, port: 443, password: '123'}\n"
	result, err := (LinkParser{}).Parse([]byte(raw))
	if err != nil || result.Report.Imported != 2 || result.Report.SkippedDuplicates != 1 || len(result.Servers) != 2 {
		t.Fatalf("provider fields changed: report=%+v, error=%v", result.Report, err)
	}
	if result.Servers[0].DisplayName != "Quoted [value] {with: brackets}" || result.Servers[0].Password != "on" ||
		result.Servers[1].Password != "123" || result.Servers[0].Options["extra"] == "" {
		t.Fatal("provider scalars or preserved nested options changed")
	}
	for name, input := range map[string]string{
		"duplicate-key":   "proxies:\n- {type: socks5, server: a.example, server: b.example, port: 443}\n",
		"recursive-alias": "proxies: &self [*self]\n",
		"alias-expansion": "a: &a [x,x,x,x,x,x,x,x,x,x]\n" +
			"b: &b [*a,*a,*a,*a,*a,*a,*a,*a,*a,*a]\n" +
			"c: &c [*b,*b,*b,*b,*b,*b,*b,*b,*b,*b]\n" +
			"d: &d [*c,*c,*c,*c,*c,*c,*c,*c,*c,*c]\n" +
			"proxies: [{type: socks5, server: a.example, port: 443, extra: *d}]\n",
	} {
		t.Run(name, func(t *testing.T) {
			if result, err := (LinkParser{}).Parse([]byte(input)); !errors.Is(err, ErrInvalid) || len(result.Servers) != 0 {
				t.Fatalf("accepted invalid YAML: servers=%d, error=%v", len(result.Servers), err)
			}
		})
	}
}

func BenchmarkParseClashDefaultCapacity(b *testing.B) {
	var input strings.Builder
	input.WriteString("proxies:\n")
	for i := range DefaultMaxItems {
		fmt.Fprintf(&input, "- {type: socks5, server: server%d.example, port: 443}\n", i)
	}
	raw := []byte(input.String())
	b.ReportAllocs()
	b.SetBytes(int64(len(raw)))
	b.ResetTimer()
	for b.Loop() {
		result, err := (LinkParser{}).Parse(raw)
		if err != nil || result.Report.Imported != DefaultMaxItems || len(result.Servers) != DefaultMaxItems {
			b.Fatalf("default capacity changed: servers=%d, error=%v", len(result.Servers), err)
		}
	}
}

func TestYAMLDepthBoundary(t *testing.T) {
	for _, depth := range []int{127, 128, 129} {
		raw := "proxies:\n- {type: socks5, server: a.example, port: 443}\nignored: " +
			strings.Repeat("[", depth) + "null" + strings.Repeat("]", depth)
		result, err := (LinkParser{}).Parse([]byte(raw))
		if depth <= 128 {
			if err != nil || result.Report.Imported != 1 {
				t.Fatalf("depth %d: expected acceptance, error=%v", depth, err)
			}
		} else if !errors.Is(err, ErrInvalid) || len(result.Servers) != 0 {
			t.Fatalf("depth %d: expected rejection, error=%v", depth, err)
		}
	}
}

func FuzzParseYAMLWithDepthPolicy(f *testing.F) {
	f.Add("- {type: socks5, server: a.example, port: 443}")
	f.Add("&self [*self]")
	f.Add(strings.Repeat("[", 129) + "null" + strings.Repeat("]", 129))
	f.Fuzz(func(_ *testing.T, body string) {
		_, _ = (LinkParser{MaxItems: 100}).Parse([]byte("proxies:\n" + body))
	})
}

func TestYAMLDepthPolicyConcurrentImports(t *testing.T) {
	const prefix = "proxies:\n- {type: socks5, server: a.example, port: 443}\nignored: "
	var work sync.WaitGroup
	for worker := range 16 {
		work.Go(func() {
			depth := 32
			if worker%2 != 0 {
				depth = 129
			}
			raw := []byte(prefix + strings.Repeat("[", depth) + "null" + strings.Repeat("]", depth))
			for range 20 {
				result, err := (LinkParser{}).Parse(raw)
				if depth == 32 && (err != nil || result.Report.Imported != 1) {
					t.Errorf("independent valid import failed: %v", err)
				}
				if depth == 129 && (!errors.Is(err, ErrInvalid) || len(result.Servers) != 0) {
					t.Errorf("independent invalid import accepted: %v", err)
				}
			}
		})
	}
	work.Wait()
}
