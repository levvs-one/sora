package supervise

import (
	"fmt"
	"net"
	"testing"
)

func TestFreePortCanBindTCPAndUDP(t *testing.T) {
	for range 32 {
		port, err := FreePort()
		if err != nil {
			t.Fatal(err)
		}
		address := fmt.Sprintf("127.0.0.1:%d", port)
		var lc net.ListenConfig
		packet, err := lc.ListenPacket(t.Context(), "udp", address)
		if err != nil {
			t.Fatalf("the selected port cannot bind UDP: %v", err)
		}
		listener, err := lc.Listen(t.Context(), "tcp", address)
		_ = packet.Close()
		if err != nil {
			t.Fatalf("the selected port cannot bind TCP: %v", err)
		}
		_ = listener.Close()
	}
}
