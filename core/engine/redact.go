package engine

import (
	"regexp"
	"sort"
	"strings"
	"sync"
)

// Redactor masks credentials in engine output, controller errors, and events
// before they leave the core. It matches plan values exactly and uses patterns
// for unknown values such as engine-generated tokens.
type Redactor struct {
	mu     sync.Mutex
	values []string
	build  *strings.Replacer
}

// NewRedactor returns a redactor seeded with the plan secrets.
func NewRedactor(values ...string) *Redactor {
	r := &Redactor{}
	r.Add(values...)
	return r
}

// Add registers values to mask. Values shorter than four characters are ignored
// to preserve ordinary log text.
func (r *Redactor) Add(values ...string) {
	added := false
	r.mu.Lock()
	for _, v := range values {
		if len(v) < 4 {
			continue
		}
		duplicate := false
		for _, have := range r.values {
			if have == v {
				duplicate = true
				break
			}
		}
		if !duplicate {
			r.values = append(r.values, v)
			added = true
		}
	}
	if added {
		// Match longest secrets first so strings.Replacer cannot
		// partially mask a longer value.
		sort.SliceStable(r.values, func(i, j int) bool { return len(r.values[i]) > len(r.values[j]) })
		r.build = nil
	}
	r.mu.Unlock()
}

// String masks one piece of text.
func (r *Redactor) String(s string) string {
	if s == "" {
		return s
	}
	r.mu.Lock()
	if r.build == nil {
		pairs := make([]string, 0, len(r.values)*2)
		for _, v := range r.values {
			pairs = append(pairs, v, "[masked]")
		}
		r.build = strings.NewReplacer(pairs...)
	}
	out := r.build.Replace(s)
	r.mu.Unlock()
	return maskPatterns(out)
}

// Err masks an error, keeping the wrap chain so errors.Is still works.
func (r *Redactor) Err(err error) error {
	if err == nil {
		return nil
	}
	return &maskedError{Redactor: r, cause: err}
}

type maskedError struct {
	Redactor *Redactor
	cause    error
}

func (e *maskedError) Error() string { return e.Redactor.String(e.cause.Error()) }
func (e *maskedError) Unwrap() error { return e.cause }

var (
	uuidPattern = regexp.MustCompile(`(?i)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`)
	// keyValuePattern masks credential pairs. Keys cover the naming
	// styles configs use (kebab, snake, camel); the separator tolerates
	// JSON quoting with or without spaces, and the value tolerates
	// quoting so a quoted phrase is masked whole: without the quoted
	// alternation, token: "my secret value" would mask only "my and
	// leave 'secret value"' in the log. Note the separator deliberately
	// does NOT consume a quote after ":" - eating it would make the
	// value alternation fall through to \S+ and leak the tail of the
	// phrase ("token: \"a b\"" used to mask only "a). Hosts stay
	// readable: only the pair is masked.
	// The key alternation is the canonical superset shared byte-for-byte
	// with sora-legacy's redactor: pre[_-]?shared[_-]?key covers every
	// WireGuard spelling (pre_shared_key is the literal sing-box JSON
	// field name), spider[_-]?x covers spider_x/spider-x/spiderx, and
	// public[_-]?key is present on both sides.
	// TestRedactorParityKeySpellings in both repos pins this list by
	// execution.
	keyValuePattern = regexp.MustCompile(`(?i)\b(uuid|password|passwd|secret|(?:access|refresh|session|id|auth|api)[_-]?token|token|private[_-]?key|pre[_-]?shared[_-]?key|obfs[_-]?password|obfs[_-]?param|api[_-]?key|auth(?:[_-]?str)?|secret[_-]?key|client[_-]?secret|psk|public[_-]?key|short[_-]?id|spider[_-]?x|username)\b([\"']?\s*[:=]\s*|\s+)("[^"]*"|'[^']*'|\S+)`)
	// strictKeyValuePattern masks short generic credential keys only with
	// an explicit assignment: a bare space after "user" or "login" is
	// usually prose ("user agent", "login failed"), not a credential pair.
	strictKeyValuePattern = regexp.MustCompile(`(?i)\b(user|login)\b([\"']?\s*[:=]\s*)("[^"]*"|'[^']*'|\S+)`)
	// userInfoPattern masks the credentials of proxy links for every
	// protocol the core parses. The password half is optional:
	// trojan://token@host, hysteria2://secret@host and vless://id@host
	// carry a single token. The host stays readable for diagnosis.
	userInfoPattern = regexp.MustCompile(`(?i)\b(https?|socks5?h?|socks4a?|ssr?|vless|vmess|trojan|hysteria2?|hy2|tuic|wireguard|wg|naive|snell)://[^/\s@]+@`)
	// tokenLinkPattern masks schemeless-credential links whose secret is a
	// bare token with no userinfo, such as vmess://base64json. The
	// fragment stays readable: it is the user's display name.
	tokenLinkPattern = regexp.MustCompile(`(?i)\b(vmess|ssr)://[A-Za-z0-9+/_=-]+`)
	// authHeaderPattern masks HTTP Authorization credentials
	// (Authorization: Bearer/Basic ...): the keyValue alternation cannot
	// see them — after "auth" in "Authorization" there is no word
	// boundary, and the credential itself carries no key at all.
	authHeaderPattern = regexp.MustCompile(`(?i)\b(authorization\s*[:=]\s*(?:bearer|basic)\s+)(\S+)`)
	// bearerPattern masks a bare Bearer token (curl-style dumps, proxy
	// logs) with no Authorization header around it. The value must look
	// like a token (12+ token characters) so prose ("bearer of news",
	// "bearer instrument") is never masked.
	bearerPattern = regexp.MustCompile(`(?i)\b(bearer\s+)([A-Za-z0-9._~+/=-]{12,})`)
)

