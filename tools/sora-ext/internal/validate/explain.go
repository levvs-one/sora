package validate

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"os"
	"strings"
)

// pos is a byte offset into the manifest source.
type pos struct {
	off int
}

// indexPositions decodes data as a JSON token stream and maps every object
// key and every string array element to its byte offset, so errors that
// name a field can point at the source. Paths look like "author.public_key",
// "permissions[2]", "ui.panels[0].entry".
//
// The decoder is strict about structure but lenient about values: only
// delimiters and strings matter here. Offsets assume plain (unescaped) keys
// and values, which holds for every machine-generated manifest.
func indexPositions(data []byte) map[string]pos {
	out := map[string]pos{}
	dec := json.NewDecoder(bytes.NewReader(data))

	// A frame is one open container. For objects, key is the pending key
	// ("" means the next string token is a key); for arrays, idx is the
	// next element index. arrayElem marks a container that is itself an
	// array element (its "[i]" segment is popped on close).
	type frame struct {
		isArray   bool
		key       string
		idx       int
		arrayElem bool
	}
	var stack []frame
	var path []string
	// join renders the path: "[i]" segments attach without a dot.
	join := func() string {
		var b strings.Builder
		for _, s := range path {
			if strings.HasPrefix(s, "[") {
				b.WriteString(s)
			} else {
				if b.Len() > 0 {
					b.WriteString(".")
				}
				b.WriteString(s)
			}
		}
		return b.String()
	}

	// consumeValue runs after a complete value (scalar or closed
	// container): it pops a pending object key or advances an array index.
	consumeValue := func() {
		if len(stack) == 0 {
			return
		}
		top := &stack[len(stack)-1]
		if top.isArray {
			top.idx++
		} else if top.key != "" {
			top.key = ""
			path = path[:len(path)-1]
		}
	}

	for {
		tok, err := dec.Token()
		if err != nil {
			break // io.EOF, or a syntax error: keep what we have
		}
		off := int(dec.InputOffset())
		// startOf backs up from "just past the closing quote" to the
		// opening quote of a string token.
		startOf := func(s string) int {
			if s := off - len(s) - 2; s >= 0 {
				return s
			}
			return 0
		}
		switch t := tok.(type) {
		case json.Delim:
			switch t {
			case '{', '[':
				if len(stack) > 0 && stack[len(stack)-1].isArray {
					// An object/array that is an array element: the index
					// becomes part of the path ("ui.panels[0]").
					top := &stack[len(stack)-1]
					path = append(path, fmt.Sprintf("[%d]", top.idx))
					stack = append(stack, frame{isArray: t == '[', arrayElem: true})
				} else {
					stack = append(stack, frame{isArray: t == '['})
				}
			case '}', ']':
				fr := stack[len(stack)-1]
				stack = stack[:len(stack)-1]
				if fr.arrayElem {
					path = path[:len(path)-1] // pop "[i]"
				}
				consumeValue()
			}
		case string:
			if len(stack) > 0 && !stack[len(stack)-1].isArray && stack[len(stack)-1].key == "" {
				// Object key.
				seg := t
				if len(path) > 0 {
					seg = join() + "." + t
				}
				out[seg] = pos{off: startOf(t)}
				path = append(path, t)
				stack[len(stack)-1].key = t
			} else {
				// String value.
				if len(stack) > 0 && stack[len(stack)-1].isArray {
					top := &stack[len(stack)-1]
					out[fmt.Sprintf("%s[%d]", join(), top.idx)] = pos{off: startOf(t)}
				} else if len(stack) > 0 && stack[len(stack)-1].key != "" {
					// Scalar value of an object key: remember the value
					// offset too, so errors about the value (bad id,
					// bad semver) point at the value, not the key.
					out[join()+"#value"] = pos{off: startOf(t)}
				}
				consumeValue()
			}
		default:
			// number, bool, nil: a complete scalar value.
			consumeValue()
		}
	}
	return out
}

