package session

import (
	"sync"
	"testing"
	"time"
)

// TestJournalUnsubscribeDuringAppend locks SORA-H6: unsubscribing while Append
// publishes must not panic (send on closed channel) and must not race.
func TestJournalUnsubscribeDuringAppend(_ *testing.T) {
	j := NewJournal(64)
	var wg sync.WaitGroup
	stop := make(chan struct{})
	// Publisher goroutines appending as fast as possible.
	for i := 0; i < 4; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for {
				select {
				case <-stop:
					return
				default:
					j.Append(Event{Kind: EventCounters})
				}
			}
		}()
	}
	// Churn subscriptions: subscribe, drain a little, cancel mid-append.
	for i := 0; i < 200; i++ {
		ch, cancel := j.Subscribe(1)
		go func() {
			for range ch {
			}
		}()
		time.Sleep(time.Millisecond)
		cancel()
	}
	close(stop)
	wg.Wait()
}

// TestJournalCancelIsIdempotentAndSilent ensures repeated cancel calls are
// safe and that a cancelled subscription receives nothing more.
func TestJournalCancelIsIdempotentAndSilent(t *testing.T) {
	j := NewJournal(8)
	ch, cancel := j.Subscribe(8)
	cancel()
	cancel()
	j.Append(Event{Kind: EventState})
	select {
	case ev := <-ch:
		t.Fatalf("cancelled subscription received event %v", ev.Sequence)
	default:
	}
}
