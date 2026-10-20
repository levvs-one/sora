package supervise

import (
	"encoding/binary"
	"syscall"
	"time"
)

// ProbeHost measures this Linux host's TUN and kernel-WireGuard
// facts BY USE: the TUN node must open, and the kernel must answer
// a generic-netlink query for the "wireguard" family. It never
// loads a module and never creates a device: it reports what is
// there.
func ProbeHost() HostFacts {
	return probeHost(hostProbe{
		tunDevice:       "/dev/net/tun",
		kernelWireGuard: netlinkHasWireGuardFamily,
	})
}

// Generic-netlink constants for the controller family query
// (linux/genetlink.h, linux/netlink.h).
const (
	netlinkGeneric     = 16 // NETLINK_GENERIC
	genlIDCtrl         = 16 // GENL_ID_CTRL
	ctrlCmdGetFamily   = 3  // CTRL_CMD_GETFAMILY
	ctrlAttrFamilyName = 2  // CTRL_ATTR_FAMILY_NAME
	nlmsgError         = 2  // NLMSG_ERROR
	nlmsgFlagRequest   = 0x1
)

// netlinkHasWireGuardFamily asks the kernel's generic-netlink
// controller to resolve the "wireguard" family — the family is
// registered when the WireGuard module loads, so a successful
// resolution is the kernel's own statement that it can serve
// WireGuard, and -ENOENT is its statement that it cannot. This is
// the same question `wg show` asks before touching any device. Any
// environment that will not even let the question be asked (socket
// or send denied) honestly reports "not present": the fact gates
// nothing today (userspace AWG needs no kernel module), and a
// future kernel path must see a confirmed fact, not a guess.
func netlinkHasWireGuardFamily() bool {
	fd, err := syscall.Socket(syscall.AF_NETLINK, syscall.SOCK_RAW, netlinkGeneric)
	if err != nil {
		return false
	}
	defer func() { _ = syscall.Close(fd) }()
	// A wedged kernel path must not wedge discovery: bound the wait.
	tv := syscall.NsecToTimeval((time.Second).Nanoseconds())
	_ = syscall.SetsockoptTimeval(fd, syscall.SOL_SOCKET, syscall.SO_RCVTIMEO, &tv)

	name := "wireguard\x00"
	attrLen := 4 + len(name)
	msgLen := 16 + 4 + attrLen // nlmsghdr + genlmsghdr + attr
	if pad := msgLen % 4; pad != 0 {
		msgLen += 4 - pad
	}
	req := make([]byte, msgLen)
	binary.LittleEndian.PutUint32(req[0:4], uint32(msgLen))
	binary.LittleEndian.PutUint16(req[4:6], genlIDCtrl)
	binary.LittleEndian.PutUint16(req[6:8], nlmsgFlagRequest)
	binary.LittleEndian.PutUint32(req[8:12], 1) // seq
	// req[12:16] pid = 0 (the kernel assigns ours)
	req[16] = ctrlCmdGetFamily
	req[17] = 1 // genl version
	binary.LittleEndian.PutUint16(req[20:22], uint16(attrLen))
	binary.LittleEndian.PutUint16(req[22:24], ctrlAttrFamilyName)
	copy(req[24:], name)

	if err := syscall.Sendto(fd, req, 0, &syscall.SockaddrNetlink{Family: syscall.AF_NETLINK}); err != nil {
		return false
	}
	buf := make([]byte, 4096)
	n, _, err := syscall.Recvfrom(fd, buf, 0)
	if err != nil || n < 20 {
		return false
	}
	resp := buf[:n]
	msgType := binary.LittleEndian.Uint16(resp[4:6])
	if msgType == nlmsgError {
		// NLMSG_ERROR carries a negative errno: -ENOENT means the
		// family is not registered; a zero is a pure ACK (not sent
		// in answer to GETFAMILY without NLM_F_ACK).
		code := int32(binary.LittleEndian.Uint32(resp[16:20]))
		return code == 0
	}
	// A controller reply to our query: genl cmd at offset 16.
	return msgType == genlIDCtrl && resp[16] == ctrlCmdGetFamily &&
		binary.LittleEndian.Uint32(resp[8:12]) == 1 &&
		familyNameAttr(resp) == "wireguard"
}

// familyNameAttr extracts the CTRL_ATTR_FAMILY_NAME value from a
// generic-netlink reply, walking the attribute list after the
// genlmsghdr. Returns "" when absent or malformed.
func familyNameAttr(msg []byte) string {
	off := 20 // nlmsghdr(16) + genlmsghdr(4)
	for off+4 <= len(msg) {
		alen := int(binary.LittleEndian.Uint16(msg[off : off+2]))
		atype := binary.LittleEndian.Uint16(msg[off+2 : off+4])
		if alen < 4 || off+alen > len(msg) {
			return ""
		}
		if atype == ctrlAttrFamilyName {
			return string(trimNUL(msg[off+4 : off+alen]))
		}
		off += (alen + 3) &^ 3
	}
	return ""
}

func trimNUL(b []byte) []byte {
	for len(b) > 0 && b[len(b)-1] == 0 {
		b = b[:len(b)-1]
	}
	return b
}
