package api

import (
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"time"

	syncpkg "github.com/levvs-one/sora-client/sync/sync"
)

// maxBody caps API request bodies at 17 MiB (16 MiB documents plus JSON).
const maxBody = 17 << 20

// ServeHTTP starts the localhost control API on 127.0.0.1:0 and returns the
// address. Only the loopback interface listens, and every request needs the
// bearer token from the data directory.
func (d *Daemon) ServeHTTP() (string, error) {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /v1/status", d.handleStatus)
	mux.HandleFunc("POST /v1/pairing/start", d.handlePairingStart)
	mux.HandleFunc("POST /v1/pairing/stop", d.handlePairingStop)
	mux.HandleFunc("POST /v1/pairing/join", d.handlePairingJoin)
	mux.HandleFunc("GET /v1/peers", d.handlePeers)
	mux.HandleFunc("DELETE /v1/peers/{id}", d.handlePeerDelete)
	mux.HandleFunc("POST /v1/peers/{id}/sync", d.handlePeerSync)
	mux.HandleFunc("PUT /v1/documents/{kind}/{name}", d.handleDocPut)
	mux.HandleFunc("GET /v1/documents", d.handleDocs)
	mux.HandleFunc("GET /v1/documents/{kind}/{name}", d.handleDocGet)

	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return "", fmt.Errorf("api: %w", err)
	}
	d.httpListener = listener
	server := &http.Server{
		Handler:      d.withAuth(mux),
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 2 * time.Minute,
	}
	d.wg.Add(1)
	go func() {
		defer d.wg.Done()
		_ = server.Serve(listener)
	}()
	go func() {
		<-d.ctx.Done()
		_ = server.Close()
	}()
	return listener.Addr().String(), nil
}

func (d *Daemon) withAuth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !d.checkToken(r.Header.Get("Authorization")) {
			writeJSON(w, http.StatusUnauthorized, errorResponse{Error: "unauthorized"})
			return
		}
		next.ServeHTTP(w, r)
	})
}

// Typed response bodies replace map[string]any: a map forces an
// interface box and a hash lookup per key on every encode, which the
// UI's status polling paid for on every tick. The JSON keys and value
// types are exactly what the map forms produced.
type errorResponse struct {
	Error string `json:"error"`
}

type okResponse struct {
	OK bool `json:"ok"`
}

type statusResponse struct {
	DeviceID         string `json:"device_id"`
	DeviceName       string `json:"device_name"`
	PairingActive    bool   `json:"pairing_active"`
	PairingExpiresAt int64  `json:"pairing_expires_at"`
	Peers            int    `json:"peers"`
}

type pairingStartResponse struct {
	QRPayload string `json:"qr_payload"`
	ExpiresAt int64  `json:"expires_at"`
}

type pairingJoinResponse struct {
	Peer Peer `json:"peer"`
}

type peersResponse struct {
	Peers []Peer `json:"peers"`
}

type peerSyncResponse struct {
	Pulled []syncpkg.Meta `json:"pulled"`
	Pushed []syncpkg.Meta `json:"pushed"`
}

type docPutResponse struct {
	Changed bool `json:"changed"`
}

type docsResponse struct {
	Docs []syncpkg.Meta `json:"docs"`
}

