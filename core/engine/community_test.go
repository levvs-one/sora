package engine

import "testing"

func TestCommunityCapabilitiesRequireCompatibleInstalledBuilds(t *testing.T) {
	available := []Availability{
		{Kind: KindSingBox, Usable: true, Version: Version{Major: 1, Minor: 14, Patch: 2}, NaiveReady: true},
		{Kind: KindXray, Usable: true, Version: Version{Major: 26, Minor: 3, Patch: 27}},
		{Kind: KindMihomo, Usable: true, Version: Version{Major: 1, Minor: 19, Patch: 32}},
	}
	for protocol, want := range map[Protocol]Kind{ProtocolMieru: KindMihomo, ProtocolNaive: KindSingBox} {
		p := &Plan{Outbounds: []Outbound{{Protocol: protocol}}}
		sel, err := SelectEngine(p, available, DefaultPreference)
		if err != nil || sel.Kind != want {
			t.Fatalf("auto %s: %+v %v", protocol, sel, err)
		}
		for _, kind := range DefaultPreference {
			_, err := SelectEngine(p, available, []Kind{kind})
			if (err == nil) != (kind == want) {
				t.Fatalf("manual %s/%s: %v", protocol, kind, err)
			}
		}
	}
	available[0].NaiveReady = false
	if _, err := SelectEngine(&Plan{Outbounds: []Outbound{{Protocol: ProtocolNaive}}}, available, DefaultPreference); err == nil {
		t.Fatal("missing Cronet accepted")
	}
	available[2].Version.Patch = 0
	if _, err := SelectEngine(&Plan{Outbounds: []Outbound{{Protocol: ProtocolMieru}}}, available, DefaultPreference); err == nil {
		t.Fatal("unverified old mieru adapter accepted")
	}
	if _, err := SelectEngine(&Plan{Outbounds: []Outbound{{Protocol: ProtocolNaive}, {Protocol: ProtocolMieru}}}, available, DefaultPreference); err == nil {
		t.Fatal("no engine can carry mieru and naive in the same plan")
	}
}
