package engine

import (
	"encoding/hex"
	"errors"
	"net/url"
	"slices"
	"strconv"
	"strings"
	"unicode"
)

// OLCRTC describes URI v1 transport settings. The PSK remains in Outbound.Password
// and the complete document is stored behind the core's credential reference.
type OLCRTC struct {
	Provider   string
	Room       string
	Transport  string
	Parameters map[string]string
}

// Validate bounds the public URI fields before allocating transport buffers.
func (c *OLCRTC) Validate() error {
	if c == nil {
		return errors.New("olcrtc: connection settings are required")
	}
	if !slices.Contains([]string{"jitsi", "telemost", "wbstream"}, c.Provider) {
		return errors.New("olcrtc: unsupported provider")
	}
	if c.Room == "" || len(c.Room) > 2048 || strings.IndexFunc(c.Room, unicode.IsControl) >= 0 || strings.ContainsAny(c.Room, "<>@#$ ") {
		return errors.New("olcrtc: invalid room identifier")
	}
	if c.Provider == "jitsi" {
		room := c.Room
		if !strings.Contains(room, "://") {
			room = "https://" + room
		}
		u, err := url.Parse(room)
		if err != nil || u.Scheme != "https" || u.Hostname() == "" || u.Path == "" || u.Path == "/" || u.User != nil || u.RawQuery != "" || u.Fragment != "" {
			return errors.New("olcrtc: Jitsi needs an HTTPS room URL")
		}
	}
	allowed := map[string][2]int{}
	switch c.Transport {
	case "datachannel":
	case "vp8channel":
		allowed = map[string][2]int{"vp8-fps": {1, 240}, "vp8-batch": {1, 1024}}
	case "seichannel":
		allowed = map[string][2]int{"fps": {1, 240}, "batch": {1, 1024}, "frag": {1, 60000}, "ack-ms": {1, 60000}}
	case "videochannel":
		allowed = map[string][2]int{"video-w": {16, 8192}, "video-h": {16, 8192}, "video-fps": {1, 240}, "video-qr-size": {1, 65535}, "video-tile-module": {1, 270}, "video-tile-rs": {0, 200}}
	default:
		return errors.New("olcrtc: unsupported transport")
	}
	for k, v := range c.Parameters {
		if c.Transport == "videochannel" {
			switch k {
			case "video-codec":
				if !slices.Contains([]string{"qrcode", "tile"}, v) {
					return errors.New("olcrtc: invalid video codec")
				}
				continue
			case "video-qr-recovery":
				if !slices.Contains([]string{"low", "medium", "high", "highest"}, v) {
					return errors.New("olcrtc: invalid QR recovery")
				}
				continue
			}
		}
		bounds, ok := allowed[k]
		n, err := strconv.Atoi(v)
		if !ok || err != nil || n < bounds[0] || n > bounds[1] {
			return errors.New("olcrtc: invalid transport parameter")
		}
	}
	if c.Parameters["video-codec"] == "tile" {
		for _, k := range []string{"video-w", "video-h"} {
			if v := c.Parameters[k]; v != "" && v != "1080" {
				return errors.New("olcrtc: tile requires 1080 by 1080 video")
			}
		}
	}
	return nil
}

func validateOLCRTC(o Outbound) error {
	if err := o.OLCRTC.Validate(); err != nil {
		return err
	}
	key, err := hex.DecodeString(o.Password)
	if err != nil || len(key) != 32 {
		return errors.New("olcrtc: the encryption key must be 32 hexadecimal bytes")
	}
	if o.Via != "" {
		return errors.New("olcrtc: the provider connection cannot dial through another outbound")
	}
	return nil
}
