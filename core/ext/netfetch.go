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
	"io"
	"net"
	"net/http"
	"net/url"
	"strings"
	"sync"
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

// Fetcher is a per-extension HTTP client bound to that extension's
// network_hosts allowlist. Use NewFetcherForExtension.
type Fetcher struct {
	extID   string
	allow   []string // normalized patterns from normalizeHostPattern
	limits  FetchLimits
	hub     *LogHub
	limiter *rateLimiter
	client  *http.Client
}

// NewFetcherForExtension builds the fetcher for one extension from its
// validated v2 manifest fields. x may carry an empty allowlist: every
// request is then denied (logged), which is the safe default.
func NewFetcherForExtension(extID string, x *ManifestExt, limits FetchLimits, hub *LogHub) (*Fetcher, error) {
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
		Timeout: 0, // deadline is enforced per-request via context
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

// logf writes one audit line to the extension's log.
func (f *Fetcher) logf(level LogLevel, format string, args ...any) {
	msg := fmt.Sprintf(format, args...)
	if len(msg) > MaxLogMessage {
		msg = msg[:MaxLogMessage]
	}
	f.hub.Log(f.extID).Append(level, msg)
}

// Fetch performs one allowlisted HTTP request. granted is the extension's
// granted permission list; without "net.fetch" the call is denied.
func (f *Fetcher) Fetch(ctx context.Context, granted []string, req FetchRequest) (*FetchResponse, error) {
	if !hasString(granted, "net.fetch") {
		f.logf(LogWarn, "fetch DENIED %s: missing %q permission", safeMethodURL(req), "net.fetch")
		return nil, errs.Newf(errs.CodePermissionDenied, KeyNetFetchDenied,
			"ext: net.fetch requires the %q permission", "net.fetch")
	}
	if !f.limiter.allow() {
		f.logf(LogWarn, "fetch DENIED %s: rate limit exceeded", safeMethodURL(req))
		return nil, errs.Newf(errs.CodeResourceExhausted, KeyNetFetchDenied,
			"ext: net.fetch rate limit exceeded").WithRetry(time.Minute)
	}
	u, err := f.parseRequest(req)
	if err != nil {
		f.logf(LogWarn, "fetch DENIED %s: %v", safeMethodURL(req), err)
		return nil, err
	}
	ctx, cancel := context.WithTimeout(ctx, f.limits.Timeout)
	defer cancel()
	httpReq, err := http.NewRequestWithContext(ctx, req.Method, u.String(), bytes.NewReader(req.Body))
	if err != nil {
		f.logf(LogError, "fetch FAILED %s: %v", safeMethodURL(req), err)
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
				f.logf(LogWarn, "fetch DENIED %s: redirect target rejected: %v", safeMethodURL(req), denied)
				return nil, denied
			}
		}
		f.logf(LogError, "fetch FAILED %s: %v", safeMethodURL(req), shortErr(err))
		return nil, errs.Newf(errs.CodeUnavailable, KeyNetFetchFailed, "ext: net.fetch: %v", shortErr(err))
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(io.LimitReader(resp.Body, f.limits.MaxResponseBody+1))
	if err != nil {
		f.logf(LogError, "fetch FAILED %s: reading body: %v", safeMethodURL(req), shortErr(err))
		return nil, errs.Newf(errs.CodeUnavailable, KeyNetFetchFailed, "ext: net.fetch: %v", shortErr(err))
	}
	if int64(len(body)) > f.limits.MaxResponseBody {
		f.logf(LogWarn, "fetch DENIED %s: response exceeds %d bytes", safeMethodURL(req), f.limits.MaxResponseBody)
		return nil, errs.Newf(errs.CodeResourceExhausted, KeyNetFetchFailed,
			"ext: net.fetch: response exceeds %d bytes", f.limits.MaxResponseBody)
	}
	f.logf(LogInfo, "fetch %s -> %d (%d bytes)", safeMethodURL(req), resp.StatusCode, len(body))
	return &FetchResponse{Status: resp.StatusCode, Headers: resp.Header.Clone(), Body: body}, nil
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
	if ip := net.ParseIP(host); ip != nil {
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

func hasString(list []string, want string) bool {
	for _, s := range list {
		if s == want {
			return true
		}
	}
	return false
}

// safeMethodURL renders "METHOD url" for logs without credentials (userinfo
// is rejected anyway) and bounded length.
func safeMethodURL(req FetchRequest) string {
	method := strings.ToUpper(strings.TrimSpace(req.Method))
	if method == "" {
		method = http.MethodGet
	}
	u := strings.TrimSpace(req.URL)
	if len(u) > 200 {
		u = u[:200] + "…"
	}
	return method + " " + u
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
