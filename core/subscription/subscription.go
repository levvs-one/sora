// Package subscription fetches bearer-token references over HTTPS only. Every
// redirect is validated and counted; bodies are size-limited. Responses contain
// credentials and are never cached on disk.
package subscription

import (
	"context"
	"hash/fnv"
	"io"
	"net"
	"net/http"
	"net/netip"
	"net/url"
	"strings"
	"syscall"
	"time"

	"github.com/levvs-one/sora-client/core/errs"
)

// Default retrieval limits allow distant providers while bounding total fetch
// time to half a minute.
const (
	// DefaultTimeout bounds one retrieval, redirects included.
	DefaultTimeout = 30 * time.Second
	// MaxRedirects limits validated redirect hops carrying the bearer
	// reference.
	MaxRedirects = 5
	// MaxBodyBytes matches the import size limit, allowing accepted bodies
	// to reach parsing.
	MaxBodyBytes = 16 << 20
	// MaxUserAgent bounds the User-Agent a subscription may set.
	MaxUserAgent = 256
)

// DefaultUserAgents is the fetch User-Agent pool, as data: when a
// subscription sets no override, the fetcher sends one of these
// ordinary browser agents, chosen deterministically by provider host
// (see userAgentForHost). A single hard-coded client agent would be
// a fingerprint — every sora install fetching with the same
// self-naming string tells the provider's logs (and anyone who reads
// them) exactly which client this is, and a censor with provider
// access could correlate users by it. A per-host pick from a small
// pool of agents real browsers send has neither property: the same
// provider always sees the same agent from this install (so any
// format the panel selects by agent stays stable), while different
// providers see different, unremarkable agents.
//
// The pool is data, not code: refresh the strings on release like
// any other fingerprint data. Panels that need a specific client
// format still get it through the per-subscription UserAgent
// override, which always wins over the pool.
var DefaultUserAgents = []string{
	"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36",
	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.4 Safari/605.1.15",
	"Mozilla/5.0 (X11; Linux x86_64; rv:140.0) Gecko/20100101 Firefox/140.0",
	"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36 Edg/138.0.0.0",
}

// userAgentForHost picks the pool agent for a provider host:
// FNV-1a over the normalized host, stable across runs and fetches,
// so one provider's view of this install never rotates.
func userAgentForHost(host string) string {
	h := fnv.New32a()
	_, _ = h.Write([]byte(strings.ToLower(strings.TrimSpace(host))))
	return DefaultUserAgents[int(h.Sum32())%len(DefaultUserAgents)]
}

// FetchOptions configures one subscription retrieval.
type FetchOptions struct {
	// UserAgent overrides the default because panels may choose
	// client-specific subscription formats.
	UserAgent string
	// FallbackURL is a reserve subscription reference, tried only when
	// the primary reference fails. Callers that store the fallback
	// beside the primary (the subscription book) pass it here; a
	// fallback-url fragment on the reference itself is honoured too
	// and is used when this field is empty.
	FallbackURL string
	// Device carries the provider device identity (C1, see device.go).
	// It is attached to this fetch only — primary, fallback and every
	// redirect hop — and to nothing else the client ever requests.
	// The zero value sends no device headers (the user's opt-out).
	Device DeviceHeaders
}

// Result is one retrieved subscription.
type Result struct {
	Body []byte
	// Info contains provider response headers and leading body metadata.
	Info Info
	// UsedFallback reports that the primary reference failed and this
	// body came from the fallback reference. It is set only on a
	// fallback success, so callers can log and show the switch instead
	// of silently presenting the reserve as the primary.
	UsedFallback bool
}

// Options configures a fetcher.
type Options struct {
	// Timeout bounds one retrieval.
	Timeout time.Duration
	// MaxRedirects limits redirect hops carrying the bearer reference.
	MaxRedirects int
	// MaxBodyBytes is the largest body accepted.
	MaxBodyBytes int
	// HTTPClient performs requests. Nil verifies certificates and leaves
	// redirects to this package. Only tests may inject a client trusting a
	// local test server.
	HTTPClient *http.Client
}

// Fetcher retrieves subscription bodies.
type Fetcher struct {
	client       *http.Client
	timeout      time.Duration
	maxRedirects int
	maxBody      int
}

