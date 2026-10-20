// net.fetch: the host-side HTTP API for extensions (runtime v2).
//
// An extension may only fetch through a Fetcher built from its own
// manifest allowlist ("network_hosts") and only when it was granted the
// "net.fetch" permission. Everything — allowed and denied requests — is
// written to the extension's log.
//
// Enforcement summary:
//   - https only, no userinfo, no IP-literal hosts, no explicit ports;
//   - host must match the allowlist: exact (case-insensitive), or
//     "*.example.com" which matches subdomains but NOT the bare domain;
//   - redirects are re-checked against the allowlist (max 3 hops);
//   - per-request timeout, request/response size caps, per-extension rate
//     limit (token bucket).
package ext

import (
	"bytes"
	"context"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// Fetch limits. They are the documented contract: an extension can rely on
// at most these, never more.
const (
	// DefaultFetchTimeout bounds one fetch end to end.
	DefaultFetchTimeout = 30 * time.Second
	// MaxFetchRequestBodyBytes caps the request body an extension may send.
	MaxFetchRequestBodyBytes = 1 << 20 // 1 MiB
	// MaxFetchResponseBodyBytes caps the response body we will read.
	MaxFetchResponseBodyBytes = 8 << 20 // 8 MiB
	// MaxFetchRedirects caps redirect hops; every hop is re-checked.
	MaxFetchRedirects = 3
	// FetchRatePerMinute and FetchRateBurst are the default per-extension
	// rate limit (sustained rate, burst size).
	FetchRatePerMinute = 30.0
	FetchRateBurst     = 10.0
)

// FetchLimits tunes a Fetcher. Zero values select the defaults above.
type FetchLimits struct {
	Timeout         time.Duration
	MaxRequestBody  int64
	MaxResponseBody int64
	MaxRedirects    int
	RatePerMinute   float64
	RateBurst       float64
}

func (l FetchLimits) withDefaults() FetchLimits {
	if l.Timeout <= 0 {
		l.Timeout = DefaultFetchTimeout
	}
	if l.MaxRequestBody <= 0 {
		l.MaxRequestBody = MaxFetchRequestBodyBytes
	}
	if l.MaxResponseBody <= 0 {
		l.MaxResponseBody = MaxFetchResponseBodyBytes
	}
	if l.MaxRedirects <= 0 {
		l.MaxRedirects = MaxFetchRedirects
	}
	if l.RatePerMinute <= 0 {
		l.RatePerMinute = FetchRatePerMinute
	}
	if l.RateBurst <= 0 {
		l.RateBurst = FetchRateBurst
	}
	return l
}

// FetchRequest is one extension HTTP request.
type FetchRequest struct {
	Method  string
	URL     string
	Headers map[string]string
	Body    []byte
}

// FetchResponse is the extension-visible result.
type FetchResponse struct {
	Status  int
	Headers http.Header
	Body    []byte
}

// allowedMethods is the closed set a worker may use.
var allowedMethods = map[string]bool{
	http.MethodGet: true, http.MethodHead: true, http.MethodPost: true,
	http.MethodPut: true, http.MethodPatch: true, http.MethodDelete: true,
	http.MethodOptions: true,
}

// hopHeaders are never taken from the extension; the transport owns them.
var hopHeaders = map[string]bool{
	"host": true, "content-length": true, "transfer-encoding": true,
	"connection": true, "keep-alive": true, "proxy-authenticate": true,
	"proxy-authorization": true, "te": true, "trailer": true, "upgrade": true,
}

// rateLimiter is a mutex-guarded token bucket.
type rateLimiter struct {
	mu     sync.Mutex
	tokens float64
	last   time.Time
	rate   float64 // tokens per second
	burst  float64
}

func newRateLimiter(ratePerMinute, burst float64) *rateLimiter {
	return &rateLimiter{tokens: burst, last: time.Now(), rate: ratePerMinute / 60, burst: burst}
}

func (l *rateLimiter) allow() bool {
	l.mu.Lock()
	defer l.mu.Unlock()
	now := time.Now()
	l.tokens += now.Sub(l.last).Seconds() * l.rate
	if l.tokens > l.burst {
		l.tokens = l.burst
	}
	l.last = now
	if l.tokens < 1 {
		return false
	}
	l.tokens--
	return true
}

// FetchStats are the diagnostics counters for one extension's net.fetch.
// The app surfaces them in the extension details screen next to the log.
type FetchStats struct {
	Requests uint64 // Fetch calls, allowed or not
	Denied   uint64 // requests refused (allowlist, rate limit, sizes, kill-switch pause)
	BytesOut uint64 // request body bytes actually sent
	BytesIn  uint64 // response body bytes actually read
}

// Fetcher is a per-extension HTTP client bound to that extension's
// network_hosts allowlist. Use NewFetcherForExtension.
//
// The permission is enforced at construction: a Fetcher is only built for
// an extension that holds "net.fetch", and a nil Fetcher fails closed in
// WorkerEnv.Fetch. There is deliberately no per-call permission argument —
// a caller-supplied grant list cannot be a security check. Disabling or
// uninstalling the extension must unregister its worker (Scheduler), which
// drops the Fetcher; no live Fetcher means no further requests.
type Fetcher struct {
	extID   string
	allow   []string // normalized patterns from normalizeHostPattern
	limits  FetchLimits
	hub     *LogHub
	limiter *rateLimiter
	client  *http.Client
	// paused, when set, reports whether the kill-switch pause is active.
	// Fetch fails fast while it returns true. The scheduler wires it to
	// Scheduler.Paused for task fetchers; a nil gate (standalone fetchers)
	// never pauses. It is set once before the fetcher is shared and only
	// read afterwards.
	paused func() bool

	statRequests atomic.Uint64
	statDenied   atomic.Uint64
	statBytesOut atomic.Uint64
	statBytesIn  atomic.Uint64
}

// NewFetcherForExtension builds the fetcher for one extension from its
// validated v2 manifest fields. x may carry an empty allowlist: every
// request is then denied (logged), which is the safe default.
//
// The transport dials direct. Production code must use
// NewFetcherForExtensionWithTransport with a tunnel-bound transport (see
// below); direct dials bypass the VPN.
func NewFetcherForExtension(extID string, x *ManifestExt, limits FetchLimits, hub *LogHub) (*Fetcher, error) {
	return NewFetcherForExtensionWithTransport(extID, x, limits, nil, hub)
}

// NewFetcherForExtensionWithTransport is NewFetcherForExtension with an
// explicit HTTP transport. rt carries the request end to end: pass a
// transport bound to the core's tunnel (local proxy / SOCKS5 dialer) so
// extension traffic follows the VPN and never leaks direct. A nil rt
// selects direct dials (tests and dev only).
func NewFetcherForExtensionWithTransport(extID string, x *ManifestExt, limits FetchLimits, rt http.RoundTripper, hub *LogHub) (*Fetcher, error) {
	if strings.TrimSpace(extID) == "" {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyNetFetchDenied, "ext: net.fetch needs an extension id")
	}
	if hub == nil {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyNetFetchDenied, "ext: net.fetch needs a log hub")
	}
	limits = limits.withDefaults()
	allow := []string{}
	if x != nil {
		for _, h := range x.NetworkHosts {
			norm, err := normalizeHostPattern(h)
			if err != nil {
				return nil, errs.Newf(errs.CodeInvalidArgument, KeyNetworkHostsInvalid,
					"ext: bad network_hosts entry %q: %v", h, err)
			}
			allow = append(allow, norm)
		}
	}
	transport := rt
	if transport == nil {
		transport = http.DefaultTransport
	}
	f := &Fetcher{
		extID:   extID,
		allow:   allow,
		limits:  limits,
		hub:     hub,
		limiter: newRateLimiter(limits.RatePerMinute, limits.RateBurst),
	}
	// The redirect policy re-validates every hop against the allowlist, so a
	// 302 cannot smuggle the request off-allowlist.
	f.client = &http.Client{
		Transport: transport,
		Timeout:   0, // deadline is enforced per-request via context
		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			if len(via) >= f.limits.MaxRedirects {
				return errs.Newf(errs.CodeResourceExhausted, KeyNetFetchFailed,
					"ext: net.fetch: too many redirects")
			}
			if err := f.checkURL(req.URL); err != nil {
				return err
			}
			return nil
		},
	}
	return f, nil
}

