package diagnostics_test

import (
	"bytes"
	"context"
	"errors"
	"io"
	"os"
	"sync"
	"testing"
	"time"

	"github.com/gopacket/gopacket"
	"github.com/gopacket/gopacket/layers"
	"github.com/gopacket/gopacket/pcapgo"

	"github.com/levvs-one/sora-client/core/diagnostics"
)

func checkPackets(t *testing.T, data []byte) {
	t.Helper()
	reader, err := pcapgo.NewNgReader(bytes.NewReader(data), pcapgo.NgReaderOptions{WantMixedLinkType: true})
	if err != nil {
		t.Fatal(err)
	}
	count := 0
	for {
		packet, info, err := reader.ReadPacketData()
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			t.Fatal(err)
		}
		if len(packet) > 256 || len(packet) != info.CaptureLength {
			t.Fatalf("unbounded or invalid packet: %+v", info)
		}
		link := reader.LinkType()
		if len(info.AncillaryData) > 0 {
			link = info.AncillaryData[0].(layers.LinkType)
		}
		decoded := gopacket.NewPacket(packet, link, gopacket.Default)
		if decoded.Layer(layers.LayerTypeIPv4) == nil && decoded.Layer(layers.LayerTypeIPv6) == nil {
			t.Fatalf("invalid IP packet: %v", decoded)
		}
		count++
	}
	if count == 0 {
		t.Fatal("capture contains no actual packets")
	}
	t.Logf("verified %d real packets in %d bytes", count, len(data))
}

func TestNativePacketArchive(t *testing.T) {
	path := os.Getenv("SORA_PACKET_ARCHIVE")
	if path == "" {
		t.Skip("requires an archive from the live tunnel test")
	}
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	checkPackets(t, data)
}

func TestNativeIndependentCaptures(t *testing.T) {
	device := os.Getenv("SORA_CAPTURE_DEVICE")
	if device == "" {
		t.Skip("requires the owned adapter in the isolated live tunnel test")
	}
	var wait sync.WaitGroup
	for range 2 {
		wait.Go(func() {
			data, err := diagnostics.CapturePackets(context.Background(), device, 2*time.Second)
			if err != nil {
				t.Error(err)
				return
			}
			checkPackets(t, data)
		})
	}
	wait.Wait()
	canceled, cancel := context.WithCancel(context.Background())
	cancel()
	started := time.Now()
	if _, err := diagnostics.CapturePackets(canceled, device, 10*time.Second); err == nil {
		t.Error("cancelled capture succeeded")
	}
	if time.Since(started) > time.Second {
		t.Error("cancelled capture did not release promptly")
	}
}
