package api

import (
	"encoding/base64"
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
			writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
			return
		}
		next.ServeHTTP(w, r)
	})
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

func writeError(w http.ResponseWriter, status int, err error) {
	writeJSON(w, status, map[string]string{"error": err.Error()})
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
	writeJSON(w, http.StatusOK, map[string]any{
		"device_id":          d.identity.ID,
		"device_name":        d.identity.Name,
		"pairing_active":     active,
		"pairing_expires_at": expires,
		"peers":              len(d.Peers()),
	})
}

func (d *Daemon) handlePairingStart(w http.ResponseWriter, r *http.Request) {
	qr, expires, err := d.StartPairing()
	if err != nil {
		writeError(w, http.StatusConflict, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"qr_payload": qr,
		"expires_at": expires,
	})
}

func (d *Daemon) handlePairingStop(w http.ResponseWriter, r *http.Request) {
	if err := d.StopPairing(); err != nil {
		writeError(w, http.StatusInternalServerError, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]bool{"ok": true})
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
	writeJSON(w, http.StatusOK, map[string]any{"peer": peer})
}

func (d *Daemon) handlePeers(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{"peers": d.Peers()})
}

func (d *Daemon) handlePeerDelete(w http.ResponseWriter, r *http.Request) {
	if !d.RevokePeer(r.PathValue("id")) {
		writeError(w, http.StatusNotFound, fmt.Errorf("unknown peer"))
		return
	}
	writeJSON(w, http.StatusOK, map[string]bool{"ok": true})
}

func (d *Daemon) handlePeerSync(w http.ResponseWriter, r *http.Request) {
	pulled, pushed, err := d.SyncPeer(r.Context(), r.PathValue("id"))
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"pulled": pulled, "pushed": pushed})
}

func (d *Daemon) handleDocPut(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Payload   string `json:"payload"` // base64
		UpdatedAt int64  `json:"updated_at"`
	}
	if !readJSON(w, r, &req) {
		return
	}
	payload, err := base64.StdEncoding.DecodeString(req.Payload)
	if err != nil {
		writeError(w, http.StatusBadRequest, fmt.Errorf("bad payload: %w", err))
		return
	}
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
	writeJSON(w, http.StatusOK, map[string]bool{"changed": changed})
}

func (d *Daemon) handleDocs(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{"docs": d.store.List()})
}

func (d *Daemon) handleDocGet(w http.ResponseWriter, r *http.Request) {
	doc, ok := d.store.Get(r.PathValue("kind"), r.PathValue("name"))
	if !ok {
		writeError(w, http.StatusNotFound, fmt.Errorf("no such document"))
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"kind":       doc.Kind,
		"name":       doc.Name,
		"updated_at": doc.UpdatedAt,
		"from":       doc.From,
		"payload":    base64.StdEncoding.EncodeToString(doc.Payload),
	})
}
