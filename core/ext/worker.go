// Background workers (runtime v2): periodic tasks for extensions that
// declare the "background" capability and hold the "background" permission.
//
// A worker runs in WorkerEnv, a deliberately small sandbox: it can append
// to the extension log and, only when the extension also holds "net.fetch",
// make allowlisted HTTP requests through the extension's own Fetcher. There
// is no filesystem, no process control, no raw network. The app-side JS
// runner executes the manifest's worker script inside this envelope; the
// Go WorkerFunc below is the seam where the host plugs that runner in.
//
// Scheduling: the declared interval_minutes is clamped into
// [MinWorkerInterval, MaxWorkerInterval]. Every run's outcome — success or
// failure, including a recovered panic — is written to the extension log.
package ext

import (
	"context"
	"fmt"
	"hash/fnv"
	"strings"
	"sync"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// Worker scheduling bounds. The 15-minute floor keeps a buggy or hostile
// extension from hot-looping the device; the 7-day ceiling matches the
// largest declarable manifest interval.
const (
	MinWorkerInterval = 15 * time.Minute
	MaxWorkerInterval = 7 * 24 * time.Hour
	// WorkerRunTimeout bounds one worker execution.
	WorkerRunTimeout = 5 * time.Minute
)

// ClampWorkerInterval maps a declared interval in minutes to the effective
// schedule: at least MinWorkerInterval, at most MaxWorkerInterval.
func ClampWorkerInterval(minutes int) time.Duration {
	d := time.Duration(minutes) * time.Minute
	if d < MinWorkerInterval {
		return MinWorkerInterval
	}
	if d > MaxWorkerInterval {
		return MaxWorkerInterval
	}
	return d
}

// WorkerEnv is the limited environment one worker run executes in. It is
// intentionally narrow: logging plus optional allowlisted fetching. A nil
// Fetcher means the extension was not granted "net.fetch", and Fetch then
// reports a permission error instead of touching the network.
type WorkerEnv struct {
	extID   string
	log     *ExtLog
	fetcher *Fetcher
}

// Logf appends a formatted line to the extension's log.
func (e *WorkerEnv) Logf(format string, args ...any) {
	e.log.Append(LogInfo, fmt.Sprintf(format, args...))
}

// Fetch performs an allowlisted HTTP request on the worker's behalf. It
// fails closed when the extension lacks the "net.fetch" permission.
func (e *WorkerEnv) Fetch(ctx context.Context, req FetchRequest) (*FetchResponse, error) {
	if e.fetcher == nil {
		e.log.Append(LogWarn, "fetch DENIED: extension was not granted the \"net.fetch\" permission")
		return nil, errs.Newf(errs.CodePermissionDenied, KeyNetFetchDenied,
			"ext: net.fetch requires the %q permission", "net.fetch")
	}
	return e.fetcher.Fetch(ctx, []string{"net.fetch"}, req)
}

// WorkerFunc is one worker execution. A nil error means success; anything
// else (or a panic) is recorded in the extension log as a failed run.
type WorkerFunc func(ctx context.Context, env *WorkerEnv) error

// WorkerTask is a registered periodic task.
type WorkerTask struct {
	ExtensionID string
	// Interval is the effective, clamped schedule.
	Interval time.Duration
	// Entry is the manifest's worker script (for the app-side JS runner).
	Entry string

	run     WorkerFunc
	fetcher *Fetcher
}

// Scheduler owns background tasks for enabled extensions.
type Scheduler struct {
	mu     sync.Mutex
	tasks  map[string]*WorkerTask
	hub    *LogHub
	runCtx context.Context // non-nil while Start..Stop is active
	stop   context.CancelFunc
	wg     sync.WaitGroup
}

// NewScheduler returns a scheduler writing to hub. A nil hub gets a fresh
// one.
func NewScheduler(hub *LogHub) *Scheduler {
	if hub == nil {
		hub = NewLogHub()
	}
	return &Scheduler{tasks: map[string]*WorkerTask{}, hub: hub}
}

// Hub exposes the log sink the scheduler writes to.
func (s *Scheduler) Hub() *LogHub { return s.hub }

// Register validates the manifest pair and installs the task. It requires
// the "background" capability and permission plus a declared
// background_task; the interval is clamped (see ClampWorkerInterval). A nil
// run is rejected. Re-registering an extension replaces its task.
func (s *Scheduler) Register(m *Manifest, x *ManifestExt, run WorkerFunc) error {
	if m == nil || x == nil || x.Background == nil {
		return errs.Newf(errs.CodeInvalidArgument, KeyBackgroundInvalid,
			"ext: background worker needs a manifest with background_task")
	}
	if !hasCapability(m, "background") {
		return errs.Newf(errs.CodeInvalidArgument, KeyBackgroundInvalid,
			`ext: background worker requires the "background" capability`)
	}
	if !hasPermission(m, "background") {
		return errs.Newf(errs.CodePermissionDenied, KeyBackgroundInvalid,
			`ext: background worker requires the "background" permission`)
	}
	if run == nil {
		return errs.Newf(errs.CodeInvalidArgument, KeyBackgroundInvalid,
			"ext: background worker needs a run function")
	}
	var fetcher *Fetcher
	if hasPermission(m, "net.fetch") {
		f, err := NewFetcherForExtension(m.ID, x, FetchLimits{}, s.hub)
		if err != nil {
			return err
		}
		fetcher = f
	}
	task := &WorkerTask{
		ExtensionID: m.ID,
		Interval:    ClampWorkerInterval(x.Background.IntervalMinutes),
		Entry:       x.Background.Entry,
		run:         run,
		fetcher:     fetcher,
	}
	s.mu.Lock()
	s.tasks[m.ID] = task
	runCtx := s.runCtx
	s.mu.Unlock()
	s.hub.Log(m.ID).Append(LogInfo,
		fmt.Sprintf("background worker registered: every %s (declared %d min), entry %s",
			task.Interval, x.Background.IntervalMinutes, task.Entry))
	if runCtx != nil {
		s.startLoopWith(runCtx, task)
	}
	return nil
}

// Unregister removes the extension's task, if any.
func (s *Scheduler) Unregister(extID string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	delete(s.tasks, extID)
}

// Task returns the registered task for extID.
func (s *Scheduler) Task(extID string) (*WorkerTask, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	t, ok := s.tasks[extID]
	return t, ok
}

// Start begins ticking all registered tasks. It is idempotent; tasks
// registered while running start ticking immediately.
func (s *Scheduler) Start(ctx context.Context) {
	s.mu.Lock()
	if s.runCtx != nil {
		s.mu.Unlock()
		return
	}
	runCtx, cancel := context.WithCancel(ctx)
	s.runCtx = runCtx
	s.stop = cancel
	tasks := make([]*WorkerTask, 0, len(s.tasks))
	for _, t := range s.tasks {
		tasks = append(tasks, t)
	}
	s.mu.Unlock()
	for _, t := range tasks {
		s.startLoopWith(runCtx, t)
	}
}

// Stop halts all task loops and waits for in-flight runs to finish.
func (s *Scheduler) Stop() {
	s.mu.Lock()
	if s.runCtx == nil {
		s.mu.Unlock()
		return
	}
	stop := s.stop
	s.runCtx = nil
	s.stop = nil
	s.mu.Unlock()
	stop()
	s.wg.Wait()
}

// startLoopWith runs the ticker loop for one task until ctx ends.
func (s *Scheduler) startLoopWith(ctx context.Context, task *WorkerTask) {
	s.wg.Add(1)
	go func() {
		defer s.wg.Done()
		// Stagger the first run so N extensions enabled at once do not
		// fire simultaneously; the stagger is deterministic per
		// extension id and bounded by one minute.
		h := fnv.New32a()
		_, _ = h.Write([]byte(task.ExtensionID))
		stagger := time.Duration(h.Sum32()%60) * time.Second
		timer := time.NewTimer(stagger + task.Interval)
		defer timer.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-timer.C:
				s.runOnce(task)
				timer.Reset(task.Interval)
			}
		}
	}()
}

