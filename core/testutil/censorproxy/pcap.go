package censorproxy

import (
	"encoding/binary"
	"fmt"
	"io"
	"net"
	"time"
)

// pcap linktypes we can strip to reach IPv4.
const (
	linkEthernet = 1
	linkRawIP    = 101
	linkIPv4     = 228
)

// ReadPcap reads a classic pcap file (not pcapng) and builds a Flow.
// Only Ethernet (1) and raw-IP (101/228) linktypes with IPv4/TCP are parsed;
// other packets are skipped. Direction is relative to the source IP of the
// first parsed packet (assumed to be the client).
func ReadPcap(r io.Reader) (*Flow, error) {
	hdr := make([]byte, 24)
	if _, err := io.ReadFull(r, hdr); err != nil {
		return nil, fmt.Errorf("pcap: короткий глобальный заголовок: %w", err)
	}
	var bo binary.ByteOrder
	var nanosec bool
	switch binary.LittleEndian.Uint32(hdr[0:4]) {
	case 0xa1b2c3d4:
		bo = binary.BigEndian
	case 0xd4c3b2a1:
		bo = binary.LittleEndian
	case 0xa1b23c4d:
		bo = binary.BigEndian // nanosec
		nanosec = true
	case 0x4d3c2ba1:
		bo = binary.LittleEndian // nanosec
		nanosec = true
	default:
		return nil, fmt.Errorf("pcap: неизвестная магия %x", hdr[0:4])
	}
	linktype := int(bo.Uint32(hdr[20:24]))
	switch linktype {
	case linkEthernet, linkRawIP, linkIPv4:
	default:
		return nil, fmt.Errorf("pcap: неподдерживаемый linktype %d (нужен 1/101/228)", linktype)
	}

	flow := &Flow{}
	var client net.IP
	var t0 time.Time
	first := true
	pktHdr := make([]byte, 16)
	for {
		if _, err := io.ReadFull(r, pktHdr); err == io.EOF || err == io.ErrUnexpectedEOF {
			break
		} else if err != nil {
			return nil, fmt.Errorf("pcap: ошибка заголовка пакета: %w", err)
		}
		tsSec := bo.Uint32(pktHdr[0:4])
		tsFrac := bo.Uint32(pktHdr[4:8])
		incl := bo.Uint32(pktHdr[8:12])
		if incl > 1<<20 {
			return nil, fmt.Errorf("pcap: подозрительная длина пакета %d", incl)
		}
		data := make([]byte, incl)
		if _, err := io.ReadFull(r, data); err != nil {
			return nil, fmt.Errorf("pcap: обрезанный пакет: %w", err)
		}
		src, payload, ok := tcpPayload(data, linktype)
		if !ok {
			continue
		}
		if first {
			client = src
			t0 = time.Unix(int64(tsSec), fracToNanos(tsFrac, nanosec))
			first = false
		}
		ts := time.Unix(int64(tsSec), fracToNanos(tsFrac, nanosec))
		dir := Inbound
		if src.Equal(client) {
			dir = Outbound
		}
		flow.Packets = append(flow.Packets, Packet{
			Dir:     dir,
			Size:    len(payload),
			At:      ts.Sub(t0),
			Payload: payload,
		})
	}
	if len(flow.Packets) == 0 {
		return nil, fmt.Errorf("pcap: не найдено ни одного IPv4/TCP пакета")
	}
	return flow, nil
}

// fracToNanos converts the pcap packet-header fractional timestamp to
// nanoseconds: the fraction is microseconds for classic pcap and already
// nanoseconds for the nanosec magic variants. Getting this wrong inflates
// inter-arrival gaps 1000x and makes every flow look "quiet" to the timing
// heuristic.
func fracToNanos(frac uint32, nanosec bool) int64 {
	if nanosec {
		return int64(frac)
	}
	return int64(frac) * 1000
}

// tcpPayload strips link + IPv4 + TCP headers, returning the source IP and
// the TCP payload. ok=false for non-IPv4/TCP packets.
func tcpPayload(data []byte, linktype int) (src net.IP, payload []byte, ok bool) {
	ip := data
	if linktype == linkEthernet {
		if len(data) < 14 {
			return nil, nil, false
		}
		eth := binary.BigEndian.Uint16(data[12:14])
		off := 14
		if eth == 0x8100 { // 802.1Q VLAN tag
			if len(data) < 18 {
				return nil, nil, false
			}
			eth = binary.BigEndian.Uint16(data[16:18])
			off = 18
		}
		if eth != 0x0800 {
			return nil, nil, false
		}
		ip = data[off:]
	}
	if len(ip) < 20 || ip[0]>>4 != 4 {
		return nil, nil, false
	}
	ihl := int(ip[0]&0x0f) * 4
	if len(ip) < ihl || ip[9] != 6 { // TCP only
		return nil, nil, false
	}
	total := int(binary.BigEndian.Uint16(ip[2:4]))
	if total > len(ip) {
		total = len(ip)
	}
	ip = ip[:total]
	tcp := ip[ihl:]
	if len(tcp) < 20 {
		return nil, nil, false
	}
	doff := int(tcp[12]>>4) * 4
	if len(tcp) < doff {
		return nil, nil, false
	}
	src = make(net.IP, 4)
	copy(src, ip[12:16])
	return src, tcp[doff:], true
}
