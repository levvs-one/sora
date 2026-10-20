package engine

import (
	"encoding/base64"
	"encoding/hex"
	"encoding/json"
	"net/url"
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
			// A seed that reaches a log rarely arrives raw: engines
			// and HTTP stacks re-encode it (percent-encoding in URLs
			// and error strings, base64 in vmess-style blobs and
			// subscription bodies, hex in WireGuard tooling, JSON
			// \uXXXX escapes in rendered configs). Masking only the
			// raw form left every one of those encodings readable —
			// the encoded forms are part of the seed, so they are
			// registered alongside it (CENSOR-LEAK: close the class,
			// not the latest spelling).
			for _, form := range derivedForms(v) {
				if form != v && len(form) >= 4 {
					pairs = append(pairs, form, "[masked]")
				}
			}
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

// derivedForms returns the re-encodings of a seed value that log
// pipelines commonly produce: URL percent-encoding (query and path
// flavours; every byte escaped as well as only the specials; upper-
// and lowercase hex digits), base64 (standard and URL-safe, padded
// and raw), hex (lower- and uppercase), and the JSON string escaping
// of the value (\" \\ and \uXXXX forms, the fully-escaped per-rune
// form, and single-rune escapes). The list is computed once per
// redactor rebuild, alongside the seeds themselves.
//
// Case contract (CENSOR-LEAK review): real encoders are consistent
// within one string — Go's hex is lowercase, %X-style encoders are
// uppercase, JSON \uXXXX writers pick one case — so the pure upper
// and lower forms of every encoding are registered. Forms that mix
// cases character by character would need a per-character case
// randomiser no known encoder is; they are the documented residual,
// together with multi-character escape subsets beyond the single-
// escape forms registered below.
func derivedForms(v string) []string {
	forms := make([]string, 0, 10)
	add := func(s string) {
		for _, have := range forms {
			if have == s {
				return
			}
		}
		forms = append(forms, s)
	}
	for _, esc := range []string{url.QueryEscape(v), url.PathEscape(v)} {
		add(esc)
		add(lowerPercentHex(esc))
	}
	// An encoder that escapes every byte, not only the specials
	// (defensive formatters, some subscription proxies): the seed
	// then survives as one long %XX run in both hex cases.
	add(percentEncodeAll(v, true))
	add(percentEncodeAll(v, false))
	raw := []byte(v)
	for _, enc := range []*base64.Encoding{
		base64.StdEncoding, base64.RawStdEncoding,
		base64.URLEncoding, base64.RawURLEncoding,
	} {
		add(enc.EncodeToString(raw))
	}
	// WireGuard tooling and %X formatters print hex uppercase; the
	// pure-uppercase form is a different string the replacer must
	// know, symmetric to lowercase percent-hex.
	lowerHex := hex.EncodeToString(raw)
	add(lowerHex)
	add(strings.ToUpper(lowerHex))
	if marshalled, err := json.Marshal(v); err == nil && len(marshalled) >= 2 {
		inner := string(marshalled[1 : len(marshalled)-1])
		add(inner)
		// Encoders disagree on the case of \uXXXX hex digits in
		// the escapes json.Marshal does emit (\u003c vs \u003C).
		add(upperUnicodeHexDigits(inner))
	}
	// Per-rune \uXXXX: encoders that escape every character, and
	// encoders that escape exactly one character of an otherwise
	// raw string (the reviewer's mysecr\u0065t1234 probe), in both
	// hex cases.
	uni := unicodeEscapeAll(v)
	add(uni)
	add(upperUnicodeHexDigits(uni))
	// Single-position escapes are enumerated only for bounded
	// seeds: the form count grows linearly with the seed, and a
	// very long seed's single-escape variants would bloat the
	// replacer for a shape no encoder produces at that length.
	if len(v) <= 64 {
		for _, form := range singleEscapes(v) {
			add(form)
		}
	}
	return forms
}

// percentEncodeAll escapes every byte of v as %XX (upper selects the
// hex digit case), the full-encoding form derivedForms documents.
func percentEncodeAll(v string, upper bool) string {
	const digitsLower, digitsUpper = "0123456789abcdef", "0123456789ABCDEF"
	digits := digitsLower
	if upper {
		digits = digitsUpper
	}
	var b strings.Builder
	b.Grow(len(v) * 3)
	for i := 0; i < len(v); i++ {
		c := v[i]
		b.WriteByte('%')
		b.WriteByte(digits[c>>4])
		b.WriteByte(digits[c&0x0f])
	}
	return b.String()
}

// unicodeEscapeAll escapes every rune of v as \uXXXX with lowercase
// hex digits, using a surrogate pair above the BMP exactly as JSON
// string encoders do.
func unicodeEscapeAll(v string) string {
	var b strings.Builder
	for _, r := range v {
		writeUnicodeEscape(&b, r)
	}
	return b.String()
}

// writeUnicodeEscape writes one rune as \uXXXX (lowercase hex), or a
// surrogate pair for runes above U+FFFF.
func writeUnicodeEscape(b *strings.Builder, r rune) {
	const digits = "0123456789abcdef"
	put := func(u uint16) {
		b.WriteString(`\u`)
		for shift := 12; shift >= 0; shift -= 4 {
			b.WriteByte(digits[(u>>uint(shift))&0x0f])
		}
	}
	if r > 0xffff {
		r -= 0x10000
		put(uint16(0xd800 + (r >> 10)))
		put(uint16(0xdc00 + (r & 0x3ff)))
		return
	}
	put(uint16(r))
}

// upperUnicodeHexDigits uppercases the four hex digits of every
// \uXXXX escape in s; all other bytes pass through unchanged.
func upperUnicodeHexDigits(s string) string {
	b := []byte(s)
	for i := 0; i+5 < len(b); i++ {
		if b[i] != '\\' || b[i+1] != 'u' {
			continue
		}
		ok := true
		for j := i + 2; j <= i+5; j++ {
			c := b[j]
			if !('0' <= c && c <= '9' || 'a' <= c && c <= 'f' || 'A' <= c && c <= 'F') {
				ok = false
				break
			}
		}
		if !ok {
			continue
		}
		for j := i + 2; j <= i+5; j++ {
			if 'a' <= b[j] && b[j] <= 'f' {
				b[j] -= 'a' - 'A'
			}
		}
		i += 5
	}
	return string(b)
}

// singleEscapes returns the forms of v in which exactly one position
// is escaped and the rest is raw: per byte as %XX (both hex cases)
// and per rune as \uXXXX (both hex cases). These are the shapes an
// encoder produces when it escapes one character class member inside
// an otherwise literal string.
func singleEscapes(v string) []string {
	const digitsLower, digitsUpper = "0123456789abcdef", "0123456789ABCDEF"
	var out []string
	for i := 0; i < len(v); i++ {
		for _, digits := range []string{digitsUpper, digitsLower} {
			c := v[i]
			out = append(out, v[:i]+"%"+string([]byte{digits[c>>4], digits[c&0x0f]})+v[i+1:])
		}
	}
	// Rune offsets for the \u forms; a rune-wise walk keeps
	// multi-byte characters intact (escaping half a UTF-8 sequence
	// is not a form any JSON encoder emits).
	for i, r := range v {
		var esc strings.Builder
		writeUnicodeEscape(&esc, r)
		lower := esc.String()
		for _, form := range []string{lower, upperUnicodeHexDigits(lower)} {
			out = append(out, v[:i]+form+v[i+len(string(r)):])
		}
	}
	return out
}

// lowerPercentHex lowercases the hex digits of %XX escapes: encoders
// disagree on the case, and a seed masked as %2F must also be masked
// as %2f.
func lowerPercentHex(s string) string {
	b := []byte(s)
	for i := 0; i+2 < len(b); i++ {
		if b[i] != '%' {
			continue
		}
		for j := i + 1; j <= i+2; j++ {
			if 'A' <= b[j] && b[j] <= 'F' {
				b[j] += 'a' - 'A'
			}
		}
		i += 2
	}
	return string(b)
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
	// The value's quoted alternatives carry a glued-suffix tail
	// ([^\s,;}\]\)]*): characters stuck to the closing quote with
	// no whitespace are part of the same token — token: "abc"def
	// and token: ""0 are one value, not a value plus a tail. The
	// old pattern stopped at the closing quote and left the tail
	// readable; worse, the tail then merged with the [masked]
	// replacement on a second pass, so masking was not idempotent
	// (FuzzRedactorNoPanicAndIdempotent's token  ""0 crash). The
	// tail class stops at structural delimiters (, ; } ] )) so a
	// compact-JSON separator after a quoted value survives; a
	// suffix behind such a delimiter is frozen by the [masked]
	// guard in replaceKeyValues instead.
	keyValuePattern = regexp.MustCompile(`(?i)\b(uuid|password|passwd|secret|(?:access|refresh|session|id|auth|api)[_-]?token|token|private[_-]?key|pre[_-]?shared[_-]?key|obfs[_-]?password|obfs[_-]?param|api[_-]?key|auth(?:[_-]?str)?|secret[_-]?key|client[_-]?secret|psk|public[_-]?key|short[_-]?id|spider[_-]?x|username)\b([\"']?\s*[:=]\s*|\s+)("(?:\\.|[^"\\])*"[^\s,;}\]\)]*|'(?:\\.|[^'\\])*'[^\s,;}\]\)]*|\S+)`)
	// strictKeyValuePattern masks keys whose names are also ordinary
	// words only with an explicit assignment (":" or "="): a bare space
	// after "user" or "login" is usually prose ("user agent", "login
	// failed"), not a credential pair. The list carries the second ring
	// the loose pattern cannot hold: bare key/code/session (subscription
	// URL query parameters are exactly "?key=…&code=…"), hwid and
	// device/session ids (provider HWID limits), seed and encryption
	// (profile credentials), and the destination identifiers a censor
	// cares about — sni, server_name, dest, host, serviceName — which
	// are prose-safe only behind an explicit assignment.
	strictKeyValuePattern = regexp.MustCompile(`(?i)\b(user|login|key|code|session|seed|hwid|device[_-]?id|session[_-]?id|sni|server[_-]?name|servername|dest|encryption|service[_-]?name|servicename|host)\b([\"']?\s*[:=]\s*)("(?:\\.|[^"\\])*"[^\s,;}\]\)]*|'(?:\\.|[^'\\])*'[^\s,;}\]\)]*|\S+)`)
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
	authHeaderPattern = regexp.MustCompile(`(?i)\b(authorization\s*[:=]\s*(?:bearer|basic|token)\s+)(\S+)`)
	// subscriptionPathPattern masks the token segment of a subscription
	// URL: providers hand out https://host/sub/<token> (and feed/token/
	// link spellings) where the credential is a bare path segment with
	// no key name and no userinfo, so neither the key patterns nor the
	// userinfo pattern can see it. Only the segment after a
	// subscription-shaped path element is masked; ordinary URLs (rule
	// sets, documentation, engine downloads) keep readable paths.
	// Between host and the keyword segment, the conventional API
	// prefix is allowed — api and version segments in any combination
	// (https://host/api/v1/sub/<token>, /api/sub/<token>) — because
	// provider panels nest subscriptions exactly there. Arbitrary
	// nesting is deliberately NOT allowed: a keyword segment buried
	// under content segments (…/news/sub/<word>) is at least as
	// likely to be a documentation path as a credential, and masking
	// it would mangle ordinary URLs in logs.
	subscriptionPathPattern = regexp.MustCompile(`(?i)\b(https?://[^\s/]+/(?:(?:api|v[0-9]+)/)*(?:sub|subscribe|subscription|feed|token|link)/)[A-Za-z0-9._~%+/=-]{8,}`)
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
	"code", "session", "seed", "hwid", "device", "sni", "server", "dest",
	"encryption", "service", "host",
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
			if matchFoldAt(s, i, "session") || matchFoldAt(s, i, "seed") || matchFoldAt(s, i, "sni") ||
				matchFoldAt(s, i, "server") || matchFoldAt(s, i, "service") {
				f.strict = true
			}
		case 't':
			if matchFoldAt(s, i, "token") {
				f.key = true
			}
		case 'k':
			if matchFoldAt(s, i, "key") {
				f.key, f.strict = true, true
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
		case 'c':
			if matchFoldAt(s, i, "code") {
				f.strict = true
			}
		case 'h':
			if matchFoldAt(s, i, "hwid") || matchFoldAt(s, i, "host") {
				f.strict = true
			}
		case 'd':
			if matchFoldAt(s, i, "device") || matchFoldAt(s, i, "dest") {
				f.strict = true
			}
		case 'e':
			if matchFoldAt(s, i, "encryption") {
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

// replaceKeyValues applies one of the key-value patterns (groups:
// 1=key, 2=separator, 3=value), replacing the value with [masked]
// while preserving key and separator verbatim. A match whose value
// already starts with [masked] is copied through unchanged: it is a
// mask this pipeline (or an earlier redaction of the same log)
// already produced. Without the guard, the value's \S+ alternative
// re-consumes the mask plus any suffix the first pass deliberately
// preserved — a structural delimiter as in token: [masked], or a
// bracket as in token: [masked]] — and masking is not a fixed
// point. The guard is the second half of the idempotence fix: the
// quoted alternatives' glued-suffix tail (see keyValuePattern)
// consumes what belongs to the value, and the guard freezes what
// was already masked, so maskPatterns(maskPatterns(x)) ==
// maskPatterns(x) holds for the whole pipeline.
func replaceKeyValues(re *regexp.Regexp, s string) string {
	matches := re.FindAllStringSubmatchIndex(s, -1)
	if matches == nil {
		return s
	}
	var b strings.Builder
	b.Grow(len(s))
	last := 0
	for _, m := range matches {
		if m[6] < 0 {
			continue
		}
		b.WriteString(s[last:m[0]])
		if strings.HasPrefix(s[m[6]:m[7]], "[masked]") {
			b.WriteString(s[m[0]:m[1]])
		} else {
			b.WriteString(s[m[2]:m[3]])
			b.WriteString(s[m[4]:m[5]])
			b.WriteString("[masked]")
		}
		last = m[1]
	}
	b.WriteString(s[last:])
	return b.String()
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
		s = subscriptionPathPattern.ReplaceAllString(s, "${1}[masked]")
		s = authHeaderPattern.ReplaceAllString(s, "${1}[masked]")
		s = bearerPattern.ReplaceAllString(s, "${1}[masked]")
		s = replaceKeyValues(keyValuePattern, s)
		s = replaceKeyValues(strictKeyValuePattern, s)
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
		s = subscriptionPathPattern.ReplaceAllString(s, "${1}[masked]")
	}
	if f.bearer {
		s = authHeaderPattern.ReplaceAllString(s, "${1}[masked]")
		s = bearerPattern.ReplaceAllString(s, "${1}[masked]")
	}
	if f.key {
		s = replaceKeyValues(keyValuePattern, s)
	}
	if f.strict {
		s = replaceKeyValues(strictKeyValuePattern, s)
	}
	if f.uuid {
		s = uuidPattern.ReplaceAllString(s, "[masked]")
	}
	return s
}