// New returns a fetcher with the defaults filled in.
func New(opts Options) *Fetcher {
	if opts.Timeout <= 0 {
		opts.Timeout = DefaultTimeout
	}
	if opts.MaxRedirects <= 0 {
		opts.MaxRedirects = MaxRedirects
	}
	if opts.MaxBodyBytes <= 0 {
		opts.MaxBodyBytes = MaxBodyBytes
	}
	client := opts.HTTPClient
	if client == nil {
		client = &http.Client{
			// Handle redirects here so every hop is validated and
			// counted.
			CheckRedirect: func(*http.Request, []*http.Request) error {
				return http.ErrUseLastResponse
			},
			Transport: &http.Transport{
				Proxy:                 http.ProxyFromEnvironment,
				DialContext:           dialChecked,
				ForceAttemptHTTP2:     true,
				MaxIdleConns:          8,
				IdleConnTimeout:       30 * time.Second,
				TLSHandshakeTimeout:   10 * time.Second,
				ExpectContinueTimeout: time.Second,
				ResponseHeaderTimeout: 20 * time.Second,
			},
		}
	}
	return &Fetcher{
		client:       client,
		timeout:      opts.Timeout,
		maxRedirects: opts.MaxRedirects,
		maxBody:      opts.MaxBodyBytes,
	}
}

// Fetch validates HTTPS and redirect limits on every hop and bounds the body.
// Failures stop retrieval without including the bearer reference in error
// details.
//
// When the reference declares a fallback (a fallback-url fragment, or
// FetchOptions.FallbackURL) and the primary attempt fails, the fallback
// is tried once under the exact same validation, redirect, and dial
// rules, with its own timeout budget. A fallback success is marked with
// Result.UsedFallback. When both attempts fail, the primary error is
// returned: it names the failure the user must act on, and the fallback
// outcome never masks it. Caller cancellation suppresses the fallback
// attempt entirely.
func (f *Fetcher) Fetch(ctx context.Context, reference string, opts FetchOptions) (Result, error) {
	agent, err := UserAgentFor(opts.UserAgent)
	if err != nil {
		return Result{}, err
	}
	device, err := opts.Device.validated()
	if err != nil {
		return Result{}, err
	}
	primary, fragmentFallback, err := SplitFallback(reference)
	if err != nil {
		return Result{}, err
	}
	if agent == "" {
		// No override: the pool agent for this provider host. It is
		// chosen once, from the primary reference, and used for the
		// fallback and every redirect hop too — a real browser does
		// not change its agent mid-retrieval.
		target, verr := ValidateReference(primary)
		if verr != nil {
			return Result{}, verr
		}
		agent = userAgentForHost(target.Hostname())
	}
	fallback := strings.TrimSpace(opts.FallbackURL)
	if fallback == "" {
		fallback = fragmentFallback
	}
	if fallback != "" {
		if _, err := ValidateReference(fallback); err != nil {
			return Result{}, err
		}
	}
	result, err := f.fetch(ctx, primary, agent, device)
	if err == nil {
		return result, nil
	}
	if fallback == "" || ctx.Err() != nil {
		return Result{}, err
	}
	reserve, reserveErr := f.fetch(ctx, fallback, agent, device)
	if reserveErr != nil {
		return Result{}, err
	}
	reserve.UsedFallback = true
	return reserve, nil
}

// fetch retrieves one reference, following validated redirects. The
// fragment is cleared before the first request: fragments are client
// side only and must never reach a provider.
func (f *Fetcher) fetch(ctx context.Context, reference string, agent string, device DeviceHeaders) (Result, error) {
	target, err := ValidateReference(reference)
	if err != nil {
		return Result{}, err
	}
	target.Fragment, target.RawFragment = "", ""
	ctx, cancel := context.WithTimeout(ctx, f.timeout)
	defer cancel()
	ctx = context.WithValue(ctx, privateKey{}, isPrivateHost(target.Hostname()))

	for hop := 0; ; hop++ {
		if hop > f.maxRedirects {
			return Result{}, errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionRedirect,
				"subscription: the provider led the request more than %d times", f.maxRedirects)
		}
		body, header, location, err := f.hop(ctx, target, agent, device)
		if err != nil {
			return Result{}, err
		}
		if location == "" {
			return Result{Body: body, Info: parseInfo(header, body)}, nil
		}
		// Resolve relative redirects against the response URL, as
		// allowed by HTTP standards.
		moved, err := url.Parse(location)
		if err != nil {
			return Result{}, errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionRedirect,
				"subscription: the provider sent a redirect that is not a location")
		}
		target, err = ValidateReference(target.ResolveReference(moved).String())
		if err != nil {
			return Result{}, err
		}
		target.Fragment, target.RawFragment = "", ""
	}
}

