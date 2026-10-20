// Package sync implements the document exchange protocol over an encrypted
// transport channel. Documents are opaque blobs (kind, name, payload) — the
// daemon never parses them; the app decides what a kind means. Conflicts
// resolve last-write-wins by updated_at, and the loser is reported so the
// client can notify the user about what arrived.
package sync

import (
	"context"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/levvs-one/sora-client/sync/transport"
)

// Meta describes a document without its payload.
type Meta struct {
	Kind      string `json:"kind"`
	Name      string `json:"name"`
	UpdatedAt int64  `json:"updated_at"` // unix milliseconds
	Hash      string `json:"hash"`       // hex sha256 of the payload
	// From is the device id that sent this copy. Empty in inventories;
	// set on sync reports so the client can show where a document came
	// from.
	From string `json:"from,omitempty"`
}

// Document is one synchronized blob.
type Document struct {
	Meta
	Payload []byte `json:"-"`
	// From is the device id that sent this copy.
	From string `json:"from,omitempty"`
}

// HashOf returns the hex sha256 of a payload.
func HashOf(payload []byte) string {
	sum := sha256.Sum256(payload)
	return hex.EncodeToString(sum[:])
}

// Store keeps the local documents.
type Store interface {
	List() []Meta
	Get(kind, name string) (Document, bool)
	// Put stores the document when it is newer than the stored copy
	// (last-write-wins); it returns whether the stored copy changed.
	Put(doc Document) (bool, error)
}

// wireDoc is the JSON form of a document on the channel.
type wireDoc struct {
	Kind      string `json:"kind"`
	Name      string `json:"name"`
	UpdatedAt int64  `json:"updated_at"`
	Payload   string `json:"payload"` // base64
	From      string `json:"from,omitempty"`
}

func toWire(d Document) wireDoc {
	return wireDoc{
		Kind: d.Kind, Name: d.Name, UpdatedAt: d.UpdatedAt,
		Payload: base64.StdEncoding.EncodeToString(d.Payload), From: d.From,
	}
}

func fromWire(w wireDoc) (Document, error) {
	payload, err := base64.StdEncoding.DecodeString(w.Payload)
	if err != nil {
		return Document{}, fmt.Errorf("sync: bad document payload: %w", err)
	}
	if len(payload) > 16<<20 {
		return Document{}, errors.New("sync: document exceeds 16 MiB")
	}
	return Document{
		Meta: Meta{
			Kind: w.Kind, Name: w.Name, UpdatedAt: w.UpdatedAt,
			Hash: HashOf(payload),
		},
		Payload: payload,
		From:    w.From,
	}, nil
}

// message is one protocol frame.
type message struct {
	T       string   `json:"t"` // hello, inv, get, doc, bye, err
	Device  string   `json:"device,omitempty"`
	Name    string   `json:"name,omitempty"`
	Docs    []Meta   `json:"docs,omitempty"`
	Kind    string   `json:"kind,omitempty"`
	DocName string   `json:"doc_name,omitempty"`
	Doc     *wireDoc `json:"doc,omitempty"`
	Err     string   `json:"err,omitempty"`
}

// Report describes what a sync run changed.
type Report struct {
	// Pulled lists documents fetched from the peer.
	Pulled []Meta
	// Pushed lists documents sent to the peer.
	Pushed []Meta
}

// syncTimeout bounds one document exchange.
const syncTimeout = 2 * time.Minute

// Sync exchanges documents with the peer over conn. The caller drives as the
// initiator; the peer answers reactively. Both sides converge on the newest
// version of every document.
func Sync(ctx context.Context, conn *transport.Conn, selfID string, store Store, initiator bool) (Report, error) {
	ctx, cancel := context.WithTimeout(ctx, syncTimeout)
	defer cancel()
	s := &session{conn: conn, selfID: selfID, store: store}
	if initiator {
		return s.runInitiator(ctx)
	}
	return s.runResponder(ctx)
}

type session struct {
	conn   *transport.Conn
	selfID string
	store  Store
}

func (s *session) send(m message) error {
	raw, err := json.Marshal(m)
	if err != nil {
		return err
	}
	return s.conn.WriteMsg(raw)
}

func (s *session) recv(ctx context.Context) (message, error) {
	type result struct {
		m   message
		err error
	}
	done := make(chan result, 1)
	go func() {
		raw, err := s.conn.ReadMsg()
		if err != nil {
			done <- result{err: err}
			return
		}
		var m message
		if err := json.Unmarshal(raw, &m); err != nil {
			done <- result{err: fmt.Errorf("sync: bad frame: %w", err)}
			return
		}
		done <- result{m: m}
	}()
	select {
	case r := <-done:
		return r.m, r.err
	case <-ctx.Done():
		return message{}, ctx.Err()
	}
}

