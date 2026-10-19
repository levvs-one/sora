//go:build windows

package diagnostics

import (
	"runtime"
	"unsafe"

	"golang.org/x/sys/windows"
)

// SystemResolvers returns the DNS servers Windows reports for its adapters.
// It never fails: undetectable resolvers yield an empty list, and callers
// report that honestly instead of guessing.
func SystemResolvers() []string {
	var out []string
	adapterSize := uint32(15000)
	for {
		if adapterSize > 2<<20 {
			return nil
		}
		adapters := make([]byte, adapterSize)
		first := (*windows.IpAdapterAddresses)(unsafe.Pointer(&adapters[0]))
		err := windows.GetAdaptersAddresses(windows.AF_UNSPEC, windows.GAA_FLAG_SKIP_ANYCAST|windows.GAA_FLAG_SKIP_MULTICAST, 0, first, &adapterSize)
		if err == windows.ERROR_BUFFER_OVERFLOW {
			continue
		}
		if err != nil {
			return nil
		}
		for current := first; current != nil; current = current.Next {
			for dns := current.FirstDnsServerAddress; dns != nil; dns = dns.Next {
				if ip := dns.Address.IP(); ip != nil {
					out = append(out, ip.String())
				}
			}
		}
		runtime.KeepAlive(adapters)
		return out
	}
}