// hop returns one response's body and headers or its redirect target.
func (f *Fetcher) hop(ctx context.Context, target *url.URL, agent string, device DeviceHeaders) ([]byte, http.Header, string, error) {
	request, err := http.NewRequestWithContext(ctx, http.MethodGet, target.String(), nil)
	if err != nil {
		// HTTP errors include bearer URLs; rebuild details using only
		// the cause.
		return nil, nil, "", errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionScheme,
			"subscription: the reference is not a url this client can request")
	}
	request.Header.Set("User-Agent", agent)
	// The device identity rides this request only; hop is called for
	// the primary, the fallback and every redirect, and for nothing
	// outside a subscription fetch.
	device.apply(request.Header)
	request.Header.Set("Accept", "text/plain, application/octet-stream, */*")
	// Bound decompressed size so compressed responses cannot exceed the
	// body limit.
	request.Header.Set("Accept-Encoding", "identity")

	response, err := f.client.Do(request)
	if err != nil {
		return nil, nil, "", errs.From(err)
	}
	defer func() {
		// Drain and close for connection reuse, but bound draining so
		// rejected responses cannot retain sockets indefinitely.
		_, _ = io.Copy(io.Discard, io.LimitReader(response.Body, drainLimit))
		_ = response.Body.Close()
	}()

	if location := redirectTarget(response); location != "" {
		return nil, nil, location, nil
	}
	if response.StatusCode != http.StatusOK {
		failure := errs.Newf(errs.CodeUnavailable, errs.KeySubscriptionStatus,
			"subscription: the provider answered %d", response.StatusCode)
		// Retry transient provider failures; rejected tokens need user
		// action and must not be retried.
		if response.StatusCode >= http.StatusInternalServerError ||
			response.StatusCode == http.StatusTooManyRequests {
			return nil, nil, "", failure.WithRetry(0)
		}
		return nil, nil, "", failure
	}
	if response.ContentLength > int64(f.maxBody) {
		return nil, nil, "", errs.Newf(errs.CodeResourceExhausted, errs.KeySubscriptionTooLarge,
			"subscription: the provider announced %d bytes, the limit is %d",
			response.ContentLength, f.maxBody)
	}
	body, err := io.ReadAll(io.LimitReader(response.Body, int64(f.maxBody)+1))
	if err != nil {
		return nil, nil, "", errs.From(err)
	}
	if len(body) > f.maxBody {
		return nil, nil, "", errs.Newf(errs.CodeResourceExhausted, errs.KeySubscriptionTooLarge,
			"subscription: the body is larger than the limit of %d bytes", f.maxBody)
	}
	if len(body) == 0 {
		return nil, nil, "", errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionEmpty,
			"subscription: the provider answered with an empty body")
	}
	return body, response.Header, "", nil
}

// drainLimit bounds unwanted body reads for connection reuse. Larger bodies
// discard the connection instead of wasting reads.
const drainLimit = 4 << 10

// redirectTarget returns the next URL or empty for a final response.
func redirectTarget(response *http.Response) string {
	switch response.StatusCode {
	case http.StatusMovedPermanently, http.StatusFound, http.StatusSeeOther,
		http.StatusTemporaryRedirect, http.StatusPermanentRedirect:
	default:
		return ""
	}
	return response.Header.Get("Location")
}

