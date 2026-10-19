package bypass

import (
	"strings"
	"sync"
	"testing"
)

func TestQueueAllocatorHandsOutUniqueQueues(t *testing.T) {
	var a QueueAllocator
	seen := map[int]bool{}
	for i := 0; i < queueCount; i++ {
		q, ok := a.Acquire()
		if !ok {
			t.Fatalf("acquire %d failed", i)
		}
		if q < queueBase || q >= queueBase+queueCount {
			t.Fatalf("queue %d out of range", q)
		}
		if seen[q] {
			t.Fatalf("queue %d handed out twice", q)
		}
		seen[q] = true
	}
	if _, ok := a.Acquire(); ok {
		t.Fatal("acquire beyond capacity succeeded")
	}
	a.Release(queueBase + 3)
	q, ok := a.Acquire()
	if !ok || q != queueBase+3 {
		t.Fatalf("released queue not reused: %d, %v", q, ok)
	}
}

func TestQueueAllocatorReleaseIsDefensive(t *testing.T) {
	var a QueueAllocator
	// Out-of-range and double releases must not corrupt the allocator.
	a.Release(-1)
	a.Release(0)
	a.Release(queueBase + queueCount)
	a.Release(99999)
	q, ok := a.Acquire()
	if !ok || q != queueBase {
		t.Fatalf("allocator corrupted by bad releases: %d, %v", q, ok)
	}
	a.Release(q)
	a.Release(q)
	if _, ok := a.Acquire(); !ok {
		t.Fatal("double release broke the allocator")
	}
}

func TestQueueAllocatorConcurrent(t *testing.T) {
	var a QueueAllocator
	var mu sync.Mutex
	seen := map[int]int{}
	var wg sync.WaitGroup
	for i := 0; i < 40; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			if q, ok := a.Acquire(); ok {
				mu.Lock()
				seen[q]++
				mu.Unlock()
			}
		}()
	}
	wg.Wait()
	if len(seen) != queueCount {
		t.Fatalf("handed out %d distinct queues, want %d", len(seen), queueCount)
	}
	for q, n := range seen {
		if n != 1 {
			t.Fatalf("queue %d handed out %d times", q, n)
		}
	}
}

func TestQueueSpecRendersRules(t *testing.T) {
	s := QueueSpec{Queue: 200, TCPPorts: "80,443", UDPPorts: "443"}
	add, err := s.AddRules()
	if err != nil {
		t.Fatalf("AddRules: %v", err)
	}
	if len(add) != 2 {
		t.Fatalf("rules = %v, want tcp+udp", add)
	}
	if !strings.Contains(add[0], "tcp dport {80, 443}") || !strings.Contains(add[0], "queue num 200") {
		t.Errorf("tcp rule = %q", add[0])
	}
	if !strings.Contains(add[1], "udp dport {443}") {
		t.Errorf("udp rule = %q", add[1])
	}
	del, err := s.DeleteRules()
	if err != nil {
		t.Fatalf("DeleteRules: %v", err)
	}
	for i := range add {
		if !strings.HasPrefix(del[i], "delete ") || strings.TrimPrefix(del[i], "delete ") != strings.TrimPrefix(add[i], "add ") {
			t.Errorf("delete rule %q does not mirror add rule %q", del[i], add[i])
		}
	}
}

func TestQueueSpecRanges(t *testing.T) {
	s := QueueSpec{Queue: 201, UDPPorts: "50000-50099"}
	add, err := s.AddRules()
	if err != nil {
		t.Fatalf("AddRules: %v", err)
	}
	if len(add) != 1 || !strings.Contains(add[0], "udp dport {50000-50099}") {
		t.Fatalf("rules = %v", add)
	}
}

func TestQueueSpecRejectsBadInput(t *testing.T) {
	for name, s := range map[string]QueueSpec{
		"no ports":       {Queue: 200},
		"not a port":     {Queue: 200, TCPPorts: "http"},
		"port too big":   {Queue: 200, TCPPorts: "99999"},
		"reversed range": {Queue: 200, UDPPorts: "443-80"},
		"zero port":      {Queue: 200, TCPPorts: "0"},
		"injection":      {Queue: 200, TCPPorts: "443; rm -rf /"},
		"nft metachars":  {Queue: 200, UDPPorts: "443 } queue num 1; #"},
	} {
		if _, err := s.AddRules(); err == nil {
			t.Errorf("%s: bad spec accepted", name)
		}
	}
}
