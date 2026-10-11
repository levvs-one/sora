//go:build linux

package diagnostics

import (
	"bytes"
	"context"
	"time"

	"github.com/gopacket/gopacket/layers"
	"github.com/gopacket/gopacket/pcapgo"

	"github.com/levvs-one/sora-client/core/errs"
)

// CapturePackets reads only the interface owned by the authenticated session.
// A short snap length keeps packet headers useful without retaining full bodies.
func CapturePackets(ctx context.Context, device string, duration time.Duration) ([]byte, error) {
	handle, err := pcapgo.NewEthernetHandle(device)
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeUnavailable, errs.KeyDiagnosticsFailed)
	}
	defer func() { _ = handle.Close() }()
	if err := handle.SetCaptureLength(256); err != nil {
		return nil, err
	}
	capture, cancel := context.WithTimeout(ctx, duration)
	defer cancel()
	stop := context.AfterFunc(capture, func() { _ = handle.Close() })
	defer stop()
	var output bytes.Buffer
	writer, err := pcapgo.NewNgWriterInterface(&output,
		pcapgo.NgInterface{Name: device, Description: "Sora TUN", LinkType: layers.LinkTypeRaw, SnapLength: 256},
		pcapgo.NgWriterOptions{SectionInfo: pcapgo.NgSectionInfo{Application: "Sora " + coreVersion}})
	if err != nil {
		return nil, err
	}
	if err := writer.Flush(); err != nil {
		return nil, err
	}
	size := output.Len()
	for {
		data, info, readErr := handle.ZeroCopyReadPacketData()
		if readErr != nil {
			if ctx.Err() != nil {
				return nil, errs.Wrap(ctx.Err(), errs.CodeCancelled, errs.KeyCancelled)
			}
			if capture.Err() != nil {
				break
			}
			return nil, errs.Wrap(readErr, errs.CodeUnavailable, errs.KeyDiagnosticsFailed)
		}
		if ctx.Err() != nil {
			return nil, errs.Wrap(ctx.Err(), errs.CodeCancelled, errs.KeyCancelled)
		}
		if size+len(data)+64 > DefaultMaxArchiveBytes {
			break
		}
		info.InterfaceIndex = 0
		if err := writer.WritePacket(info, data); err != nil {
			return nil, err
		}
		size += len(data) + 64
	}
	if err := writer.Flush(); err != nil {
		return nil, err
	}
	return output.Bytes(), nil
}
