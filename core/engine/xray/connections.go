package xray

import (
	"context"
	"encoding/json"
	"regexp"
	"slices"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/engine"
	"github.com/levvs-one/sora-client/core/errs"
)

// Xray has no connection API, but its access log names every flow it opens.
// The list shows what opened in the last minute, without counters.
const (
	seenFor = time.Minute
	seenMax = 512
)

// accessLine reads "from 127.0.0.1:1 accepted tcp:example.com:443 [in -> out]".
var accessLine = regexp.MustCompile(`^from \S+ accepted (tcp|udp):(.+):(\d+) \[[^\]]*?(?:->|>>) *([^\]\s]*)\]`)

// flows remembers recent connections by destination.
type flows struct {
	mu    sync.Mutex
	seen  map[string]engine.Connection
	names map[string]string
	other string
}

// name maps the tags of a plan to the outbound ids the client knows.
func (f *flows) name(p *engine.Plan) {
	names := map[string]string{profileDirect: "direct", profileBlock: "reject", profileZapret: engine.ZapretDirect}
	other := ""
	for i, o := range p.Outbounds {
		names[outboundTag(i)] = o.ID
		if o.Protocol != engine.ProtocolXrayProfile {
			continue
		}
		other = o.ID
		var cfg struct {
			Outbounds []any `json:"outbounds"`
		}
		if json.Unmarshal(o.Profile, &cfg) == nil {
			for _, tag := range freedomTags(cfg.Outbounds) {
				names[tag] = "direct"
			}
		}
	}
	f.mu.Lock()
	defer f.mu.Unlock()
	f.names, f.other = names, other
}

// note records one log line when it opens a connection.
func (f *flows) note(line string, at time.Time) {
	m := accessLine.FindStringSubmatch(line)
	if m == nil {
		return
	}
	port, err := strconv.ParseUint(m[3], 10, 16)
	if err != nil {
		return
	}
	host := strings.Trim(m[2], "[]")
	id := m[1] + ":" + host + ":" + m[3]
	f.mu.Lock()
	defer f.mu.Unlock()
	if f.seen == nil {
		f.seen = map[string]engine.Connection{}
	}
	carrier, ok := f.names[m[4]]
	if !ok {
		carrier = f.other
	}
	if carrier == "" {
		carrier = m[4]
	}
	f.seen[id] = engine.Connection{ID: id, Network: m[1], Host: host, Port: uint16(port), Chain: []string{carrier}, Start: at}
	if len(f.seen) > seenMax {
		f.prune(at.Add(-seenFor))
	}
}

// prune drops what is older than limit, and the oldest entries over seenMax.
func (f *flows) prune(limit time.Time) {
	for id, c := range f.seen {
		if c.Start.Before(limit) {
			delete(f.seen, id)
		}
	}
	for len(f.seen) > seenMax {
		oldest := ""
		for id, c := range f.seen {
			if oldest == "" || c.Start.Before(f.seen[oldest].Start) {
				oldest = id
			}
		}
		delete(f.seen, oldest)
	}
}

func (f *flows) list(now time.Time) []engine.Connection {
	f.mu.Lock()
	defer f.mu.Unlock()
	f.prune(now.Add(-seenFor))
	out := make([]engine.Connection, 0, len(f.seen))
	for _, c := range f.seen {
		out = append(out, c)
	}
	slices.SortFunc(out, func(a, b engine.Connection) int { return b.Start.Compare(a.Start) })
	return out
}

// OutboundConfig shows one server as readable JSON: a profile as the provider
// wrote it, any other server as the Xray outbound Sora would run.
func OutboundConfig(o engine.Outbound) (string, error) {
	var value any
	if o.Protocol == engine.ProtocolXrayProfile {
		if err := json.Unmarshal(o.Profile, &value); err != nil {
			return "", err
		}
	} else {
		r := renderer{plan: &engine.Plan{}, tags: map[string]string{o.ID: "proxy"}, groups: map[string]engine.Group{}, byGroup: map[string]string{}}
		out, err := r.outbound(o)
		if err != nil {
			return "", err
		}
		value = out
	}
	raw, err := json.MarshalIndent(value, "", "  ")
	return string(raw), err
}

// Connections lists what the session opened in the last minute.
func (e *Engine) Connections(context.Context) ([]engine.Connection, error) {
	return e.driver.flows.list(time.Now()), nil
}

// CloseConnection reports that Xray cannot drop one flow.
func (e *Engine) CloseConnection(context.Context, string) error {
	return errs.Newf(errs.CodeUnsupported, errs.KeyConnectionsUnavailable, "xray: a connection cannot be closed")
}

// CloseConnections reports that Xray has no bulk close, so a session restarts it.
func (e *Engine) CloseConnections(context.Context) error {
	return errs.Newf(errs.CodeUnsupported, errs.KeyConnectionsUnavailable, "xray: connections cannot be closed")
}
