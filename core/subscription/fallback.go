package subscription

import (
	"net/url"
	"strings"

	"github.com/levvs-one/sora-client/core/errs"
)

// fallbackParam is the fragment parameter Happ 4.5.0 beta introduced
// ("Added support of 'fallback-url' in URL's fragment", Happ changelog,
// mirrored on APKMirror for 4.5.0 beta and 4.6.0): a subscription link
// may carry a reserve subscription URL in its fragment, in the form
//
//	https://panel.example/sub/token#fallback-url=https://backup.example/sub/token
//
// The fallback value may be percent-encoded as a whole or written raw;
// it is the last fragment parameter either way, so everything after the
// marker belongs to it (a raw fallback keeps its own query string,
// including '&' separators). A fragment is never sent to a server, so
// the fallback travels with the link without leaking to the primary
// provider, and the fetcher strips it before any request.
//
// No header-based form is confirmed in any public Happ or Remnawave
// source; only the fragment form above is supported.
const fallbackParam = "fallback-url"

// SplitFallback separates a subscription reference into its primary URL
// (fragment removed) and the fallback URL declared in the fragment, if
// any. A fragment without the marker (for example a plain display name)
// yields no fallback. A declared fallback is validated with the same
// rules as a primary reference: plain HTTP or embedded credentials are
// refused here, before any request is made, so a fallback can never
// smuggle the token onto a cleartext channel the primary rules reject.
func SplitFallback(reference string) (primary, fallback string, err error) {
	trimmed := strings.TrimSpace(reference)
	parsed, perr := url.Parse(trimmed)
	if perr != nil {
		return "", "", errs.Newf(errs.CodeInvalidArgument, errs.KeySubscriptionScheme,
			"subscription: the reference is not a url")
	}
	frag := parsed.Fragment
	marker := fallbackParam + "="
	// The marker counts only as a fragment parameter of its own: at
	// the very start of the fragment or immediately after '&'. The
	// same text inside another parameter's value ("#name=fallback-
	// url=https://…") is that parameter's data, not a declaration.
	idx := -1
	for from := 0; ; {
		found := strings.Index(frag[from:], marker)
		if found < 0 {
			break
		}
		cand := from + found
		if cand == 0 || frag[cand-1] == '&' {
			idx = cand
			break
		}
		from = cand + 1
	}
	if idx < 0 {
		primary = trimmed
		if frag != "" {
			// A fragment is never sent to the server; drop it so the
			// stored and fetched forms agree with each other.
			parsed.Fragment, parsed.RawFragment = "", ""
			primary = parsed.String()
		}
		return primary, "", nil
	}
	raw := strings.TrimSpace(frag[idx+len(marker):])
	// The fallback's own fragment, if one was written raw, is not part
	// of the fallback reference.
	if cut := strings.IndexByte(raw, '#'); cut >= 0 {
		raw = raw[:cut]
	}
	parsed.Fragment, parsed.RawFragment = "", ""
	primary = parsed.String()
	if raw == "" {
		return primary, "", nil
	}
	validated, verr := ValidateReference(raw)
	if verr != nil {
		return "", "", verr
	}
	validated.Fragment, validated.RawFragment = "", ""
	return primary, validated.String(), nil
}

// JoinFallback renders a primary reference plus its fallback as the
// single link users paste and share: the fallback rides in the
// fragment, percent-encoded so its own query string survives intact.
// SplitFallback reads the result back.
func JoinFallback(primary, fallback string) string {
	if strings.TrimSpace(fallback) == "" {
		return primary
	}
	return primary + "#" + fallbackParam + "=" + url.QueryEscape(fallback)
}
