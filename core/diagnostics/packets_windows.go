//go:build windows

package diagnostics

import (
	"bytes"
	"context"
	"fmt"
	"net"
	"os"
	"runtime"
	"strings"
	"sync"
	"sync/atomic"
	"time"
	"unsafe"

	"github.com/gopacket/gopacket"
	"github.com/gopacket/gopacket/layers"
	"github.com/gopacket/gopacket/pcapgo"
	"golang.org/x/sys/windows"

	"github.com/levvs-one/sora-client/core/errs"
)

// These layouts are the documented Pktmon streaming ABI. Handles belong only
// to our independent session: no global CLI capture, filters or ETW logger.
type packetStreamConfig struct {
	Context, Event, Data   uintptr
	Multiplier, Truncation uint16
}
type packetDescriptor struct {
	Data                                                                      unsafe.Pointer
	Size, MetadataOffset, PacketOffset, PacketLength, MissedWrite, MissedRead uint32
}
type packetMetadata struct {
	Group                                                         uint64
	Count, Appearance, Direction, Type, Component, Edge, Reserved uint16
	DropReason, DropLocation                                      uint32
	Processor                                                     uint16
	// Windows uses 8-byte alignment for LARGE_INTEGER on both x86 and x64.
	_         [6]byte
	Timestamp uint64
}
type packetSource struct {
	Kind                               uint32
	Name                               [64]uint16
	Description                        [128]uint16
	ID, SecondaryID, ParentID, Present uint32
	// The Detail union contains ULONGLONG, which has 8-byte MSVC alignment.
	_      [4]byte
	Detail [2]uint64
}
type capturedPacket struct {
	data     []byte
	time     time.Time
	original int
	ethernet bool
}
type packetStream struct {
	packets  chan capturedPacket
	failures chan error
	dropped  atomic.Uint64
}

var packetStreams sync.Map
var packetStreamID atomic.Uintptr

// Windows callbacks cannot be freed. Register one pair for the process, and
// keep per-capture state in a bounded-lifetime registry instead of closures.
var packetDataCallback = windows.NewCallback(func(owner uintptr, descriptor *packetDescriptor) uintptr {
	value, ok := packetStreams.Load(owner)
	if !ok || descriptor == nil || descriptor.Data == nil {
		return 0
	}
	stream := value.(*packetStream)
	if descriptor.Size > 32768 || descriptor.MetadataOffset > descriptor.Size ||
		uint32(unsafe.Sizeof(packetMetadata{})) > descriptor.Size-descriptor.MetadataOffset || descriptor.PacketOffset >= descriptor.Size {
		return 0
	}
	data := unsafe.Slice((*byte)(descriptor.Data), int(descriptor.Size))
	meta := (*packetMetadata)(unsafe.Add(descriptor.Data, descriptor.MetadataOffset))
	if meta.Type != 1 && meta.Type != 3 {
		return 0
	}
	size := min(int(descriptor.PacketLength), int(descriptor.Size-descriptor.PacketOffset), 256)
	if size == 0 {
		return 0
	}
	stamp := windows.Filetime{LowDateTime: uint32(meta.Timestamp), HighDateTime: uint32(meta.Timestamp >> 32)}
	packet := capturedPacket{data: bytes.Clone(data[int(descriptor.PacketOffset) : int(descriptor.PacketOffset)+size]),
		time: time.Unix(0, stamp.Nanoseconds()), original: int(descriptor.PacketLength), ethernet: meta.Type == 1}
	stream.dropped.Add(uint64(descriptor.MissedWrite) + uint64(descriptor.MissedRead))
	select {
	case stream.packets <- packet:
	default:
		stream.dropped.Add(1)
	}
	return 0
})
var packetEventCallback = windows.NewCallback(func(owner uintptr, info unsafe.Pointer, kind uint32) uintptr {
	if kind != 2 || info == nil {
		return 0
	}
	if value, ok := packetStreams.Load(owner); ok {
		reason := *(*uint32)(unsafe.Add(info, 4))
		select {
		case value.(*packetStream).failures <- fmt.Errorf("Pktmon stream failed: %d", reason):
		default:
		}
	}
	return 0
})

