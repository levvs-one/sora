//go:build linux

package interop_test

import (
	"net"
	"os"
	"strings"
	"sync"
	"syscall"
	"testing"
	"unsafe"

	"golang.org/x/sys/unix"
)

// CENSOR-P4 fix M1: the AWG traffic test may SKIP only on an exact
// signature that THIS environment denies sendmmsg — never on the
// mere presence of a seccomp filter (the default Docker profile
// filters syscalls yet allows sendmmsg, and a real AWG failure
// there must stay a failure). One exact signature is the engine
// log line (sandboxBlocksSendmmsg); this direct probe is the
// other: the test process itself attempts one sendmmsg of a single
// byte to its own loopback UDP socket and checks the errno. Only
// EPERM — the sandbox profile's denial — counts; any other outcome
// (success, or an unrelated error) means the traffic proof runs.
var (
	sendmmsgProbeOnce  sync.Once
	sendmmsgProbeEPERM bool
)

func sendmmsgDenied() bool {
	sendmmsgProbeOnce.Do(func() {
		sendmmsgProbeEPERM = probeSendmmsg() == syscall.EPERM
	})
	return sendmmsgProbeEPERM
}

// TestSendmmsgDeniedNeedsTheSignature pins the M1 discrimination:
// the probe may report a denial only when sendmmsg itself returns
// EPERM. With no seccomp filter on the process at all a denial is
// impossible to attribute to a profile, so the probe must say "not
// denied" — a host under an unrelated ALLOWING filter (default
// Docker) is exactly the case that must run the traffic proof.
func TestSendmmsgDeniedNeedsTheSignature(t *testing.T) {
	b, err := os.ReadFile("/proc/self/status")
	if err != nil {
		t.Skip("no /proc/self/status to read")
	}
	if strings.Contains(string(b), "Seccomp:\t0\n") && sendmmsgDenied() {
		t.Fatal("sendmmsg reported denied with no seccomp filter on the process")
	}
	// The cached probe result must agree with a fresh raw attempt.
	if denied := probeSendmmsg() == syscall.EPERM; denied != sendmmsgDenied() {
		t.Fatalf("probe cache disagrees with a fresh attempt: fresh EPERM=%v, cached=%v", denied, sendmmsgDenied())
	}
}

func probeSendmmsg() error {
	conn, err := net.ListenPacket("udp", "127.0.0.1:0")
	if err != nil {
		return err
	}
	defer func() { _ = conn.Close() }()
	port := conn.LocalAddr().(*net.UDPAddr).Port
	raw, err := conn.(syscall.Conn).SyscallConn()
	if err != nil {
		return err
	}
	payload := []byte{0}
	iov := &unix.Iovec{Base: &payload[0], Len: 1}
	rsa := &unix.RawSockaddrInet4{
		Family: unix.AF_INET,
		Port:   uint16(port<<8 | port>>8), // network byte order
		Addr:   [4]byte{127, 0, 0, 1},
	}
	msg := unix.Mmsghdr{
		Hdr: unix.Msghdr{
			Name:    (*byte)(unsafe.Pointer(rsa)),
			Namelen: uint32(unsafe.Sizeof(*rsa)),
			Iov:     iov,
			Iovlen:  1,
		},
	}
	msgs := []unix.Mmsghdr{msg}
	var sendErr error
	ctrlErr := raw.Control(func(fd uintptr) {
		// x/sys/unix exports the Mmsghdr layout and the syscall
		// number but no Sendmmsg wrapper; call it raw.
		_, _, errno := syscall.Syscall6(unix.SYS_SENDMMSG, fd,
			uintptr(unsafe.Pointer(&msgs[0])), uintptr(len(msgs)), 0, 0, 0)
		if errno != 0 {
			sendErr = errno
		}
	})
	if ctrlErr != nil {
		return ctrlErr
	}
	return sendErr
}
