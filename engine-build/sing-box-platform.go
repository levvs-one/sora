//go:build android

// Joins the sing-box command when packaging/android/natives.sh builds it, with
// no change to the upstream files. An Android app can neither create a TUN
// device nor read the interface list, so this is the platform sing-box's own
// Android library expects from its app: the adapter arrives as an inherited
// descriptor from VpnService, and the app stays outside its own VPN, so sockets
// need no protection and there is no default interface to follow.
package main

import (
	"context"
	"errors"
	"net"
	"net/netip"
	"os"
	"strconv"
	"sync"
	"syscall"
	"unsafe"

	"github.com/sagernet/sing-box/adapter"
	C "github.com/sagernet/sing-box/constant"
	"github.com/sagernet/sing-box/option"
	tun "github.com/sagernet/sing-tun"
	"github.com/sagernet/sing/common/control"
	"github.com/sagernet/sing/common/logger"
	"github.com/sagernet/sing/common/x/list"
	"github.com/sagernet/sing/service"
	"github.com/spf13/cobra"
	"golang.org/x/sys/unix"
)

var errNotOnAndroid = errors.New("not available in the Sora Android build")

// physical stands for whichever network the phone uses. Android routes this
// app's sockets itself, so nothing binds to it.
var physical = control.Interface{Index: 1, MTU: 1500, Name: "android", Flags: net.FlagUp | net.FlagRunning}

func init() {
	run := mainCommand.PersistentPreRun
	mainCommand.PersistentPreRun = func(cmd *cobra.Command, args []string) {
		run(cmd, args)
		globalCtx = service.ContextWith[adapter.PlatformInterface](globalCtx, &platform{})
	}
}

type platform struct {
	manager   adapter.NetworkManager
	addresses []netip.Addr
}

func (p *platform) Initialize(manager adapter.NetworkManager) error {
	p.manager = manager
	return nil
}

func (*platform) UsePlatformAutoDetectInterfaceControl() bool { return true }

func (*platform) AutoDetectInterfaceControl(int) error { return nil }

func (*platform) UsePlatformInterface() bool { return true }

func (p *platform) OpenInterface(options *tun.Options, _ option.TunPlatformOptions) (tun.Tun, error) {
	fd, err := strconv.Atoi(os.Getenv("SORA_TUN_FD"))
	if err != nil || fd <= 0 {
		return nil, errors.New("the app passed no adapter")
	}
	name, err := adapterName(fd)
	if err != nil {
		return nil, err
	}
	options.Name = name
	options.FileDescriptor = fd
	options.InterfaceMonitor.RegisterMyInterface(name)
	for _, prefix := range append(options.Inet4Address[:len(options.Inet4Address):len(options.Inet4Address)], options.Inet6Address...) {
		p.addresses = append(p.addresses, prefix.Addr())
	}
	return tun.New(*options)
}

func adapterName(fd int) (string, error) {
	var request [unix.IFNAMSIZ + 64]byte
	_, _, errno := unix.Syscall(syscall.SYS_IOCTL, uintptr(fd), uintptr(unix.TUNGETIFF), uintptr(unsafe.Pointer(&request[0])))
	if errno != 0 {
		return "", errno
	}
	return unix.ByteSliceToString(request[:]), nil
}

func (*platform) ProcessPlatformOptions(option.TunPlatformOptions) error { return nil }

func (*platform) UsePlatformDefaultInterfaceMonitor() bool { return true }

func (p *platform) CreateDefaultInterfaceMonitor(logger.Logger) tun.DefaultInterfaceMonitor {
	return &monitor{platform: p}
}

func (*platform) UsePlatformNetworkInterfaces() bool { return true }

func (*platform) NetworkInterfaces() ([]adapter.NetworkInterface, error) {
	return []adapter.NetworkInterface{{Interface: physical, Type: C.InterfaceTypeOther}}, nil
}

func (*platform) UnderNetworkExtension() bool { return false }

func (*platform) NetworkExtensionIncludeAllNetworks() bool { return false }

func (*platform) ClearDNSCache() {}

func (*platform) RequestPermissionForWIFIState() error { return nil }

func (*platform) ReadWIFIState(context.Context) adapter.WIFIState { return adapter.WIFIState{} }

func (*platform) UsePlatformConnectionOwnerFinder() bool { return false }

func (*platform) FindConnectionOwner(*adapter.FindConnectionOwnerRequest) (*adapter.ConnectionOwner, error) {
	return nil, errNotOnAndroid
}

func (*platform) UsePlatformWIFIMonitor() bool { return true }

func (*platform) UsePlatformNotification() bool { return false }

func (*platform) SendNotification(*adapter.Notification) error { return nil }

func (*platform) CancelNotification(string, int32) error { return nil }

func (p *platform) MyInterfaceAddress() []netip.Addr { return p.addresses }

func (*platform) UsePlatformNeighborResolver() bool { return false }

func (*platform) StartNeighborMonitor(adapter.NeighborUpdateListener) error { return errNotOnAndroid }

func (*platform) CloseNeighborMonitor(adapter.NeighborUpdateListener) error { return nil }

func (*platform) UsePlatformShell() bool { return false }

func (*platform) CheckPlatformShell() error { return errNotOnAndroid }

func (*platform) OpenShellSession(*adapter.PlatformUser, string, []string, string, int32, int32) (adapter.ShellSession, error) {
	return nil, errNotOnAndroid
}

func (*platform) LookupUser(string) (*adapter.PlatformUser, error) { return nil, errNotOnAndroid }

func (*platform) LookupSFTPServer() (string, error) { return "", errNotOnAndroid }

func (*platform) ReadSystemSSHHostKey() ([]byte, error) { return nil, errNotOnAndroid }

func (*platform) TailscaleHostname() string { return "" }

func (*platform) UsePlatformBridge() bool { return false }

func (*platform) CreateBridge(adapter.BridgeOptions) (adapter.BridgeSession, error) {
	return nil, errNotOnAndroid
}

// monitor reports one unchanging network. The core reopens connections when
// the app tells it the phone moved to another one.
type monitor struct {
	platform  *platform
	access    sync.Mutex
	callbacks list.List[tun.DefaultInterfaceUpdateCallback]
	mine      []string
}

func (m *monitor) Start() error { return m.platform.manager.UpdateInterfaces() }

func (*monitor) Close() error { return nil }

func (*monitor) DefaultInterface() *control.Interface { return &physical }

func (*monitor) OverrideAndroidVPN() bool { return false }

func (*monitor) AndroidVPNEnabled() bool { return false }

func (m *monitor) RegisterCallback(callback tun.DefaultInterfaceUpdateCallback) *list.Element[tun.DefaultInterfaceUpdateCallback] {
	m.access.Lock()
	defer m.access.Unlock()
	return m.callbacks.PushBack(callback)
}

func (m *monitor) UnregisterCallback(element *list.Element[tun.DefaultInterfaceUpdateCallback]) {
	m.access.Lock()
	defer m.access.Unlock()
	m.callbacks.Remove(element)
}

func (m *monitor) RegisterMyInterface(name string) {
	m.access.Lock()
	defer m.access.Unlock()
	m.mine = append(m.mine, name)
}

func (m *monitor) MyInterfaces() []string {
	m.access.Lock()
	defer m.access.Unlock()
	return m.mine
}
