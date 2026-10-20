package control

import (
	"context"
	"strings"
	"sync"
	"testing"

	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/subscription"
)

// fallbackPanel is a Fetcher fake that records every reference and the
// FetchOptions it was called with, and answers per primary reference:
// the primary fails or succeeds as the test sets, and a call is only
// distinguishable as primary-driven because the real fetcher performs
// the fallback switch internally. Here the fake stands in for the
// fetcher as a whole: refresh must hand it the stored primary plus the
// stored fallback in the options, fragment-free.
type fallbackPanel struct {
	mu      sync.Mutex
	refs    []string
	options []subscription.FetchOptions
	body    string
	usedFB  bool
	err     error
}

func (p *fallbackPanel) Fetch(_ context.Context, reference string, opts subscription.FetchOptions) (subscription.Result, error) {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.refs = append(p.refs, reference)
	p.options = append(p.options, opts)
	if p.err != nil {
		return subscription.Result{}, p.err
	}
	return subscription.Result{Body: []byte(p.body), Info: subscription.Info{Title: "Provider"}, UsedFallback: p.usedFB}, nil
}

func (p *fallbackPanel) lastCall() (string, subscription.FetchOptions) {
	p.mu.Lock()
	defer p.mu.Unlock()
	return p.refs[len(p.refs)-1], p.options[len(p.options)-1]
}

const (
	fallbackPrimaryLink = "https://panel.example/sub/abc"
	fallbackBackupLink  = "https://backup.example/sub/abc"
	fallbackPastedLink  = fallbackPrimaryLink + "#fallback-url=" + fallbackBackupLink
)

func TestSaveSplitsAndStoresTheFallback(t *testing.T) {
	p := &fallbackPanel{body: servers("a")}
	srv, _ := bookServer(t, t.TempDir(), p)
	state := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: fallbackPastedLink, AutoUpdate: true})
	id := state.GetSettings().GetId()

	rec := srv.subs.records[id]
	if rec.URL != fallbackPrimaryLink {
		t.Errorf("stored primary = %q, want the fragment-free %q", rec.URL, fallbackPrimaryLink)
	}
	if rec.FallbackURL != fallbackBackupLink {
		t.Errorf("stored fallback = %q, want %q", rec.FallbackURL, fallbackBackupLink)
	}
	ref, opts := p.lastCall()
	if ref != fallbackPrimaryLink || strings.Contains(ref, "#") {
		t.Errorf("the fetcher got reference %q: the fragment must never reach a fetch", ref)
	}
	if opts.FallbackURL != fallbackBackupLink {
		t.Errorf("the fetcher got FallbackURL %q, want the stored %q", opts.FallbackURL, fallbackBackupLink)
	}
	// States still never expose either link.
	if state.GetSettings().GetUrl() != "" {
		t.Error("subscription states must not expose the bearer link")
	}
	// The one authenticated link read round-trips both parts.
	srv.subs.mu.Lock()
	got := srv.subs.records[id].storedLink()
	srv.subs.mu.Unlock()
	primary, fallback, err := subscription.SplitFallback(got)
	if err != nil || primary != fallbackPrimaryLink || fallback != fallbackBackupLink {
		t.Errorf("storedLink() = %q, splits to (%q, %q, %v)", got, primary, fallback, err)
	}
}

func TestFallbackSurvivesARestart(t *testing.T) {
	dir := t.TempDir()
	srv, store := bookServer(t, dir, &fallbackPanel{body: servers("a")})
	state := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: fallbackPastedLink})
	id := state.GetSettings().GetId()
	_ = store.Close()

	restarted, _ := bookServer(t, dir, &fallbackPanel{body: servers("a")})
	rec := restarted.subs.records[id]
	if rec == nil || rec.URL != fallbackPrimaryLink || rec.FallbackURL != fallbackBackupLink {
		t.Fatalf("after a restart the record is %+v, want primary and fallback intact", rec)
	}
}

func TestSaveRefusesAFallbackTheFetcherWouldRefuse(t *testing.T) {
	srv, _ := bookServer(t, t.TempDir(), &fallbackPanel{body: servers("a")})
	for name, link := range map[string]string{
		"plain http fallback":  fallbackPrimaryLink + "#fallback-url=http://backup.example/sub/abc",
		"fallback credentials": fallbackPrimaryLink + "#fallback-url=https://user:pass@backup.example/sub/abc",
		"fallback no host":     fallbackPrimaryLink + "#fallback-url=https:///sub/abc",
	} {
		if _, err := srv.subs.save(&corev1.SubscriptionSettings{Url: link}); err == nil {
			t.Errorf("%s must be refused at save time", name)
		}
	}
	if len(srv.subs.records) != 0 {
		t.Error("a refused fallback must not leave a stored subscription behind")
	}
}

