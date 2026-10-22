package control

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"os"
	"slices"
	"strings"
	"testing"

	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
)

func TestSubscriptionProviderOrder(t *testing.T) {
	raw, err := os.ReadFile("../parser/testdata/imports.json")
	if err != nil {
		t.Fatal(err)
	}
	var fixtures []struct{ Name, Input string }
	if err := json.Unmarshal(raw, &fixtures); err != nil {
		t.Fatal(err)
	}
	inputs := map[string]string{}
	for _, fixture := range fixtures {
		inputs[fixture.Name] = fixture.Input
	}
	const names = "zulu,alpha,middle"
	want := strings.Split(names, ",")
	plain := servers(append(slices.Clone(want), "zulu")...)
	bodies := map[string]string{
		"plain":  plain,
		"base64": base64.StdEncoding.EncodeToString([]byte(plain)),
	}
	var yamlNodes []string
	for _, name := range append(slices.Clone(want), "zulu") {
		yamlNodes = append(yamlNodes, strings.NewReplacer("proxies:\n", "", "Edge", name, "example.com", name+".example.com").Replace(inputs["clash yaml"]))
	}
	bodies["clash"] = "proxies:\n" + strings.Join(yamlNodes, "")
	for _, format := range []struct{ name, fixture, key string }{
		{"sing-box", "singbox json", "outbounds"},
		{"sip008", "sip008 json", "servers"},
		{"xray", "xray profile raw", ""},
	} {
		var nodes []json.RawMessage
		for _, name := range append(slices.Clone(want), "zulu") {
			var root map[string]json.RawMessage
			input := strings.NewReplacer("Edge", name, "example.com", name+".example.com").Replace(inputs[format.fixture])
			if err := json.Unmarshal([]byte(input), &root); err != nil {
				t.Fatal(err)
			}
			if format.key == "" {
				nodes = append(nodes, json.RawMessage(input))
			} else {
				var items []map[string]any
				if err := json.Unmarshal(root[format.key], &items); err != nil {
					t.Fatal(err)
				}
				items[0]["tag"] = name
				node, err := json.Marshal(items[0])
				if err != nil {
					t.Fatal(err)
				}
				nodes = append(nodes, node)
			}
		}
		var body []byte
		if format.key == "" {
			body, err = json.Marshal(nodes)
		} else {
			body, err = json.Marshal(map[string]any{format.key: nodes})
		}
		if err != nil {
			t.Fatal(err)
		}
		bodies[format.name] = string(body)
	}
	for format, body := range bodies {
		t.Run(format, func(t *testing.T) {
			p := &panel{body: body}
			dir := t.TempDir()
			srv, store := bookServer(t, dir, p)
			state := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://panel.example/sub/order"})
			id := state.GetSettings().GetId()
			checkSubscriptionOrder(t, srv, state, want)
			if err := store.Close(); err != nil {
				t.Fatal(err)
			}
			restarted, _ := bookServer(t, dir, p)
			listed, err := restarted.ListSubscriptions(context.Background(), &corev1.ListSubscriptionsRequest{
				ApiVersion: customVersion(), ControlAuthenticator: make([]byte, TokenLen),
			})
			if err != nil || len(listed.GetSubscriptions()) != 1 {
				t.Fatalf("list after restart: %v, %v", listed, err)
			}
			checkSubscriptionOrder(t, restarted, listed.GetSubscriptions()[0], want)
			changes, stop := restarted.subs.watch()
			defer stop()
			// A provider reorder must replace the old order, including after
			// lazy loading from several persisted protobuf chunks.
			nextBody := strings.NewReplacer("zulu", "middle", "middle", "zulu").Replace(body)
			if format == "base64" {
				nextBody = base64.StdEncoding.EncodeToString([]byte(strings.NewReplacer("zulu", "middle", "middle", "zulu").Replace(plain)))
			}
			p.set(nextBody, nil)
			refreshed, err := restarted.RefreshSubscription(context.Background(), &corev1.RefreshSubscriptionRequest{
				ApiVersion: customVersion(), ControlAuthenticator: make([]byte, TokenLen), Id: id,
			})
			if err != nil || refreshed.GetError() != nil {
				t.Fatalf("refresh: %v, %v", refreshed, err)
			}
			next := []string{"middle", "alpha", "zulu"}
			checkSubscriptionOrder(t, restarted, refreshed.GetState(), next)
			for range 2 {
				changed := <-changes
				if !changed.GetUpdating() {
					checkSubscriptionOrder(t, restarted, changed, next)
				}
			}
		})
	}
}

