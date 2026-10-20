package control

// Regression test for the F8 shadow feature: Capabilities() never advertised
// "chains", so the client's connectChain always threw chainUnsupported on a
// real core. apiVersion() must append "chains" exactly when at least one
// installed, usable engine supports engine.FeatureChains - the same gate
// that ProbeChain uses via chainEngines.

import (
	"context"
	"slices"
	"testing"

	"github.com/levvs-one/sora-client/core/engine"
)

// stubChainMeasurer is a Measurer exposing fixed engine availability.
type stubChainMeasurer struct {
	avail []engine.Availability
}

func (m stubChainMeasurer) Measure(context.Context, []engine.Outbound, engine.MeasureOptions) (<-chan engine.Measurement, error) {
	return nil, engine.ErrNoEngine
}

func (m stubChainMeasurer) Availability() []engine.Availability { return m.avail }

// stubPlainMeasurer is a Measurer with no engine-availability discovery.
type stubPlainMeasurer struct{}

func (stubPlainMeasurer) Measure(context.Context, []engine.Outbound, engine.MeasureOptions) (<-chan engine.Measurement, error) {
	return nil, engine.ErrNoEngine
}

func chainsAdvertised(s *Server) bool {
	return slices.Contains(s.apiVersion().GetCapabilities(), "chains")
}

func TestApiVersionChainsCapability(t *testing.T) {
	v := Version{Major: 1, Minor: 11}
	xray := engine.Availability{
		Kind:    engine.KindXray,
		Usable:  true,
		Version: engine.Version{Raw: "26.3.27", Major: 26, Minor: 3, Patch: 27},
	}

	t.Run("advertised when a chain-capable engine is usable", func(t *testing.T) {
		s := &Server{version: v, measurer: stubChainMeasurer{avail: []engine.Availability{xray}}}
		if !chainsAdvertised(s) {
			t.Fatalf("capabilities = %v, want \"chains\"", s.apiVersion().GetCapabilities())
		}
	})
	t.Run("absent when no engine is usable", func(t *testing.T) {
		broken := xray
		broken.Usable = false
		s := &Server{version: v, measurer: stubChainMeasurer{avail: []engine.Availability{broken}}}
		if chainsAdvertised(s) {
			t.Fatalf("capabilities = %v, want no \"chains\"", s.apiVersion().GetCapabilities())
		}
	})
	t.Run("absent when measurer exposes no availability", func(t *testing.T) {
		s := &Server{version: v, measurer: stubPlainMeasurer{}}
		if chainsAdvertised(s) {
			t.Fatalf("capabilities = %v, want no \"chains\"", s.apiVersion().GetCapabilities())
		}
	})
	t.Run("absent when measurer is nil", func(t *testing.T) {
		s := &Server{version: v}
		if chainsAdvertised(s) {
			t.Fatalf("capabilities = %v, want no \"chains\"", s.apiVersion().GetCapabilities())
		}
	})
}