// Stats returns a snapshot of the fetcher's diagnostics counters.
func (f *Fetcher) Stats() FetchStats {
	return FetchStats{
		Requests: f.statRequests.Load(),
		Denied:   f.statDenied.Load(),
		BytesOut: f.statBytesOut.Load(),
		BytesIn:  f.statBytesIn.Load(),
	}
}

// logf writes one audit line to the extension's log.
func (f *Fetcher) logf(level LogLevel, format string, args ...any) {
	msg := fmt.Sprintf(format, args...)
	if len(msg) > MaxLogMessage {
		msg = msg[:MaxLogMessage]
	}
	f.hub.Log(f.extID).Append(level, msg)
}

// Fetch performs one allowlisted HTTP request.
//
// The permission is enforced at construction: a Fetcher is only built for
// an extension that holds "net.fetch" (see Scheduler.Register), and a nil
// Fetcher fails closed in WorkerEnv.Fetch. There is deliberately no
// per-call permission argument — a caller-supplied grant list cannot be a
// security check.
//
// Every request — allowed or denied — is written to the extension's log,
// which is the audit trail for extension network activity.
func (f *Fetcher) Fetch(ctx context.Context, req FetchRequest) (*FetchResponse, error) {
	f.statRequests.Add(1)
	if f.paused != nil && f.paused() {
		// Kill-switch pause: no background request is attempted against
		// the blocked network. In-flight requests are aborted separately
		// via the run context (see Scheduler.SetKillSwitch).
		f.statDenied.Add(1)
		f.logf(LogWarn, "fetch DENIED %s: kill switch paused background network", safeMethodURL(req))
		return nil, errs.Newf(errs.CodeUnavailable, KeyNetFetchPaused,
			"ext: net.fetch is paused: the kill switch is active")
	}
	if !f.limiter.allow() {
		f.statDenied.Add(1)
		f.logf(LogWarn, "fetch DENIED %s: rate limit exceeded", safeMethodURL(req))
		return nil, errs.Newf(errs.CodeResourceExhausted, KeyNetFetchDenied,
			"ext: net.fetch rate limit exceeded").WithRetry(time.Minute)
	}
	u, err := f.parseRequest(req)
	if err != nil {
		f.statDenied.Add(1)
		f.logf(LogWarn, "fetch DENIED %s: %v", safeMethodURL(req), err)
		return nil, err
	}
	ctx, cancel := context.WithTimeout(ctx, f.limits.Timeout)
	defer cancel()
	// Display form for this request's log lines, built once from the
	// already-parsed URL: safeMethodURL(req) would parse the URL a second
	// time per log line (and Fetch logs at least once per request).
	mu := safeMethodParsed(req.Method, u)
	httpReq, err := http.NewRequestWithContext(ctx, req.Method, u.String(), bytes.NewReader(req.Body))
	if err != nil {
		f.logf(LogError, "fetch FAILED %s: %v", mu, err)
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyNetFetchFailed, "ext: net.fetch: %v", err)
	}
	for k, v := range req.Headers {
		if hopHeaders[strings.ToLower(k)] {
			continue
		}
		httpReq.Header.Set(k, v)
	}
	resp, err := f.client.Do(httpReq)
	if err != nil {
		if urlErr, ok := err.(*url.Error); ok && urlErr != nil {
			if denied, ok := urlErr.Err.(*errs.Error); ok {
				// A redirect hop failed the allowlist check.
				f.statDenied.Add(1)
				f.logf(LogWarn, "fetch DENIED %s: redirect target rejected: %v", mu, denied)
				return nil, denied
			}
		}
		f.logf(LogError, "fetch FAILED %s: %v", mu, shortErr(err))
		return nil, errs.Newf(errs.CodeUnavailable, KeyNetFetchFailed, "ext: net.fetch: %v", shortErr(err))
	}
	defer resp.Body.Close()
	body, err := f.readResponseBody(resp)
	if err != nil {
		f.logf(LogError, "fetch FAILED %s: reading body: %v", mu, shortErr(err))
		return nil, errs.Newf(errs.CodeUnavailable, KeyNetFetchFailed, "ext: net.fetch: %v", shortErr(err))
	}
	if int64(len(body)) > f.limits.MaxResponseBody {
		f.statDenied.Add(1)
		f.logf(LogWarn, "fetch DENIED %s: response exceeds %d bytes", mu, f.limits.MaxResponseBody)
		return nil, errs.Newf(errs.CodeResourceExhausted, KeyNetFetchFailed,
			"ext: net.fetch: response exceeds %d bytes", f.limits.MaxResponseBody)
	}
	f.statBytesOut.Add(uint64(len(req.Body)))
	f.statBytesIn.Add(uint64(len(body)))
	f.logf(LogInfo, "fetch %s -> %d (%d bytes)", mu, resp.StatusCode, len(body))
	return &FetchResponse{Status: resp.StatusCode, Headers: resp.Header.Clone(), Body: body}, nil
}

