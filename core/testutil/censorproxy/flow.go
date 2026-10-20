package censorproxy

import "time"

// Direction is the packet direction relative to the client that initiated
// the flow.
type Direction int

const (
	// Outbound is client -> server.
	Outbound Direction = iota
	// Inbound is server -> client.
	Inbound
)

// Packet is one observed L4 packet.
type Packet struct {
	Dir Direction
	// Size is the L4 payload size in bytes (headers excluded).
	Size int
	// At is the capture timestamp, relative to the flow start.
	At time.Duration
	// Payload is the raw L4 payload; nil when unavailable. Detectors that
	// need payload (ClientHello extraction) skip packets with nil payload.
	Payload []byte
}

// Flow is the classifier input: an ordered packet capture of one connection.
type Flow struct {
	Packets []Packet
}

// Config tunes the stand for one run.
type Config struct {
	// Profile is the uTLS profile name the JA4 detector assesses the
	// observed ClientHello against (e.g. "chrome"); empty selects "chrome".
	Profile string
	// DestHost is the expected destination host for the SNI-consistency
	// detector; empty marks that detector insufficient.
	DestHost string
	// MinPackets is the minimum flow length for a verdict; shorter flows
	// are "insufficient data", never "clean". Zero selects DefaultMinPackets.
	MinPackets int
	// FirstN bounds the "early" window L1 heuristics look at. Zero selects
	// DefaultFirstN.
	FirstN int
}

// DefaultMinPackets is the minimum flow length (spec §3.3: Wu et al.
// heuristics are noisy on short flows).
const DefaultMinPackets = 50

// DefaultFirstN is the number of leading packets L1 heuristics examine.
const DefaultFirstN = 20

func (c Config) withDefaults() Config {
	if c.MinPackets <= 0 {
		c.MinPackets = DefaultMinPackets
	}
	if c.FirstN <= 0 {
		c.FirstN = DefaultFirstN
	}
	return c
}

// outbound returns the outbound packets of the flow in order.
func (f *Flow) outbound() []Packet {
	var out []Packet
	for _, p := range f.Packets {
		if p.Dir == Outbound {
			out = append(out, p)
		}
	}
	return out
}