// explain turns a core/ext error into an Issue with position, suggestion and
// fix hints. The path resolution is driven by the error code (known message
// shapes from core/ext), not by guessing from the text.
func explain(data []byte, positions map[string]pos, err error) Issue {
	msg := cleanMessage(err.Error())
	code := classify(msg)
	is := Issue{Code: code, Message: msg}
	quoted := quotedStrings(msg)
	token := ""
	if len(quoted) > 0 {
		token = quoted[0]
	}

	path := ""
	switch code {
	case "unknown-field":
		// The unknown key is still indexed by position.
		path = token
	case "unknown-permission", "duplicate-permission":
		path = arrayElement(data, positions, "permissions", token)
	case "unknown-capability":
		path = arrayElement(data, positions, "capabilities", token)
	case "bad-id":
		path = "id"
	case "bad-semver":
		path = "version"
		if strings.Contains(msg, "min_app_version") {
			path = "min_app_version"
		}
	case "bad-public-key":
		path = "author.public_key"
	case "unsafe-entry":
		// panel "<id>" has an unsafe entry "<entry>": find the panel.
		if len(quoted) >= 2 {
			token = quoted[1]
			path = panelEntryPath(data, positions, quoted[0])
		}
	case "missing-capability-permission":
		path = wordField(msg, "background_task", "network_hosts", "theme", "network_hook", "routing")
	case "bad-json":
		// Recover the syntax error offset directly.
		var tmp any
		if jerr := json.Unmarshal(data, &tmp); jerr != nil {
			if se, ok := jerr.(*json.SyntaxError); ok {
				line, col, snippet := lineCol(data, int(se.Offset))
				is.Line, is.Col, is.Snippet = line, col, snippet
				is.Token = ""
			}
		}
	}
	if path != "" {
		if p, ok := positions[path]; ok {
			// Prefer the value offset for errors about a value; the key
			// offset for unknown fields (the key itself is wrong).
			if code != "unknown-field" {
				if pv, ok := positions[path+"#value"]; ok {
					p = pv
				}
			}
			line, col, snippet := lineCol(data, p.off)
			is.Line, is.Col, is.Snippet = line, col, snippet
		}
	}
	is.Token = token
	is.Suggestion = suggest(code, token, quoted)
	is.Help = helpFor(code, token)
	return is
}

// panelEntryPath finds "ui.panels[i].entry" for the panel with the given
// id, by decoding just the panel list.
func panelEntryPath(data []byte, positions map[string]pos, panelID string) string {
	var doc struct {
		UI struct {
			Panels []struct {
				ID string `json:"id"`
			} `json:"panels"`
		} `json:"ui"`
	}
	if err := json.Unmarshal(data, &doc); err != nil {
		return ""
	}
	for i, p := range doc.UI.Panels {
		if p.ID == panelID {
			return fmt.Sprintf("ui.panels[%d].entry", i)
		}
	}
	return ""
}

// wordField finds the first of fields mentioned as a whole word in msg.
func wordField(msg string, fields ...string) string {
	words := strings.FieldsFunc(msg, func(r rune) bool {
		return !(r == '_' || r == '-' ||
			r >= 'a' && r <= 'z' || r >= 'A' && r <= 'Z' || r >= '0' && r <= '9')
	})
	set := map[string]bool{}
	for _, w := range words {
		set[w] = true
	}
	for _, f := range fields {
		if set[f] {
			return f
		}
	}
	return ""
}

// arrayElement finds "arr[i]" in positions whose source text is exactly
// the quoted token, e.g. permissions[2] for `"net.fech"`.
func arrayElement(data []byte, positions map[string]pos, arr, token string) string {
	if positions == nil {
		return ""
	}
	want := `"` + token + `"`
	for i := 0; ; i++ {
		p := fmt.Sprintf("%s[%d]", arr, i)
		pp, ok := positions[p]
		if !ok {
			return ""
		}
		if pp.off+len(want) <= len(data) && string(data[pp.off:pp.off+len(want)]) == want {
			return p
		}
	}
}

// lineCol converts a byte offset into 1-based line/col plus the line text.
func lineCol(data []byte, off int) (int, int, string) {
	if data == nil || off < 0 || off > len(data) {
		return 0, 0, ""
	}
	line, col := 1, 1
	for i := 0; i < off; i++ {
		if data[i] == '\n' {
			line++
			col = 1
		} else {
			col++
		}
	}
	start := off
	for start > 0 && data[start-1] != '\n' {
		start--
	}
	end := off
	for end < len(data) && data[end] != '\n' {
		end++
	}
	return line, col, string(data[start:end])
}

func quotedStrings(s string) []string {
	var out []string
	for {
		i := strings.Index(s, `"`)
		if i < 0 {
			break
		}
		s = s[i+1:]
		j := strings.Index(s, `"`)
		if j < 0 {
			break
		}
		out = append(out, s[:j])
		s = s[j+1:]
	}
	return out
}

// cleanMessage strips the errs envelope ("<code> <key>: ") and the "ext: "
// prefix core/ext puts on its messages, leaving the human sentence.
func cleanMessage(s string) string {
	if i := strings.Index(s, ": "); i >= 0 {
		rest := s[i+2:]
		if strings.HasPrefix(rest, "ext: ") {
			return strings.TrimSpace(strings.TrimPrefix(rest, "ext: "))
		}
		// Non-ext errors (zip, io): keep the text after the envelope.
		return strings.TrimSpace(rest)
	}
	return strings.TrimSpace(strings.TrimPrefix(s, "ext: "))
}