func TestDuplicateDetectionUsesThePrimaryLink(t *testing.T) {
	srv, _ := bookServer(t, t.TempDir(), &fallbackPanel{body: servers("a")})
	saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: fallbackPastedLink})
	other := fallbackPrimaryLink + "#fallback-url=https://other.example/sub/abc"
	if _, err := srv.subs.save(&corev1.SubscriptionSettings{Url: other}); err == nil {
		t.Error("the same primary with a different fallback is still the same subscription")
	}
}

func TestRefreshThroughTheFallbackKeepsTheServers(t *testing.T) {
	p := &fallbackPanel{body: servers("via-backup"), usedFB: true}
	srv, _ := bookServer(t, t.TempDir(), p)
	state := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: fallbackPastedLink})
	if len(state.GetOutbounds()) != 1 || state.GetLastError() != nil {
		t.Fatalf("a fallback refresh must land like any success, got %v", state)
	}
}

func TestRelinkingReplacesTheFallbackAndLinklessSavesKeepIt(t *testing.T) {
	p := &fallbackPanel{body: servers("a")}
	srv, _ := bookServer(t, t.TempDir(), p)
	state := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: fallbackPastedLink})
	id := state.GetSettings().GetId()

	// A rename (no link) keeps primary and fallback untouched.
	if _, err := srv.subs.save(&corev1.SubscriptionSettings{Id: id, Name: "Renamed"}); err != nil {
		t.Fatal(err)
	}
	if got := srv.subs.records[id].FallbackURL; got != fallbackBackupLink {
		t.Fatalf("a linkless save dropped the fallback, got %q", got)
	}
	// An explicit new link without a fragment clears the fallback: the
	// pasted link is the whole truth.
	if _, err := srv.subs.save(&corev1.SubscriptionSettings{Id: id, Url: "https://panel.example/sub/new"}); err != nil {
		t.Fatal(err)
	}
	rec := srv.subs.records[id]
	if rec.URL != "https://panel.example/sub/new" || rec.FallbackURL != "" {
		t.Fatalf("after relinking the record is %+v, want the new primary and no fallback", rec)
	}
	// An explicit link with a new fallback stores that one instead.
	if _, err := srv.subs.save(&corev1.SubscriptionSettings{Id: id, Url: "https://panel.example/sub/new#fallback-url=https://third.example/sub/x"}); err != nil {
		t.Fatal(err)
	}
	if got := srv.subs.records[id].FallbackURL; got != "https://third.example/sub/x" {
		t.Fatalf("the replacement fallback = %q", got)
	}
}

func TestGetSubscriptionLinkReturnsTheFallbackToo(t *testing.T) {
	srv, _ := bookServer(t, t.TempDir(), &fallbackPanel{body: servers("a")})
	state := saveAndWait(t, srv.subs, &corev1.SubscriptionSettings{Url: fallbackPastedLink})
	id := state.GetSettings().GetId()
	version := &corev1.ApiVersion{Major: 1, Minor: 6}
	response, err := srv.GetSubscriptionLink(context.Background(), &corev1.GetSubscriptionLinkRequest{
		ApiVersion: version, ControlAuthenticator: make([]byte, TokenLen), Id: id,
	})
	if err != nil || response.GetError() != nil {
		t.Fatalf("GetSubscriptionLink = %v, %v", response.GetError(), err)
	}
	primary, fallback, err := subscription.SplitFallback(response.GetUrl())
	if err != nil || primary != fallbackPrimaryLink || fallback != fallbackBackupLink {
		t.Errorf("the link read = %q, splits to (%q, %q, %v): the fallback must round-trip", response.GetUrl(), primary, fallback, err)
	}
	// Sanity: the primary error vocabulary is untouched by the split.
	if _, _, err := subscription.SplitFallback(fallbackPrimaryLink + "#fallback-url=http://x.example/sub"); errs.KeyOf(err) != errs.KeySubscriptionScheme {
		t.Errorf("a refused fallback keeps the scheme key, got %v", err)
	}
}