// CapturePackets uses the in-box multisession API and closes only its own
// monitor, stream and session. An absent API is reported rather than falling
// back to a global capture that might belong to another application.
func CapturePackets(ctx context.Context, device string, duration time.Duration) ([]byte, error) {
	if err := ctx.Err(); err != nil {
		return nil, errs.Wrap(err, errs.CodeCancelled, errs.KeyCancelled)
	}
	adapter, err := net.InterfaceByName(device)
	if err != nil {
		return nil, errs.Wrap(err, errs.CodeUnavailable, errs.KeyDiagnosticsFailed)
	}
	var guid windows.GUID
	adapterSize := uint32(15000)
	for {
		if adapterSize > 2<<20 {
			return nil, errs.Newf(errs.CodeUnavailable, errs.KeyDiagnosticsFailed, "Windows returned an oversized adapter list")
		}
		adapters := make([]byte, adapterSize)
		first := (*windows.IpAdapterAddresses)(unsafe.Pointer(&adapters[0]))
		err := windows.GetAdaptersAddresses(windows.AF_UNSPEC, windows.GAA_FLAG_INCLUDE_ALL_INTERFACES, 0, first, &adapterSize)
		if err == windows.ERROR_BUFFER_OVERFLOW {
			continue
		}
		if err != nil {
			return nil, errs.Wrap(err, errs.CodeUnavailable, errs.KeyDiagnosticsFailed)
		}
		found := false
		for current := first; current != nil; current = current.Next {
			if current.IfIndex != uint32(adapter.Index) || !strings.EqualFold(windows.UTF16PtrToString(current.FriendlyName), device) {
				continue
			}
			guid, err = windows.GUIDFromString("{" + strings.Trim(windows.BytePtrToString(current.AdapterName), "{}") + "}")
			if err != nil {
				return nil, err
			}
			found = true
			break
		}
		runtime.KeepAlive(adapters)
		if !found {
			return nil, errs.Newf(errs.CodeUnavailable, errs.KeyDiagnosticsFailed, "Windows has no GUID for the owned Sora adapter")
		}
		break
	}
	dll := windows.NewLazySystemDLL("pktmonapi.dll")
	names := []string{"PacketMonitorInitialize", "PacketMonitorUninitialize", "PacketMonitorCreateLiveSession",
		"PacketMonitorCloseSessionHandle", "PacketMonitorEnumDataSources", "PacketMonitorAddSingleDataSourceToSession",
		"PacketMonitorCreateRealtimeStream", "PacketMonitorCloseRealtimeStream", "PacketMonitorAttachOutputToSession", "PacketMonitorSetSessionActive"}
	procedures := make(map[string]*windows.LazyProc, len(names))
	for _, name := range names {
		proc := dll.NewProc(name)
		if err := proc.Find(); err != nil {
			return nil, errs.Wrap(err, errs.CodeUnsupported, errs.KeyDiagnosticsFailed)
		}
		procedures[name] = proc
	}
	call := func(name string, args ...uintptr) error {
		result, _, _ := procedures[name].Call(args...)
		if int32(result) < 0 {
			return errs.Newf(errs.CodeUnavailable, errs.KeyDiagnosticsFailed, "%s failed: HRESULT 0x%08x", name, uint32(result))
		}
		return nil
	}
	var monitor, session, streamHandle windows.Handle
	if err := call("PacketMonitorInitialize", 0x00010000, 0, uintptr(unsafe.Pointer(&monitor))); err != nil {
		return nil, err
	}
	defer procedures["PacketMonitorUninitialize"].Call(uintptr(monitor))
	owner := packetStreamID.Add(1)
	stream := &packetStream{packets: make(chan capturedPacket, 128), failures: make(chan error, 1)}
	packetStreams.Store(owner, stream)
	defer packetStreams.Delete(owner)
	name, _ := windows.UTF16PtrFromString(fmt.Sprintf("Sora-%d-%d", os.Getpid(), owner))
	if err := call("PacketMonitorCreateLiveSession", uintptr(monitor), uintptr(unsafe.Pointer(name)), uintptr(unsafe.Pointer(&session))); err != nil {
		return nil, err
	}
	defer procedures["PacketMonitorCloseSessionHandle"].Call(uintptr(session))
	var needed uintptr
	// The first call reports required bytes with ERROR_INSUFFICIENT_BUFFER.
	_, _, _ = procedures["PacketMonitorEnumDataSources"].Call(uintptr(monitor), 1, 0, 0, uintptr(unsafe.Pointer(&needed)), 0)
	if needed < 16 || needed > 2<<20 {
		return nil, errs.Newf(errs.CodeUnavailable, errs.KeyDiagnosticsFailed, "Pktmon returned an invalid data-source buffer size")
	}
	sources := make([]byte, needed)
	if err := call("PacketMonitorEnumDataSources", uintptr(monitor), 1, 0, needed, uintptr(unsafe.Pointer(&needed)), uintptr(unsafe.Pointer(&sources[0]))); err != nil {
		return nil, err
	}
	count := *(*uint32)(unsafe.Pointer(&sources[0]))
	offset := unsafe.Sizeof(uintptr(0))
	if count > 4096 || offset+uintptr(count)*unsafe.Sizeof(uintptr(0)) > uintptr(len(sources)) {
		return nil, errs.Newf(errs.CodeUnavailable, errs.KeyDiagnosticsFailed, "Pktmon returned an invalid data-source list")
	}
	start, end := uintptr(unsafe.Pointer(&sources[0])), uintptr(unsafe.Pointer(&sources[0]))+uintptr(len(sources))
	selected := false
	for _, pointer := range unsafe.Slice((*unsafe.Pointer)(unsafe.Add(unsafe.Pointer(&sources[0]), offset)), int(count)) {
		address := uintptr(pointer)
		if address < start || address+unsafe.Sizeof(packetSource{}) > end {
			continue
		}
		source := (*packetSource)(pointer)
		if source.Kind != 1 || source.Present&1 == 0 ||
			!bytes.Equal(unsafe.Slice((*byte)(unsafe.Pointer(&source.Detail[0])), 16), unsafe.Slice((*byte)(unsafe.Pointer(&guid)), 16)) {
			continue
		}
		if err := call("PacketMonitorAddSingleDataSourceToSession", uintptr(session), address); err != nil {
			return nil, err
		}
		selected = true
	}
	runtime.KeepAlive(sources)
	if !selected {
		return nil, errs.Newf(errs.CodeUnavailable, errs.KeyDiagnosticsFailed, "Pktmon has no data source matching the owned Sora adapter")
	}
	config := packetStreamConfig{Context: owner, Event: packetEventCallback, Data: packetDataCallback, Multiplier: 1, Truncation: 256}
	if err := call("PacketMonitorCreateRealtimeStream", uintptr(monitor), uintptr(unsafe.Pointer(&config)), uintptr(unsafe.Pointer(&streamHandle))); err != nil {
		return nil, err
	}
	defer procedures["PacketMonitorCloseRealtimeStream"].Call(uintptr(streamHandle))
	if err := call("PacketMonitorAttachOutputToSession", uintptr(session), uintptr(streamHandle)); err != nil {
		return nil, err
	}
	if err := call("PacketMonitorSetSessionActive", uintptr(session), 1); err != nil {
		return nil, err
	}
	defer procedures["PacketMonitorSetSessionActive"].Call(uintptr(session), 0)
	var output bytes.Buffer
	writer, err := pcapgo.NewNgWriterInterface(&output, pcapgo.NgInterface{Name: device, Description: "Sora TUN", LinkType: layers.LinkTypeRaw, SnapLength: 256},
		pcapgo.NgWriterOptions{SectionInfo: pcapgo.NgSectionInfo{Application: "Sora " + coreVersion}})
	if err != nil {
		return nil, err
	}
	ethernet, err := writer.AddInterface(pcapgo.NgInterface{Name: device, Description: "Sora TUN Ethernet", LinkType: layers.LinkTypeEthernet, SnapLength: 256})
	if err != nil {
		return nil, err
	}
	if err := writer.Flush(); err != nil {
		return nil, err
	}
	clock := time.NewTimer(duration)
	defer clock.Stop()
	size := output.Len()
	started := time.Now()
	received := [2]uint64{}
	done := false
	for !done {
		select {
		case <-ctx.Done():
			return nil, errs.Wrap(ctx.Err(), errs.CodeCancelled, errs.KeyCancelled)
		case err := <-stream.failures:
			return nil, errs.Wrap(err, errs.CodeUnavailable, errs.KeyDiagnosticsFailed)
		case <-clock.C:
			done = true
		case packet := <-stream.packets:
			if size+len(packet.data)+64+512 > DefaultMaxArchiveBytes {
				done = true
				break
			}
			index := 0
			if packet.ethernet {
				index = ethernet
			}
			if err := writer.WritePacket(gopacket.CaptureInfo{Timestamp: packet.time, CaptureLength: len(packet.data), Length: packet.original, InterfaceIndex: index}, packet.data); err != nil {
				return nil, err
			}
			size += len(packet.data) + 64
			received[index]++
		}
	}
	if err := call("PacketMonitorSetSessionActive", uintptr(session), 0); err != nil {
		return nil, err
	}
	for index, count := range received {
		if err := writer.WriteInterfaceStats(index, pcapgo.NgInterfaceStatistics{LastUpdate: time.Now(), StartTime: started, EndTime: time.Now(),
			PacketsReceived: count, PacketsDropped: pcapgo.NgNoValue64, Comment: fmt.Sprintf("Stream reports %d missed packets across both link types", stream.dropped.Load())}); err != nil {
			return nil, err
		}
	}
	if err := writer.Flush(); err != nil {
		return nil, err
	}
	return output.Bytes(), nil
}
