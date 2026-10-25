# Strict Linux kill-switch receiver checks

`TestStrictNftIntegration` uses two private network namespaces connected by a
veth pair. Its existing guard-holder process installs the real nftables policy;
the peer serves HTTP and UDP echo. The extended test adds four named packet
counters on that independent peer, covering TCP/UDP to the blocked IPv4 and IPv6
fixture destinations. Missing, duplicate or malformed counters fail the test.

Every counter must observe traffic before filtering. All four must then remain
zero during protected probes, including after `SIGKILL` of the guard-holder,
after a down/up cycle of the veth interface, and after recovery from persisted
guard intent. Allowed IPv4 TCP and IPv6 UDP engine endpoints must remain
reachable in those protected phases, so loss of connectivity cannot pass as
working protection. A JSON object records phase names and received packet counts.

Linux removed the fixture's global IPv6 addresses during administrative link
down in the first run. The test now restores those addresses with `ip address
replace`, representing network-manager address restoration, then waits for IPv6
reachability. It changes no host interface or sysctl.

The existing recovery test deliberately deletes the Sora nftables table. That
interval is explicitly unprotected: the receiver must observe all four kinds of
traffic again. Counters reset only after recovery has reapplied protection.
Including that deliberate window in protected totals initially failed with
received packets; the phases are now separate rather than discarding that
evidence or weakening the zero-packet assertion.

## Observed result

The actual local namespace test with Go's race detector passed in 13.336 seconds.
One run recorded these counts; positive counts can vary and are required to be
greater than zero, not to equal these particular numbers.

| Phase | IPv4 TCP | IPv4 UDP | IPv6 TCP | IPv6 UDP |
| --- | ---: | ---: | ---: | ---: |
| Baseline | 5 | 1 | 5 | 1 |
| Armed | 0 | 0 | 0 | 0 |
| Guard-holder killed | 0 | 0 | 0 | 0 |
| Interface/address recovery | 0 | 0 | 0 | 0 |
| Deliberately removed firewall | 9 | 1 | 9 | 1 |
| Guard intent recovered | 0 | 0 | 0 | 0 |

The local unprivileged user namespace cannot map the second test UID, so existing
cross-account subtests skipped there. The unchanged required hosted-root CI step
must run those subtests; local results do not establish that boundary. Local
sudo is unavailable and was not requested interactively.

This is a Linux guard-process/packet test, not a full Sora-service, UI, tunnel,
DNS, hardware-network-switching or Windows failure matrix. It does not prove
boot/power-loss coverage or protection against another privileged writer that
deletes firewall rules. Those S4 cases remain open. No production code, firewall
policy, host routes, service or machine power settings change in this patch.

The existing workflow runs the test in its private network with
`SORA_NFT_REQUIRED=1`; unavailable prerequisites or cross-account execution must
fail rather than become successful negative tests. Counter operations follow
the [nftables named-counter interface](https://wiki.nftables.org/wiki-nftables/index.php/Counters);
JSON is decoded with the existing standard library.
