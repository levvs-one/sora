package bypass

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"sync"
)

// NFQUEUE allocation and nftables rule rendering for the nfqws executor.
//
// nfqws reads packets from a netfilter queue; without queue rules it sees
// nothing. This file holds the pure mechanics: handing out queue numbers
// and rendering the nft commands that steer a strategy's filtered traffic
// into a queue. Process supervision, rule application, and the table/chain
// lifecycle live with the executor (see NFQWS-MIGRATION.md §2).
//
// The rule text is data, not action: nothing here touches the kernel.

const (
	// queueBase is the first NFQUEUE number sora hands out. 200 follows
	// the zapret convention (NFQWS_PORTS uses 200 by default); the block
	// below it is left alone for anything else on the host.
	queueBase = 200
	// queueCount bounds concurrent nfqws instances. One instance serves
	// every outbound sharing a filter set, so 20 is generous.
	queueCount = 20
)

// nftTable is the table the executor creates for interception rules.
const nftTable = "sora_nfqws"

// QueueAllocator hands out NFQUEUE numbers to nfqws instances. It is safe
// for concurrent use.
type QueueAllocator struct {
	mu   sync.Mutex
	used [queueCount]bool
}

// Acquire returns a free queue number, or false when all are in use.
func (a *QueueAllocator) Acquire() (int, bool) {
	a.mu.Lock()
	defer a.mu.Unlock()
	for i := range a.used {
		if !a.used[i] {
			a.used[i] = true
			return queueBase + i, true
		}
	}
	return 0, false
}

// Release frees a queue number. Out-of-range numbers are ignored: a
// double release must never corrupt the allocator.
func (a *QueueAllocator) Release(q int) {
	i := q - queueBase
	if i < 0 || i >= queueCount {
		return
	}
	a.mu.Lock()
	defer a.mu.Unlock()
	a.used[i] = false
}

// validPortToken is one port or port range in nfqws filter syntax.
var validPortToken = regexp.MustCompile(`^([0-9]{1,5})(-([0-9]{1,5}))?$`)

// parsePorts validates a comma-separated nfqws port filter ("80,443",
// "50000-50099") and returns the tokens for nft set syntax. An empty
// filter selects nothing and returns nil.
func parsePorts(filter string) ([]string, error) {
	filter = strings.TrimSpace(filter)
	if filter == "" {
		return nil, nil
	}
	var out []string
	for _, tok := range strings.Split(filter, ",") {
		tok = strings.TrimSpace(tok)
		m := validPortToken.FindStringSubmatch(tok)
		if m == nil {
			return nil, fmt.Errorf("bypass: %q is not a port or port range", tok)
		}
		lo, _ := strconv.Atoi(m[1])
		hi := lo
		if m[3] != "" {
			hi, _ = strconv.Atoi(m[3])
		}
		if lo > 65535 || hi > 65535 || lo > hi || lo == 0 {
			return nil, fmt.Errorf("bypass: port range %q is out of bounds", tok)
		}
		out = append(out, tok)
	}
	return out, nil
}

// QueueSpec is the interception request for one nfqws instance: the queue
// number it reads and the destination ports to steer into it, in the
// strategy's FilterTCP/FilterUDP syntax.
type QueueSpec struct {
	Queue    int
	TCPPorts string
	UDPPorts string
}

// nftRules renders the nft add/delete commands for the spec. The
// sora_nfqws table and its output chain must exist; creating them is the
// executor's job. At least one of TCPPorts/UDPPorts must select something:
// a queue with no traffic is a configuration bug, fail here instead of
// installing a dead rule.
func (s QueueSpec) nftRules(verb string) ([]string, error) {
	tcp, err := parsePorts(s.TCPPorts)
	if err != nil {
		return nil, err
	}
	udp, err := parsePorts(s.UDPPorts)
	if err != nil {
		return nil, err
	}
	if len(tcp) == 0 && len(udp) == 0 {
		return nil, fmt.Errorf("bypass: a queue spec with no ports would intercept nothing")
	}
	var rules []string
	if len(tcp) > 0 {
		rules = append(rules, fmt.Sprintf("%s rule inet %s output tcp dport {%s} queue num %d",
			verb, nftTable, strings.Join(tcp, ", "), s.Queue))
	}
	if len(udp) > 0 {
		rules = append(rules, fmt.Sprintf("%s rule inet %s output udp dport {%s} queue num %d",
			verb, nftTable, strings.Join(udp, ", "), s.Queue))
	}
	return rules, nil
}

// AddRules renders the `nft add rule` commands installing interception.
func (s QueueSpec) AddRules() ([]string, error) { return s.nftRules("add") }

// DeleteRules renders the matching `nft delete rule` commands. Deleting a
// rule that was never added is an nft error the executor tolerates; the
// text must still match exactly what AddRules installed.
func (s QueueSpec) DeleteRules() ([]string, error) { return s.nftRules("delete") }