// readResponseBody reads at most MaxResponseBody+1 bytes of resp.Body
// (the caller rejects anything over MaxResponseBody, exactly as with the
// previous io.ReadAll+LimitReader). When the transport reports a
// ContentLength inside the cap, the buffer is grown to it once:
// io.ReadAll's doubling growth allocates ~2x the body in total (measured
// 2 231 343 B/op for a 1 MiB body), the pre-sized buffer ~1x. An unknown
// (-1, chunked) or over-cap ContentLength just falls back to growth — the
// hint never weakens the cap, which the LimitReader still enforces.
func (f *Fetcher) readResponseBody(resp *http.Response) ([]byte, error) {
	var hint int64
	if resp.ContentLength > 0 && resp.ContentLength <= f.limits.MaxResponseBody {
		hint = resp.ContentLength
	}
	return readAllLimited(resp.Body, f.limits.MaxResponseBody+1, hint)
}

// parseRequest validates the method, URL and body, and returns the
// allowlist-checked URL.
func (f *Fetcher) parseRequest(req FetchRequest) (*url.URL, error) {
	method := strings.ToUpper(strings.TrimSpace(req.Method))
	if method == "" {
		method = http.MethodGet
	}
	if !allowedMethods[method] {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyNetFetchDenied,
			"ext: net.fetch: method %q is not allowed", req.Method)
	}
	req.Method = method
	if int64(len(req.Body)) > f.limits.MaxRequestBody {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyNetFetchDenied,
			"ext: net.fetch: request body exceeds %d bytes", f.limits.MaxRequestBody)
	}
	raw := strings.TrimSpace(req.URL)
	if raw == "" || len(raw) > 2048 {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyNetFetchDenied, "ext: net.fetch: bad URL")
	}
	u, err := url.Parse(raw)
	if err != nil || u.Host == "" {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyNetFetchDenied, "ext: net.fetch: bad URL")
	}
	if err := f.checkURL(u); err != nil {
		return nil, err
	}
	return u, nil
}