// docGetResponse carries the payload as []byte so encoding/json
// base64-encodes it directly into the response: the wire form is the
// exact base64 string the manual EncodeToString produced, without
// the extra full-size string copy.
type docGetResponse struct {
	Kind      string `json:"kind"`
	Name      string `json:"name"`
	UpdatedAt int64  `json:"updated_at"`
	From      string `json:"from"`
	Payload   []byte `json:"payload"` // base64 in JSON
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func writeError(w http.ResponseWriter, status int, err error) {
	writeJSON(w, status, errorResponse{Error: err.Error()})
}

func readJSON(w http.ResponseWriter, r *http.Request, v any) bool {
	r.Body = http.MaxBytesReader(w, r.Body, maxBody)
	if err := json.NewDecoder(r.Body).Decode(v); err != nil {
		writeError(w, http.StatusBadRequest, fmt.Errorf("bad JSON: %w", err))
		return false
	}
	return true
}

func (d *Daemon) handleStatus(w http.ResponseWriter, r *http.Request) {
	active, expires := d.PairingActive()
	writeJSON(w, http.StatusOK, statusResponse{
		DeviceID:         d.identity.ID,
		DeviceName:       d.identity.Name,
		PairingActive:    active,
		PairingExpiresAt: expires,
		Peers:            d.peerCount(),
	})
}

func (d *Daemon) handlePairingStart(w http.ResponseWriter, r *http.Request) {
	qr, expires, err := d.StartPairing()
	if err != nil {
		writeError(w, http.StatusConflict, err)
		return
	}
	writeJSON(w, http.StatusOK, pairingStartResponse{
		QRPayload: qr,
		ExpiresAt: expires,
	})
}

func (d *Daemon) handlePairingStop(w http.ResponseWriter, r *http.Request) {
	if err := d.StopPairing(); err != nil {
		writeError(w, http.StatusInternalServerError, err)
		return
	}
	writeJSON(w, http.StatusOK, okResponse{OK: true})
}

func (d *Daemon) handlePairingJoin(w http.ResponseWriter, r *http.Request) {
	var req struct {
		QRPayload string `json:"qr_payload"`
	}
	if !readJSON(w, r, &req) {
		return
	}
	peer, err := d.Join(r.Context(), req.QRPayload)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, pairingJoinResponse{Peer: peer})
}

func (d *Daemon) handlePeers(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, peersResponse{Peers: d.Peers()})
}

func (d *Daemon) handlePeerDelete(w http.ResponseWriter, r *http.Request) {
	revoked, err := d.RevokePeer(r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusInternalServerError, err)
		return
	}
	if !revoked {
		writeError(w, http.StatusNotFound, fmt.Errorf("unknown peer"))
		return
	}
	writeJSON(w, http.StatusOK, okResponse{OK: true})
}

func (d *Daemon) handlePeerSync(w http.ResponseWriter, r *http.Request) {
	pulled, pushed, err := d.SyncPeer(r.Context(), r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, peerSyncResponse{Pulled: pulled, Pushed: pushed})
}

func (d *Daemon) handleDocPut(w http.ResponseWriter, r *http.Request) {
	// Payload is a []byte so the JSON decoder base64-decodes it
	// directly into the final slice: the request wire form is the
	// exact base64 string a string field carried, without the extra
	// full-size string copy a DecodeString pass needed. Invalid
	// base64 now fails the JSON decode in readJSON (still a 400).
	var req struct {
		Payload   []byte `json:"payload"` // base64
		UpdatedAt int64  `json:"updated_at"`
	}
	if !readJSON(w, r, &req) {
		return
	}
	payload := req.Payload
	if len(payload) > 16<<20 {
		writeError(w, http.StatusBadRequest, fmt.Errorf("document exceeds 16 MiB"))
		return
	}
	updatedAt := req.UpdatedAt
	if updatedAt <= 0 {
		updatedAt = time.Now().UnixMilli()
	}
	changed, err := d.store.Put(syncpkg.Document{
		Meta: syncpkg.Meta{
			Kind:      r.PathValue("kind"),
			Name:      r.PathValue("name"),
			UpdatedAt: updatedAt,
			Hash:      syncpkg.HashOf(payload),
		},
		Payload: payload,
		From:    d.identity.ID,
	})
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	writeJSON(w, http.StatusOK, docPutResponse{Changed: changed})
}

func (d *Daemon) handleDocs(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, docsResponse{Docs: d.store.List()})
}

func (d *Daemon) handleDocGet(w http.ResponseWriter, r *http.Request) {
	doc, ok := d.store.Get(r.PathValue("kind"), r.PathValue("name"))
	if !ok {
		writeError(w, http.StatusNotFound, fmt.Errorf("no such document"))
		return
	}
	payload := doc.Payload
	if payload == nil {
		payload = []byte{} // keep "payload":"" in the reply, never null
	}
	writeJSON(w, http.StatusOK, docGetResponse{
		Kind:      doc.Kind,
		Name:      doc.Name,
		UpdatedAt: doc.UpdatedAt,
		From:      doc.From,
		Payload:   payload,
	})
}
