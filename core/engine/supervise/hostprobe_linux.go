package supervise

// ProbeHost reads this Linux host's TUN and kernel-WireGuard facts
// from the device node and sysfs. It never loads a module and never
// creates a device: it reports what is there.
func ProbeHost() HostFacts {
	return probeHost(hostPaths{tunDevice: "/dev/net/tun", wgModule: "/sys/module/wireguard"})
}