// checkURL enforces the transport policy for one URL: https only, no
// userinfo, no IP-literal host, no explicit port, host on the allowlist.
func (f *Fetcher) checkURL(u *url.URL) error {
	if !strings.EqualFold(u.Scheme, "https") {
		return errs.Newf(errs.CodePermissionDenied, KeyNetFetchDenied,
			"ext: net.fetch: only https URLs are allowed")
	}
	if u.User != nil {
		return errs.Newf(errs.CodePermissionDenied, KeyNetFetchDenied,
			"ext: net.fetch: userinfo in URL is not allowed")
	}
	host := u.Hostname()
	if host == "" {
		return errs.Newf(errs.CodePermissionDenied, KeyNetFetchDenied, "ext: net.fetch: bad URL")
	}
	if isIPLike(host) {
		// IP literals in any notation (net.ParseIP misses decimal/hex/
		// octal forms, but some system resolvers still dial them as IPs).
		return errs.Newf(errs.CodePermissionDenied, KeyNetFetchDenied,
			"ext: net.fetch: IP-literal hosts are not allowed")
	}
	if _, port, err := net.SplitHostPort(u.Host); err == nil && port != "" {
		return errs.Newf(errs.CodePermissionDenied, KeyNetFetchDenied,
			"ext: net.fetch: explicit ports are not allowed")
	}
	if !f.hostAllowed(host) {
		return errs.Newf(errs.CodePermissionDenied, KeyNetFetchDenied,
			"ext: net.fetch: host %q is not in network_hosts", host)
	}
	return nil
}

// hostAllowed matches host against the normalized allowlist. An exact entry
// matches only itself (no implicit subdomains); "*.example.com" matches
// subdomains but not the bare "example.com".
func (f *Fetcher) hostAllowed(host string) bool {
	h := strings.ToLower(strings.TrimSuffix(host, "."))
	for _, pat := range f.allow {
		if strings.HasPrefix(pat, "*.") {
			base := pat[2:]
			if len(h) > len(base)+1 && strings.HasSuffix(h, "."+base) {
				return true
			}
			continue
		}
		if h == pat {
			return true
		}
	}
	return false
}

// safeMethodURL renders "METHOD url" for logs. The query, fragment and any
// userinfo are stripped: they routinely carry API keys and tokens, and the
// extension's log is surfaced in the app UI.
func safeMethodURL(req FetchRequest) string {
	u := strings.TrimSpace(req.URL)
	if parsed, err := url.Parse(u); err == nil {
		return safeMethodParsed(req.Method, parsed)
	}
	return safeMethodDisplay(req.Method, u)
}

// safeMethodParsed is safeMethodURL for a URL that is already parsed (the
// request path parses once for validation; log lines reuse that parse
// instead of paying for a second one).
func safeMethodParsed(method string, parsed *url.URL) string {
	clean := *parsed
	clean.User = nil
	clean.RawQuery = ""
	clean.ForceQuery = false
	clean.Fragment = ""
	clean.RawFragment = ""
	return safeMethodDisplay(method, clean.String())
}

func safeMethodDisplay(method, u string) string {
	m := strings.ToUpper(strings.TrimSpace(method))
	if m == "" {
		m = http.MethodGet
	}
	if len(u) > 200 {
		u = u[:200] + "…"
	}
	return m + " " + u
}

// shortErr keeps one bounded line of an error for logs.
func shortErr(err error) string {
	s := err.Error()
	if i := strings.IndexByte(s, '\n'); i >= 0 {
		s = s[:i]
	}
	if len(s) > 200 {
		s = s[:200] + "…"
	}
	return s
}
