package transport

import (
	"context"
	"net"
	"testing"
	"time"

	"github.com/levvs-one/sora-client/sync/pairing"
)

func TestKnownHandshakeRejectsAnnouncedKeyMismatch(t *testing.T) {
	for _, side := range []string{"initiator", "responder"} {
		t.Run(side, func(t *testing.T) {
			a, privA, err := pairing.Generate("a")
			if err != nil {
				t.Fatal(err)
			}
			b, privB, err := pairing.Generate("b")
			if err != nil {
				t.Fatal(err)
			}
			selfA := Identity{DeviceID: "a", PublicKey: a.PublicKey}
			selfB := Identity{DeviceID: "b", PublicKey: b.PublicKey}
			if side == "initiator" {
				selfA.PublicKey = b.PublicKey
			} else {
				selfB.PublicKey = a.PublicKey
			}
			rawA, rawB := net.Pipe()
			defer func() { _ = rawA.Close(); _ = rawB.Close() }()
			ctx, cancel := context.WithTimeout(context.Background(), time.Second)
			defer cancel()
			accepted := make(chan error, 1)
			go func() {
				_, err := AcceptKnown(ctx, rawB, privB, selfB, func(k [32]byte) bool { return k == a.PublicKey })
				accepted <- err
			}()
			_, dialErr := DialKnown(ctx, rawA, b.PublicKey, privA, selfA)
			acceptErr := <-accepted
			if side == "initiator" && acceptErr == nil {
				t.Fatal("accepted identity key unrelated to Noise static key")
			}
			if side == "responder" && dialErr == nil {
				t.Fatal("dial accepted identity key unrelated to Noise static key")
			}
		})
	}
}
