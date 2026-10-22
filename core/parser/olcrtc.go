package parser

import (
	"encoding/hex"
	"net/url"
	"strings"

	"github.com/levvs-one/sora-client/core/engine"
)

// URI v1 is not an RFC URL: a Jitsi room may itself contain :// and /, and
// angle brackets delimit transport parameters. Split before percent decoding.
func parseOLCRTC(raw string) (OutboundSpec, error) {
	payload := raw[len("olcrtc://"):]
	provider, tail, ok := strings.Cut(payload, "?")
	if !ok {
		return OutboundSpec{}, ErrInvalid
	}
	transport, tail, ok := strings.Cut(tail, "@")
	if !ok {
		return OutboundSpec{}, ErrInvalid
	}
	room, tail, ok := strings.Cut(tail, "#")
	if !ok {
		return OutboundSpec{}, ErrInvalid
	}
	key, comment, _ := strings.Cut(tail, "$")
	key, err := url.PathUnescape(key)
	if err != nil {
		return OutboundSpec{}, ErrInvalid
	}
	decoded, err := hex.DecodeString(key)
	if err != nil || len(decoded) != 32 {
		return OutboundSpec{}, ErrInvalid
	}
	c := &engine.OLCRTC{Provider: strings.ToLower(provider), Transport: transport, Parameters: map[string]string{}}
	if name, params, has := strings.Cut(transport, "<"); has {
		if !strings.HasSuffix(params, ">") || strings.Count(params, ">") != 1 || strings.Contains(params, "<") {
			return OutboundSpec{}, ErrInvalid
		}
		c.Transport = name
		params = strings.TrimSuffix(params, ">")
		for _, item := range strings.Split(params, "&") {
			k, v, has := strings.Cut(item, "=")
			if !has || k == "" {
				return OutboundSpec{}, ErrInvalid
			}
			if _, dup := c.Parameters[k]; dup {
				return OutboundSpec{}, ErrInvalid
			}
			v, err = url.PathUnescape(v)
			if err != nil {
				return OutboundSpec{}, ErrInvalid
			}
			// Upstream explicitly retains these old v1 fields as ignored no-ops.
			if c.Transport == "videochannel" && (k == "video-bitrate" || k == "video-hw") {
				continue
			}
			c.Parameters[k] = v
		}
	}
	c.Room, err = url.PathUnescape(room)
	if err != nil {
		return OutboundSpec{}, ErrInvalid
	}
	comment, err = url.PathUnescape(comment)
	if err != nil {
		return OutboundSpec{}, ErrInvalid
	}
	if err = c.Validate(); err != nil {
		return OutboundSpec{}, ErrInvalid
	}
	if len(comment) > engine.MaxNameBytes || strings.ContainsAny(comment, "\r\n\t\x00") {
		return OutboundSpec{}, ErrInvalid
	}
	host := map[string]string{"telemost": "telemost.yandex.ru", "wbstream": "stream.wb.ru"}[c.Provider]
	if c.Provider == "jitsi" {
		roomURL := c.Room
		if !strings.Contains(roomURL, "://") {
			roomURL = "https://" + roomURL
		}
		u, _ := url.Parse(roomURL)
		host = u.Hostname()
	}
	if comment == "" {
		comment = c.Provider + " / " + c.Transport
	}
	o := OutboundSpec{Protocol: "olcrtc", Host: host, Port: 443, Transport: "tcp", Security: "none", Password: strings.ToLower(key), DisplayName: strings.TrimSpace(comment), OLCRTC: c, Options: map[string]string{}}
	o.CountryCode = countryCode(o.DisplayName)
	return o, o.validate()
}
