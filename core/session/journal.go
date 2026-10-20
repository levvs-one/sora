package session

import (
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/censor"
	"github.com/levvs-one/sora-client/core/errs"
	"github.com/levvs-one/sora-client/core/profiles"
)

// EventKind maps session events to CoreEvent oneof fields for control-plane
// translation.
type EventKind string

// Kinds of session event.
const (
	EventState    EventKind = "state"
	EventCounters EventKind = "counters"
	EventLog      EventKind = "log"
	EventProbe    EventKind = "probe"
	EventError    EventKind = "error"
	EventGroup    EventKind = "group"
	// EventNetwork marks a detected network change (interface/gateway
	// switch). Detail carries the new network fingerprint.
	EventNetwork EventKind = "network"
	// EventProfile marks a network profile matching the current network
	// (F5). Profile carries the match; the client applies it.
	EventProfile EventKind = "profile"
	// EventCensor carries a censorship verdict for a failed connection
	// attempt (SW4). Censor holds the structured verdict; Detail holds the
	// user-facing line the control plane surfaces through the event stream.
	EventCensor EventKind = "censor"
)

// Event records a session change. Journal-assigned sequence numbers increase
// within the session so clients can resume streams after reconnecting.
type Event struct {
	Sequence uint64
	At       time.Time
	Kind     EventKind
	State    State
	Reason   errs.Code
	Key      errs.Key
	Detail   string
	Counters Counters
	Probe    *ProbeOutcome
	Switch   *GroupSwitch
	Profile  *profiles.Match
	// Censor is set for EventCensor: the detector's verdict about a failed
	// connection attempt.
	Censor     *censor.Verdict
	RetryAfter time.Duration
	LogLine    string
}

// GroupSwitch is a fallback group that moved to another member on its own.
// Members are outbound ids or names of nested groups.
type GroupSwitch struct {
	Group    string
	Previous string
	Selected string
}

// Counters defines session traffic totals independently of engine types to
// preserve the client contract.
type Counters struct {
	BytesUp           uint64
	BytesDown         uint64
	ActiveConnections int
	At                time.Time
}

// ProbeOutcome carries latency results with their session-known server
// identity, avoiding reconstruction by the control plane.
type ProbeOutcome struct {
	ServerID  string
	Reachable bool
	LatencyMS int
	Err       error
}

// Journal stores bounded session history and publishes without blocking. Slow
// subscribers lose counted events; clients reconcile gaps with a fresh status
// snapshot.
type Journal struct {
	mu       sync.Mutex
	next     uint64
	capacity int
	history  []Event
	subs     map[*subscription]struct{}
	dropped  uint64
}

// subscription is one live listener. The closed flag is set under the
// journal mutex; the channel itself is never closed, because Append may
// hold a copied reference and closing it would race the send and panic
// the whole core (SORA-H6). Consumers terminate on context cancellation.
type subscription struct {
	ch     chan Event
	closed bool
}

// DefaultJournalCapacity retains roughly a minute of counters and state changes
// for client reattachment.
const DefaultJournalCapacity = 512

// NewJournal returns a journal that keeps capacity events of history.
// The history buffer starts small and grows with the session: allocating
// the full capacity up front costs a ~100 KB zeroed pointerful slice on
// every session start, and most of that work is pure memclr/GC pressure.
// The steady state is unchanged — once full, trimming keeps the retained
// capacity exactly as before.
func NewJournal(capacity int) *Journal {
	if capacity <= 0 {
		capacity = DefaultJournalCapacity
	}
	initial := min(capacity, 64)
	return &Journal{
		capacity: capacity,
		history:  make([]Event, 0, initial),
		subs:     make(map[*subscription]struct{}),
	}
}

// Append assigns sequence and time, stores and publishes the event, and returns
// the stamped value for log correlation. Publishing holds the mutex for the
// whole send loop: sends are non-blocking, and no unsubscribe can interleave
// between the subscriber snapshot and the send (SORA-H6).
func (j *Journal) Append(ev Event) Event {
	j.mu.Lock()
	defer j.mu.Unlock()
	j.next++
	ev.Sequence = j.next
	if ev.At.IsZero() {
		ev.At = time.Now()
	}
	j.history = append(j.history, ev)
	if len(j.history) > j.capacity {
		// Trim history without reallocating the slice on every counter
		// tick.
		j.history = append(j.history[:0], j.history[len(j.history)-j.capacity:]...)
	}
	for sub := range j.subs {
		if sub.closed {
			continue
		}
		select {
		case sub.ch <- ev:
		default:
			j.dropped++
		}
	}
	return ev
}

// Since returns retained events after the cursor, oldest first, up to limit.
// Clients beyond retained history need a status snapshot; drop counts signal
// incomplete delivery.
func (j *Journal) Since(after uint64, limit int) []Event {
	j.mu.Lock()
	defer j.mu.Unlock()
	if limit <= 0 || limit > j.capacity {
		limit = j.capacity
	}
	// Capacity hint only: never reserve more than the retained history
	// can fill. Callers pass the journal cap as the limit even for a
	// young session holding a handful of events, and Event is a large
	// struct — reserving the full limit allocates ~100 KB to return
	// three events (the censor ingest path hits exactly this).
	out := make([]Event, 0, min(limit, len(j.history)))
	for _, ev := range j.history {
		if ev.Sequence <= after {
			continue
		}
		out = append(out, ev)
		if len(out) == limit {
			break
		}
	}
	return out
}

// Latest returns the newest event sequence for stream resumption.
func (j *Journal) Latest() uint64 {
	j.mu.Lock()
	defer j.mu.Unlock()
	return j.next
}

// Dropped counts missed subscriber events so clients can detect incomplete
// state.
func (j *Journal) Dropped() uint64 {
	j.mu.Lock()
	defer j.mu.Unlock()
	return j.dropped
}

// Subscribe creates a buffered live listener. The returned cancellation
// function unregisters it safely on repeated calls. The channel is never
// closed (see subscription); consumers must stop on context cancellation.
func (j *Journal) Subscribe(buffer int) (<-chan Event, func()) {
	if buffer <= 0 {
		buffer = 64
	}
	sub := &subscription{ch: make(chan Event, buffer)}
	j.mu.Lock()
	j.subs[sub] = struct{}{}
	j.mu.Unlock()
	var once sync.Once
	cancel := func() {
		once.Do(func() {
			j.mu.Lock()
			defer j.mu.Unlock()
			sub.closed = true
			delete(j.subs, sub)
		})
	}
	return sub.ch, cancel
}