// gateWords is the conservative fast path for maskPatterns: every
// pattern below can only match text containing "://" (URL userinfo and
// token links), one of these credential key words (the alternations in
// keyValuePattern/strictKeyValuePattern all contain one as a substring),
// or a UUID shape, which needs at least four dashes. A log line with
// none of these cannot be changed by any pattern, so it skips all five
// regexp passes — most engine output is such lines, and the passes cost
// tens of microseconds each on the big alternations. The gate is a
// superset by construction (substring presence, no word boundaries):
// when in doubt it lets the line through to the real patterns. It is a
// lowercase substring scan on purpose: a case-insensitive regexp gate
// measured 24µs per line, nearly as slow as the patterns themselves.
var gateWords = []string{
	"://", "uuid", "password", "passwd", "secret", "token", "key", "param",
	"auth", "psk", "username", "user", "login", "spider", "short", "bearer",
}

// gateContains reports whether s holds any gate word, case-insensitively.
func gateContains(s string) bool {
	l := strings.ToLower(s)
	for _, w := range gateWords {
		if strings.Contains(l, w) {
			return true
		}
	}
	return false
}

// keyGateWords are the substrings that gate keyValuePattern alone: every
// alternative of its key alternation contains one of them (uuid/password/
// passwd/secret/token/psk/spider/short literally; every *_key/*-key form
// contains "key"; obfs_param contains "param"; auth and auth_str contain
// "auth"; username contains "user"). A line with none of them cannot be
// changed by keyValuePattern.
var keyGateWords = []string{
	"uuid", "password", "passwd", "secret", "token", "key", "param",
	"auth", "psk", "user", "spider", "short",
}

// isASCII reports whether s is plain ASCII, where case folding is a
// per-byte operation and the gate scans below are exact. Non-ASCII text
// keeps the strings.ToLower gate: Unicode folding (e.g. U+212A KELVIN
// SIGN folding to "k") is observable there and must not change.
func isASCII(s string) bool {
	for i := 0; i < len(s); i++ {
		if s[i] >= 0x80 {
			return false
		}
	}
	return true
}

// gateFlags holds the per-pattern necessary conditions of one ASCII
// line, computed by gateFlagsASCII in a single pass.
type gateFlags struct {
	scheme bool // "://" present: userInfoPattern/tokenLinkPattern may match
	key    bool // a keyGateWords substring: keyValuePattern may match
	strict bool // "user"/"login" present: strictKeyValuePattern may match
	uuid   bool // at least four dashes: uuidPattern may match
	bearer bool // "bearer"/"authorization" present: authHeaderPattern/bearerPattern may match
}

// matchFoldAt reports whether w (lowercase ASCII) occurs in s at i,
// folding ASCII letters only.
func matchFoldAt(s string, i int, w string) bool {
	if i+len(w) > len(s) {
		return false
	}
	for j := 0; j < len(w); j++ {
		c := s[i+j]
		if 'A' <= c && c <= 'Z' {
			c += 'a' - 'A'
		}
		if c != w[j] {
			return false
		}
	}
	return true
}