// ValidateReference parses HTTPS references and rejects HTTP to avoid sending
// bearer tokens in cleartext.
func ValidateReference(reference string) (*url.URL, error) {
	trimmed := strings.TrimSpace(reference)
	if trimmed == "" {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionScheme,
			"subscription: the reference is empty")
	}
	parsed, err := url.Parse(trimmed)
	if err != nil {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionScheme,
			"subscription: the reference is not a url")
	}
	if parsed.User != nil {
		// Reject URL user info to avoid additional credentials in
		// reference strings and logs.
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionScheme,
			"subscription: the reference carries credentials of its own")
	}
	switch strings.ToLower(parsed.Scheme) {
	case "https":
	case "http":
		return nil, errs.Newf(errs.CodeUnsupported, errs.KeySubscriptionScheme,
			"subscription: the reference uses http, which would send the token in clear")
	default:
		return nil, errs.Newf(errs.CodeUnsupported, errs.KeySubscriptionScheme,
			"subscription: the reference is not an http or https url")
	}
	if parsed.Host == "" {
		return nil, errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionScheme,
			"subscription: the reference has no host")
	}
	return parsed, nil
}

// UserAgentFor validates an override. An empty override returns ""
// and means "the fetcher picks the pool agent for the provider host"
// (see DefaultUserAgents): the default is per-provider data, not one
// global client string. Line breaks are rejected to prevent header
// injection.
func UserAgentFor(asked string) (string, error) {
	trimmed := strings.TrimSpace(asked)
	if trimmed == "" {
		return "", nil
	}
	if len(trimmed) > MaxUserAgent {
		return "", errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionScheme,
			"subscription: the User-Agent is longer than %d bytes", MaxUserAgent)
	}
	for _, r := range trimmed {
		if r < 0x20 || r > 0x7e {
			return "", errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionScheme,
				"subscription: the User-Agent may hold printable ASCII only")
		}
	}
	return trimmed, nil
}

// privateKey permits private destinations only for initially local
// subscriptions. Internet providers cannot redirect the service into local
// networks.
type privateKey struct{}

// isPrivateHost reports whether host is a private IP literal or localhost.
// DNS answers are deliberately ignored: an attacker controlling DNS could
// otherwise flip a hostname into the private range and permit dials to
// internal addresses (SORA-L11). Hostnames resolving to private addresses
// are not trusted; use an IP literal for local subscriptions.
func isPrivateHost(host string) bool {
	addr, err := netip.ParseAddr(host)
	if err != nil {
		return false
	}
	return !publicAddr(addr)
}

func publicAddr(addr netip.Addr) bool {
	addr = addr.Unmap()
	if !addr.IsGlobalUnicast() || addr.IsPrivate() {
		return false
	}
	// IsGlobalUnicast still reports special-use ranges as global; none of
	// them is a reachable public subscription host.
	for _, p := range specialUsePrefixes {
		if p.Contains(addr) {
			return false
		}
	}
	return true
}

// specialUsePrefixes are globally-unreachable ranges that IsGlobalUnicast
// reports as global unicast.
var specialUsePrefixes = []netip.Prefix{
	netip.MustParsePrefix("100.64.0.0/10"),   // CGNAT (RFC 6598)
	netip.MustParsePrefix("192.0.2.0/24"),    // documentation (RFC 5737)
	netip.MustParsePrefix("198.51.100.0/24"), // documentation (RFC 5737)
	netip.MustParsePrefix("203.0.113.0/24"),  // documentation (RFC 5737)
	netip.MustParsePrefix("198.18.0.0/15"),   // benchmarking (RFC 2544)
	netip.MustParsePrefix("240.0.0.0/4"),     // reserved (RFC 1112)
	netip.MustParsePrefix("2001:db8::/32"),   // documentation (RFC 3849)
}

// dialChecked rejects private resolved addresses unless the subscription is
// local. Checking the actual dial target after DNS prevents rebinding bypasses.
func dialChecked(ctx context.Context, network, address string) (net.Conn, error) {
	allowPrivate, _ := ctx.Value(privateKey{}).(bool)
	dialer := &net.Dialer{
		Timeout: 30 * time.Second,
		Control: func(_, address string, _ syscall.RawConn) error {
			return checkDial(allowPrivate, address)
		},
	}
	return dialer.DialContext(ctx, network, address)
}

// checkDial validates one resolved address using dialChecked's policy.
func checkDial(allowPrivate bool, address string) error {
	host, _, err := net.SplitHostPort(address)
	if err != nil {
		return err
	}
	addr, err := netip.ParseAddr(host)
	if err != nil {
		return err
	}
	if allowPrivate || publicAddr(addr) {
		return nil
	}
	return errs.Newf(errs.CodePermissionDenied, errs.KeySubscriptionRedirect,
		"subscription: the request was led to an address outside the internet")
}
