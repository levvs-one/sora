package olcrtc

import (
	"errors"
	"slices"
	"strconv"

	"gopkg.in/yaml.v3"

	"github.com/levvs-one/sora-client/core/engine"
)

// Listener is ephemeral, core-only authentication for the local bridge.
type Listener struct {
	Port               uint16
	Username, Password string
}

// Has reports whether a plan needs an auxiliary olcrtc client.
func Has(p *engine.Plan) bool {
	return p != nil && slices.ContainsFunc(p.Outbounds, func(o engine.Outbound) bool { return o.Protocol == engine.ProtocolOLCRTC })
}

// Rewrite preserves identities and routes while replacing each tunnel with its
// private TCP-only SOCKS bridge. Port 1 is used only by native validation.
func Rewrite(p *engine.Plan, listeners map[string]Listener) *engine.Plan {
	out := *p
	out.Outbounds = slices.Clone(p.Outbounds)
	for i, o := range out.Outbounds {
		if o.Protocol != engine.ProtocolOLCRTC {
			continue
		}
		l, ok := listeners[o.ID]
		if !ok {
			l = Listener{Port: 1, Username: "validation", Password: "validation"}
		}
		out.Outbounds[i] = engine.Outbound{ID: o.ID, Name: o.Name, Protocol: engine.ProtocolSOCKS5, Server: "127.0.0.1", Port: l.Port, UserID: l.Username, Password: l.Password}
	}
	return &out
}

// Render produces only upstream schema fields. yaml.v3 quotes keys, room IDs
// and credentials so imported strings cannot add configuration directives.
func Render(o engine.Outbound, l Listener) ([]byte, error) {
	if err := o.Validate(); err != nil {
		return nil, err
	}
	if o.OLCRTC == nil || l.Port == 0 || len(l.Username) < 32 || len(l.Password) < 32 {
		return nil, errors.New("olcrtc: a private authenticated listener is required")
	}
	c := o.OLCRTC
	cfg := map[string]any{"mode": "cnc", "auth": map[string]any{"provider": c.Provider}, "room": map[string]any{"id": c.Room}, "crypto": map[string]any{"key": o.Password}, "net": map[string]any{"transport": c.Transport, "dns": "8.8.8.8:53"}, "socks": map[string]any{"host": "127.0.0.1", "port": l.Port, "user": l.Username, "pass": l.Password}}
	fields := map[string]string{"vp8-fps": "fps", "vp8-batch": "batch_size", "fps": "fps", "batch": "batch_size", "frag": "fragment_size", "ack-ms": "ack_timeout_ms", "video-w": "width", "video-h": "height", "video-fps": "fps", "video-codec": "codec", "video-qr-size": "qr_size", "video-qr-recovery": "qr_recovery", "video-tile-module": "tile_module", "video-tile-rs": "tile_rs"}
	section := map[string]string{"vp8channel": "vp8", "seichannel": "sei", "videochannel": "video"}[c.Transport]
	if section != "" {
		params := map[string]any{}
		for key, v := range c.Parameters {
			if key == "video-codec" || key == "video-qr-recovery" {
				params[fields[key]] = v
			} else {
				n, _ := strconv.Atoi(v)
				params[fields[key]] = n
			}
		}
		if len(params) > 0 {
			cfg[section] = params
		}
	}
	return yaml.Marshal(cfg)
}
