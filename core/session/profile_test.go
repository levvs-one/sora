package session

import (
	"context"
	"testing"

	"github.com/levvs-one/sora-client/core/profiles"
)

func profileStore(t *testing.T) *profiles.Store {
	t.Helper()
	s, err := profiles.NewStore(t.TempDir())
	if err != nil {
		t.Fatal(err)
	}
	saved, err := s.Save(profiles.Profile{
		Name:      "Home",
		Triggers:  profiles.Triggers{SSIDs: []string{"Home_Network"}},
		Apply:     profiles.Apply{Mode: "tun"},
		AutoApply: true,
	})
	if err != nil {
		t.Fatal(err)
	}
	if saved.ID == "" {
		t.Fatal("profile must get an id")
	}
	return s
}

func startSessionWithProfiles(t *testing.T, store *profiles.Store) *Session {
	t.Helper()
	eng, guard := newFakeEngine(), &fakeGuard{}
	cfg := testConfig(eng, guard)
	cfg.Profiles = store
	s, err := New(cfg)
	if err != nil {
		t.Fatal(err)
	}
	if err := s.Start(context.Background()); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = s.Stop(context.Background()) })
	return s
}

func TestProfileMatchIsJournaled(t *testing.T) {
	s := startSessionWithProfiles(t, profileStore(t))
	s.matchProfile(profiles.Fingerprint{SSID: "Home_Network"})
	events := s.Journal().Since(0, 64)
	found := false
	for _, e := range events {
		if e.Kind != EventProfile {
			continue
		}
		found = true
		if e.Profile == nil || e.Profile.Name != "Home" || !e.Profile.AutoApply {
			t.Fatalf("wrong profile event: %+v", e.Profile)
		}
	}
	if !found {
		t.Fatal("a matching network must journal a profile event")
	}
}

func TestProfileMismatchJournalsNothing(t *testing.T) {
	s := startSessionWithProfiles(t, profileStore(t))
	before := len(s.Journal().Since(0, 64))
	s.matchProfile(profiles.Fingerprint{SSID: "Unknown_Cafe"})
	if got := len(s.Journal().Since(0, 64)); got != before {
		t.Fatalf("a mismatching network journaled %d events, want none", got-before)
	}
}

func TestProfileHookNeedsConnectedSession(t *testing.T) {
	eng, guard := newFakeEngine(), &fakeGuard{}
	cfg := testConfig(eng, guard)
	cfg.Profiles = profileStore(t)
	s, err := New(cfg)
	if err != nil {
		t.Fatal(err)
	}
	// Not started: still disconnected, so checkProfile must stay silent even
	// though a profile would match.
	s.checkProfile()
	for _, e := range s.Journal().Since(0, 64) {
		if e.Kind == EventProfile {
			t.Fatal("a disconnected session must not emit profile events")
		}
	}
}

func TestProfileHookWithoutStoreIsSilent(t *testing.T) {
	eng, guard := newFakeEngine(), &fakeGuard{}
	s, err := New(testConfig(eng, guard))
	if err != nil {
		t.Fatal(err)
	}
	if err := s.Start(context.Background()); err != nil {
		t.Fatal(err)
	}
	defer func() { _ = s.Stop(context.Background()) }()
	s.checkProfile()
	for _, e := range s.Journal().Since(0, 64) {
		if e.Kind == EventProfile {
			t.Fatal("no store must mean no profile events")
		}
	}
}