// runInitiator drives the exchange: hellos, inventories, then pulls and
// pushes computed from both inventories.
func (s *session) runInitiator(ctx context.Context) (Report, error) {
	var rep Report
	if err := s.send(message{T: "hello", Device: s.selfID}); err != nil {
		return rep, err
	}
	m, err := s.recv(ctx)
	if err != nil {
		return rep, err
	}
	if m.T != "hello" || m.Device == "" {
		return rep, fmt.Errorf("sync: expected hello, got %q", m.T)
	}
	local := s.store.List()
	if err := s.send(message{T: "inv", Docs: local}); err != nil {
		return rep, err
	}
	m, err = s.recv(ctx)
	if err != nil {
		return rep, err
	}
	if m.T != "inv" {
		return rep, fmt.Errorf("sync: expected inventory, got %q", m.T)
	}
	peer := m.Docs
	byLocal := index(local)
	byPeer := index(peer)
	// Pull what the peer has newer, push what we have newer or the peer
	// lacks.
	for _, pm := range peer {
		lm, ok := byLocal[docKey{pm.Kind, pm.Name}]
		if !ok || pm.UpdatedAt > lm.UpdatedAt {
			doc, err := s.pull(ctx, pm.Kind, pm.Name)
			if err != nil {
				return rep, err
			}
			changed, err := s.store.Put(doc)
			if err != nil {
				return rep, err
			}
			if changed {
				meta := doc.Meta
				meta.From = doc.From
				rep.Pulled = append(rep.Pulled, meta)
			}
		}
	}
	for _, lm := range local {
		pm, ok := byPeer[docKey{lm.Kind, lm.Name}]
		if !ok || lm.UpdatedAt > pm.UpdatedAt {
			doc, found := s.store.Get(lm.Kind, lm.Name)
			if !found {
				continue
			}
			if err := s.send(message{T: "doc", Doc: ptr(toWire(doc))}); err != nil {
				return rep, err
			}
			rep.Pushed = append(rep.Pushed, doc.Meta)
		}
	}
	if err := s.send(message{T: "bye"}); err != nil {
		return rep, err
	}
	m, err = s.recv(ctx)
	if err != nil {
		return rep, err
	}
	if m.T != "bye" {
		return rep, fmt.Errorf("sync: expected bye, got %q", m.T)
	}
	return rep, nil
}

// pull fetches one document from the peer.
func (s *session) pull(ctx context.Context, kind, name string) (Document, error) {
	if err := s.send(message{T: "get", Kind: kind, DocName: name}); err != nil {
		return Document{}, err
	}
	m, err := s.recv(ctx)
	if err != nil {
		return Document{}, err
	}
	switch m.T {
	case "doc":
		if m.Doc == nil {
			return Document{}, errors.New("sync: empty doc reply")
		}
		return fromWire(*m.Doc)
	case "err":
		return Document{}, fmt.Errorf("sync: peer cannot serve %s/%s: %s", kind, name, m.Err)
	default:
		return Document{}, fmt.Errorf("sync: expected doc, got %q", m.T)
	}
}

// runResponder answers the initiator's requests.
func (s *session) runResponder(ctx context.Context) (Report, error) {
	var rep Report
	m, err := s.recv(ctx)
	if err != nil {
		return rep, err
	}
	if m.T != "hello" || m.Device == "" {
		return rep, fmt.Errorf("sync: expected hello, got %q", m.T)
	}
	if err := s.send(message{T: "hello", Device: s.selfID}); err != nil {
		return rep, err
	}
	m, err = s.recv(ctx)
	if err != nil {
		return rep, err
	}
	if m.T != "inv" {
		return rep, fmt.Errorf("sync: expected inventory, got %q", m.T)
	}
	if err := s.send(message{T: "inv", Docs: s.store.List()}); err != nil {
		return rep, err
	}
	for {
		m, err := s.recv(ctx)
		if err != nil {
			return rep, err
		}
		switch m.T {
		case "get":
			doc, found := s.store.Get(m.Kind, m.DocName)
			if !found {
				if err := s.send(message{T: "err", Err: "no such document"}); err != nil {
					return rep, err
				}
				continue
			}
			if err := s.send(message{T: "doc", Doc: ptr(toWire(doc))}); err != nil {
				return rep, err
			}
		case "doc":
			if m.Doc == nil {
				return rep, fmt.Errorf("sync: empty doc frame")
			}
			doc, err := fromWire(*m.Doc)
			if err != nil {
				return rep, err
			}
			changed, err := s.store.Put(doc)
			if err != nil {
				return rep, err
			}
			if changed {
				meta := doc.Meta
				meta.From = doc.From
				rep.Pulled = append(rep.Pulled, meta)
			}
		case "bye":
			if err := s.send(message{T: "bye"}); err != nil {
				return rep, err
			}
			return rep, nil
		default:
			return rep, fmt.Errorf("sync: unexpected frame %q", m.T)
		}
	}
}

// docKey identifies a document without the string-concatenation allocation
// of a "kind\x00name" key.
type docKey struct {
	kind string
	name string
}

func index(metas []Meta) map[docKey]Meta {
	out := make(map[docKey]Meta, len(metas))
	for _, m := range metas {
		out[docKey{m.Kind, m.Name}] = m
	}
	return out
}

func ptr[T any](v T) *T { return &v }