// classify maps a message to a short error code.
func classify(msg string) string {
	switch {
	case strings.Contains(msg, "unknown permission"):
		return "unknown-permission"
	case strings.Contains(msg, "duplicate permission"):
		return "duplicate-permission"
	case strings.Contains(msg, "unknown capability"):
		return "unknown-capability"
	case strings.Contains(msg, "unknown field"):
		return "unknown-field"
	case strings.Contains(msg, "must be semver"):
		return "bad-semver"
	case strings.Contains(msg, "reverse-DNS"):
		return "bad-id"
	case strings.Contains(msg, "requires the"):
		return "missing-capability-permission"
	case strings.Contains(msg, "unsafe entry"):
		return "unsafe-entry"
	case strings.Contains(msg, "not valid JSON"):
		return "bad-json"
	case strings.Contains(msg, "public key"):
		return "bad-public-key"
	case strings.Contains(msg, "was modified"), strings.Contains(msg, "does not match"):
		return "integrity"
	case strings.Contains(msg, "not a zip"), strings.Contains(msg, "unsafe path"):
		return "bad-package"
	default:
		return "invalid"
	}
}

var permissionVocab = []string{
	"connections.read", "servers.read", "settings.read", "settings.write",
	"notifications", "tray", "ui.panel", "theme.apply", "routing.rules",
	"net.hooks", "net.fetch", "background",
}

var capabilityVocab = []string{
	"theme", "network-hook", "routing", "ui-panel", "background", "widget",
}

var topLevelVocab = []string{
	"manifest_version", "id", "name", "version", "min_app_version",
	"description", "author", "permissions", "capabilities", "ui",
	"settings_schema", "background_task", "network_hosts",
	"theme", "network_hook", "routing",
}

// suggest returns a did-you-mean candidate for the token, or "".
func suggest(code, token string, quoted []string) string {
	var vocab []string
	switch code {
	case "unknown-permission":
		vocab = permissionVocab
	case "unknown-capability":
		vocab = capabilityVocab
	case "unknown-field":
		vocab = topLevelVocab
		if token == "" && len(quoted) > 0 {
			token = quoted[0]
		}
	default:
		return ""
	}
	if token == "" {
		return ""
	}
	best, bestDist := "", 3
	for _, w := range vocab {
		if d := levenshtein(token, w); d < bestDist {
			best, bestDist = w, d
		}
	}
	return best
}

func levenshtein(a, b string) int {
	la, lb := len(a), len(b)
	prev := make([]int, lb+1)
	for j := range prev {
		prev[j] = j
	}
	for i := 1; i <= la; i++ {
		cur := make([]int, lb+1)
		cur[0] = i
		for j := 1; j <= lb; j++ {
			cost := 0
			if a[i-1] != b[j-1] {
				cost = 1
			}
			cur[j] = min(prev[j]+1, cur[j-1]+1, prev[j-1]+cost)
		}
		prev = cur
	}
	return prev[lb]
}

// helpFor returns fix hints for an error code.
func helpFor(code, token string) []string {
	switch code {
	case "unknown-permission":
		return []string{
			"permissions must come from the v1 registry (docs/extensions.md §3):",
			"  " + strings.Join(permissionVocab, ", "),
			"request only what the extension needs — dangerous ones prompt for confirmation",
		}
	case "duplicate-permission":
		return []string{"list each permission once"}
	case "unknown-capability":
		return []string{
			"capabilities are one of: " + strings.Join(capabilityVocab, ", "),
			"the permission list is what actually gates access",
		}
	case "unknown-field":
		return []string{
			"the manifest schema is closed: unknown fields are rejected",
			"known top-level fields: " + strings.Join(topLevelVocab, ", "),
		}
	case "bad-semver":
		return []string{"use MAJOR.MINOR.PATCH, e.g. \"1.2.0\" (no leading \"v\")"}
	case "bad-id":
		return []string{"use reverse-DNS with at least two labels, e.g. \"com.example.stats\""}
	case "missing-capability-permission":
		return []string{"declare the matching capability and permission together (see the manifest template)"}
	case "unsafe-entry":
		return []string{"use a relative path inside the package, e.g. \"panel.html\" (no \"..\", no leading \"/\")"}
	case "bad-json":
		return []string{"fix the JSON syntax first — nothing else can be checked until it parses"}
	case "bad-public-key":
		return []string{
			"paste the base64 line from your .pub file (sora-ext keygen prints it)",
			"for catalog installs the catalog pins the expected key",
		}
	case "integrity":
		return []string{
			"the package was modified after signing: run sora-ext pack and sora-ext sign again",
			"never hand-edit files inside a signed .soraext",
		}
	default:
		return nil
	}
}

// parseChecksumsList parses "sha256hex  path" lines.
func parseChecksumsList(text string) map[string]string {
	out := map[string]string{}
	for _, line := range strings.Split(strings.ReplaceAll(strings.TrimSpace(text), "\r\n", "\n"), "\n") {
		if strings.TrimSpace(line) == "" {
			continue
		}
		parts := strings.SplitN(line, "  ", 2)
		if len(parts) != 2 {
			parts = strings.Fields(line)
			if len(parts) != 2 {
				continue
			}
		}
		out[parts[1]] = parts[0]
	}
	return out
}

func sha256HexOfFile(path string) string {
	data, err := os.ReadFile(path)
	if err != nil {
		return ""
	}
	sum := sha256.Sum256(data)
	return hex.EncodeToString(sum[:])
}