// gateFlagsASCII computes the flags in one pass over s, trying gate
// words only at positions whose folded byte can start one. It allocates
// nothing, unlike the ToLower copy gateContains makes of every line.
func gateFlagsASCII(s string) gateFlags {
	var f gateFlags
	dashes := 0
	for i := 0; i < len(s); i++ {
		c := s[i]
		if c == '-' {
			dashes++
			continue
		}
		if 'A' <= c && c <= 'Z' {
			c += 'a' - 'A'
		}
		switch c {
		case ':':
			if i+2 < len(s) && s[i+1] == '/' && s[i+2] == '/' {
				f.scheme = true
			}
		case 'u':
			if matchFoldAt(s, i, "user") {
				f.key, f.strict = true, true
			}
			if matchFoldAt(s, i, "uuid") {
				f.key = true
			}
		case 'p':
			if matchFoldAt(s, i, "password") || matchFoldAt(s, i, "passwd") || matchFoldAt(s, i, "psk") || matchFoldAt(s, i, "param") {
				f.key = true
			}
		case 's':
			if matchFoldAt(s, i, "secret") || matchFoldAt(s, i, "spider") || matchFoldAt(s, i, "short") {
				f.key = true
			}
		case 't':
			if matchFoldAt(s, i, "token") {
				f.key = true
			}
		case 'k':
			if matchFoldAt(s, i, "key") {
				f.key = true
			}
		case 'a':
			if matchFoldAt(s, i, "auth") {
				f.key = true
			}
			if matchFoldAt(s, i, "authorization") {
				f.bearer = true
			}
		case 'b':
			if matchFoldAt(s, i, "bearer") || matchFoldAt(s, i, "basic") {
				f.bearer = true
			}
		case 'l':
			if matchFoldAt(s, i, "login") {
				f.strict = true
			}
		}
		if f.scheme && f.key && f.strict && f.bearer && dashes >= 4 {
			break
		}
	}
	f.uuid = dashes >= 4
	return f
}

// maskPatterns masks identifiers, credential pairs, and URL credentials whose
// exact values are unknown.
func maskPatterns(s string) string {
	if !isASCII(s) {
		// The original gate and full pipeline, unchanged: Unicode case
		// folding decides what the (?i) patterns can see, so no ASCII
		// shortcut may skip a pass here.
		if !gateContains(s) && strings.Count(s, "-") < 4 {
			return s
		}
		s = userInfoPattern.ReplaceAllString(s, "${1}://[masked]@")
		s = tokenLinkPattern.ReplaceAllString(s, "${1}://[masked]")
		s = authHeaderPattern.ReplaceAllString(s, "${1}[masked]")
		s = bearerPattern.ReplaceAllString(s, "${1}[masked]")
		s = keyValuePattern.ReplaceAllString(s, "${1}${2}[masked]")
		s = strictKeyValuePattern.ReplaceAllString(s, "${1}${2}[masked]")
		s = uuidPattern.ReplaceAllString(s, "[masked]")
		return s
	}
	// ASCII fast path: one gate per pattern, each a necessary condition
	// for that pattern to match at all —
	//   userInfo/tokenLink need a literal "://";
	//   keyValue needs one of keyGateWords (see its comment);
	//   strictKeyValue needs "user" or "login";
	//   uuid needs at least four dashes (the pattern has exactly four).
	// The flags are computed once, on entry. That stays a superset for
	// the string each later pattern actually receives: the replacements
	// only delete spans and insert "[masked]"/"[masked]@", whose bracket
	// characters no gate word can span, and keyValue preserves its key
	// and separator verbatim — so no pass can create a trigger (scheme,
	// key word, user/login, dashes) that the entry string lacked. A
	// skipped pattern therefore provably cannot match, and the output is
	// byte-identical to the unconditional pipeline (pinned by
	// TestMaskPatternsDifferential).
	f := gateFlagsASCII(s)
	if !f.scheme && !f.key && !f.strict && !f.uuid && !f.bearer {
		return s
	}
	if f.scheme {
		s = userInfoPattern.ReplaceAllString(s, "${1}://[masked]@")
		s = tokenLinkPattern.ReplaceAllString(s, "${1}://[masked]")
	}
	if f.bearer {
		s = authHeaderPattern.ReplaceAllString(s, "${1}[masked]")
		s = bearerPattern.ReplaceAllString(s, "${1}[masked]")
	}
	if f.key {
		s = keyValuePattern.ReplaceAllString(s, "${1}${2}[masked]")
	}
	if f.strict {
		s = strictKeyValuePattern.ReplaceAllString(s, "${1}${2}[masked]")
	}
	if f.uuid {
		s = uuidPattern.ReplaceAllString(s, "[masked]")
	}
	return s
}
