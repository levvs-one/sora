package parser

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"testing"
)

func TestItemLimitAppliesToEverySubscriptionListFormat(t *testing.T) {
	const id = "123e4567-e89b-12d3-a456-426614174000"
	var links, yaml strings.Builder
	yaml.WriteString("proxies:\n")
	var items, profiles []map[string]any
	for i := range 3 {
		host := fmt.Sprintf("server%d.example", i)
		fmt.Fprintf(&links, "vless://%s@%s:443\n", id, host)
		fmt.Fprintf(&yaml, "- {name: Server%d, type: vless, server: %s, port: 443, uuid: %s}\n", i, host, id)
		items = append(items, map[string]any{"type": "vless", "server": host, "server_port": 443, "uuid": id})
		profiles = append(profiles, map[string]any{"remarks": fmt.Sprintf("Profile%d", i), "outbounds": []any{
			map[string]any{"protocol": "vless", "settings": map[string]any{"address": host, "port": 443}},
		}})
	}
	inputs := map[string][]byte{
		"plain": []byte(links.String()), "base64": []byte(base64.StdEncoding.EncodeToString([]byte(links.String()))),
		"clash": []byte(yaml.String()),
	}
	for name, value := range map[string]any{"singbox": map[string]any{"outbounds": items}, "sip008": map[string]any{"servers": items}, "xray-profiles": profiles} {
		encoded, err := json.Marshal(value)
		if err != nil {
			t.Fatal(err)
		}
		inputs[name] = encoded
	}
	for name, input := range inputs {
		t.Run(name, func(t *testing.T) {
			for _, limit := range []int{-1, 0, 1, 2, 3, 4} {
				result, err := (LinkParser{MaxItems: limit}).Parse(input)
				want := 3
				if limit > 0 && limit < want {
					want = limit
				}
				if err != nil || len(result.Servers) != want || result.Report.Imported != want ||
					result.Report.Unsupported != 3-want || result.Report.Invalid != 0 || result.Report.SkippedDuplicates != 0 {
					t.Fatalf("limit=%d: servers=%d, report=%+v, error=%v", limit, len(result.Servers), result.Report, err)
				}
				if len(result.Report.UnsupportedItems) != 3-want {
					t.Fatal("truncated entries were not reported")
				}
				for i, item := range result.Report.UnsupportedItems {
					if item.Index != want+i || item.Reason != "item limit exceeded" {
						t.Fatalf("incorrect truncation report: %+v", item)
					}
				}
			}
		})
	}
}

func TestStructuredLimitPreservesDuplicateAndInvalidAccounting(t *testing.T) {
	for name, input := range map[string]string{
		"json": `{"outbounds":[{"type":"socks5","server":"a.example","port":443},{"type":"socks5","server":"a.example","port":443},{"type":"socks5"},{"type":"socks5","server":"b.example","port":443},{"type":"socks5","server":"c.example","port":443}]}`,
		"yaml": "proxies:\n- {type: socks5, server: a.example, port: 443}\n- {type: socks5, server: a.example, port: 443}\n- {type: socks5}\n- {type: socks5, server: b.example, port: 443}\n- {type: socks5, server: c.example, port: 443}",
	} {
		t.Run(name, func(t *testing.T) {
			result, err := (LinkParser{MaxItems: 2}).Parse([]byte(input))
			if err != nil || len(result.Servers) != 2 || result.Report.Imported != 2 || result.Report.Invalid != 1 ||
				result.Report.SkippedDuplicates != 1 || result.Report.Unsupported != 1 {
				t.Fatalf("report=%+v, servers=%d, error=%v", result.Report, len(result.Servers), err)
			}
			if len(result.Report.DuplicateItems) != 1 || result.Report.DuplicateItems[0].Index != 1 ||
				len(result.Report.UnsupportedItems) != 1 || result.Report.UnsupportedItems[0].Index != 4 {
				t.Fatal("source indexes changed after duplicate/invalid entries")
			}
		})
	}
}

func TestDetectorRejectsOversizedWhitespaceBeforeEmptyClassification(t *testing.T) {
	if _, err := (ImportDetector{}).Detect([]byte(strings.Repeat(" ", MaxInputSize+1))); !errors.Is(err, ErrInputTooLarge) {
		t.Fatalf("oversized input classification: %v", err)
	}
}

func TestXrayProfileCountsAsOneImportedItem(t *testing.T) {
	input := []byte(`{"remarks":"One profile","outbounds":[{"protocol":"vless","settings":{"address":"a.example","port":443}},{"protocol":"freedom"},{"protocol":"blackhole"}]}`)
	result, err := (LinkParser{MaxItems: 1}).Parse(input)
	if err != nil || len(result.Servers) != 1 || result.Report.Imported != 1 || result.Report.Unsupported != 0 || result.Servers[0].Protocol != "xray-profile" {
		t.Fatalf("full profile was split or truncated: report=%+v, error=%v", result.Report, err)
	}
}

func TestListLimitKeepsOnlyTheAcceptedServersMetadata(t *testing.T) {
	input := "olcrtc://wbstream?vp8channel@room-01#" + olcKey + "$First\n##name: Last kept\n" +
		"olcrtc://wbstream?vp8channel@room-02#" + olcKey + "$Second\n##name: Must not overwrite\n\n# comment\n"
	for _, raw := range []string{input, base64.StdEncoding.EncodeToString([]byte(input))} {
		result, err := (LinkParser{MaxItems: 1}).Parse([]byte(raw))
		if err != nil || len(result.Servers) != 1 || result.Report.Unsupported != 1 ||
			result.Servers[0].DisplayName != "Last kept" || result.Servers[0].Options["olcrtc-meta-name"] != "Last kept" {
			t.Fatalf("metadata attached across the limit: report=%+v, error=%v", result.Report, err)
		}
	}
}