func checkSubscriptionOrder(t *testing.T, srv *Server, state *corev1.SubscriptionState, want []string) {
	t.Helper()
	var names, refs []string
	for _, outbound := range state.GetOutbounds() {
		names = append(names, outbound.GetDisplayName())
		refs = append(refs, outbound.GetCredentials().GetReference())
	}
	if !slices.Equal(names, want) {
		t.Fatalf("provider order = %v, want %v", names, want)
	}
	srv.subs.mu.Lock()
	stored := slices.Clone(srv.subs.records[state.GetSettings().GetId()].Servers)
	srv.subs.mu.Unlock()
	if !slices.Equal(refs, stored) {
		t.Fatal("stored references differ from the provider list order")
	}
}

func TestSubscriptionOrderAcrossChunksAndRefresh(t *testing.T) {
	want := make([]string, 700)
	for i := range want {
		want[i] = fmt.Sprintf("node%03d", len(want)-i)
	}
	p := &panel{body: servers(want...)}
	dir := t.TempDir()
	srv, store := bookServer(t, dir, p)
	first := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://panel.example/sub/large"})
	second := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://panel.example/sub/second"})
	checkSubscriptionOrder(t, srv, first, want)
	if srv.subs.records[first.GetSettings().GetId()].ListParts < 2 {
		t.Fatal("test must cross list chunks")
	}
	if err := store.Close(); err != nil {
		t.Fatal(err)
	}
	restarted, _ := bookServer(t, dir, p)
	list := restarted.subs.list()
	if len(list) != 2 || list[0].GetSettings().GetId() != first.GetSettings().GetId() || list[1].GetSettings().GetId() != second.GetSettings().GetId() {
		t.Fatal("subscription insertion order changed after restart")
	}
	checkSubscriptionOrder(t, restarted, list[0], want)
	slices.Reverse(want)
	p.set(servers(want...), nil)
	state, err := restarted.subs.refresh(context.Background(), first.GetSettings().GetId())
	if err != nil {
		t.Fatal(err)
	}
	checkSubscriptionOrder(t, restarted, state, want)
	if restarted.subs.list()[1].GetSettings().GetId() != second.GetSettings().GetId() {
		t.Fatal("refresh reordered subscriptions")
	}
}

func TestCustomChangesKeepProviderOrder(t *testing.T) {
	srv, token := customTestPlane(t)
	srv.fetcher = &panel{body: servers("zulu", "alpha", "middle")}
	first := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://panel.example/sub/first"})
	second := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: "https://panel.example/sub/second"})
	changes, stop := srv.subs.watch()
	defer stop()
	saveCustomForHook(t, customImpl(t, srv), token, "Manual")
	for range 2 {
		state := <-changes
		if state.GetSettings().GetId() != first.GetSettings().GetId() && state.GetSettings().GetId() != second.GetSettings().GetId() {
			t.Fatal("unexpected subscription in custom broadcast")
		}
		var names []string
		for _, outbound := range state.GetOutbounds() {
			names = append(names, outbound.GetDisplayName())
		}
		if !slices.Equal(names, []string{"zulu", "alpha", "middle", "Manual"}) {
			t.Fatalf("custom broadcast changed provider order: %v", names)
		}
	}
}