// runOnce executes one task run with a timeout, recovers panics, and logs
// the outcome to the extension's log.
func (s *Scheduler) runOnce(task *WorkerTask) {
	ctx, cancel := context.WithTimeout(context.Background(), WorkerRunTimeout)
	defer cancel()
	env := &WorkerEnv{extID: task.ExtensionID, log: s.hub.Log(task.ExtensionID), fetcher: task.fetcher}
	start := time.Now()
	err := func() (err error) {
		defer func() {
			if r := recover(); r != nil {
				err = errs.Newf(errs.CodeInvalidArgument, KeyWorkerFailed,
					"ext: background worker panicked: %v", r)
			}
		}()
		return task.run(ctx, env)
	}()
	elapsed := time.Since(start).Truncate(time.Millisecond)
	if err != nil {
		s.hub.Log(task.ExtensionID).Append(LogError,
			fmt.Sprintf("background worker run failed after %s: %v", elapsed, oneLine(err, 300)))
		return
	}
	s.hub.Log(task.ExtensionID).Append(LogInfo,
		fmt.Sprintf("background worker run ok (%s)", elapsed))
}

// oneLine collapses an error to a single bounded line for logs.
func oneLine(err error, max int) string {
	s := strings.ReplaceAll(strings.ReplaceAll(err.Error(), "\n", " "), "\r", " ")
	s = strings.Join(strings.Fields(s), " ")
	if len(s) > max {
		s = s[:max] + "…"
	}
	return s
}
