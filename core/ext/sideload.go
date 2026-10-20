package ext

// Sideload consent: the facts the install prompt must show before the user
// accepts a package that did not come from the team catalog.
//
// A sideloaded .soraext is verified against the author's own key from the
// manifest - self-attested. The signature proves the bytes were not modified
// after the author signed them; it says nothing about whether the author is
// trustworthy, and anyone can mint a self-attested signature in a minute.
// The consent screen must make that unmistakable, show exactly who claims
// authorship (name, identity, key fingerprint), and list every permission
// with its risk. "Trust this author" must be a deliberate, informed tap -
// never a pre-checked box or a one-line "unknown source" shrug.
//
// This file builds the facts; the app renders them (see the sideload spec in
// the security report). Call SideloadConsent only after pkg.Verify()
// succeeded - facts about an unverified package are theater.

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"strings"

	"github.com/levvs-one/sora-client/core/errs"
)

// riskConsequence is the concrete, non-technical consequence shown for a
// permission on the consent screen. It must stay blunt: the user is deciding
// whether to hand a stranger these capabilities.
var riskConsequence = map[string]string{
	"connections.read": "see which apps you use and which sites they contact",
	"servers.read":     "see your server list",
	"settings.read":    "read the app's settings",
	"settings.write":   "change the app's settings",
	"notifications":    "show notifications as if from the app",
	"tray":             "add entries to the tray menu",
	"ui.panel":         "embed its own panels inside the app",
	"theme.apply":      "restyle the app's interface",
	"routing.rules":    "redirect your traffic - including banking and mail - through servers it chooses",
	"net.hooks":        "inspect and reshape your network traffic (DPI-bypass modules run at this level)",
	"net.fetch":        "contact servers on the internet from your device",
	"background":       "run code periodically even when you are not using the extension",
}

// PermissionFact is one permission rendered for the consent screen.
type PermissionFact struct {
	ID          string
	Risk        Risk
	Consequence string
}

// ConsentFacts is everything the sideload prompt must show.
type ConsentFacts struct {
	ID          string
	Name        string
	Version     string
	AuthorName  string
	AuthorID    string // verifiable identity, e.g. "github:janedoe"
	KeyID       string // minisign key id, hex
	Fingerprint string // SHA-256 of the author pubkey, grouped hex
	// SelfAttested is always true for sideloads: the signature is the
	// author's own, not pinned by the catalog.
	SelfAttested bool
	Permissions  []PermissionFact
	// Risks are the blunt bullets for the warning block, most severe first.
	Risks []string
}

// AuthorKeyFingerprint parses a minisign public key line and returns the
// key id (16 hex chars) and the SHA-256 fingerprint of the 32-byte public
// key, grouped as "AB12:CD34:..." for read-aloud comparison.
func AuthorKeyFingerprint(pubKeyLine string) (keyID, fingerprint string, err error) {
	id, pub, err := ParsePublicKey(pubKeyLine)
	if err != nil {
		return "", "", err
	}
	sum := sha256.Sum256(pub[:])
	hexSum := strings.ToUpper(hex.EncodeToString(sum[:]))
	groups := make([]string, 0, 16)
	for i := 0; i < len(hexSum); i += 4 {
		groups = append(groups, hexSum[i:i+4])
	}
	return strings.ToUpper(hex.EncodeToString(id[:])), strings.Join(groups, ":"), nil
}

// SideloadConsent builds the consent facts for a verified package's
// manifest. Dangerous permissions sort first; within a risk level the
// manifest order is kept.
func SideloadConsent(m *Manifest) (*ConsentFacts, error) {
	if m == nil {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyPackageInvalid, "ext: no manifest")
	}
	keyID, fp, err := AuthorKeyFingerprint(m.Author.PublicKey)
	if err != nil {
		return nil, errs.Newf(errs.CodeInvalidArgument, KeyManifestInvalid,
			"ext: cannot fingerprint the author key: %v", err)
	}
	facts := &ConsentFacts{
		ID:           m.ID,
		Name:         m.Name,
		Version:      m.Version,
		AuthorName:   m.Author.Name,
		AuthorID:     m.Author.Identity,
		KeyID:        keyID,
		Fingerprint:  fp,
		SelfAttested: true,
		Risks: []string{
			"Not from the Sora catalog - nobody reviewed this code.",
			"The signature is self-attested: it proves the file was not changed after signing, but anyone can create such a signature. It does not prove the author is who they claim to be.",
			fmt.Sprintf("Only continue if you trust %s (%s) and the key fingerprint above matches the key they publish.", m.Author.Name, m.Author.Identity),
		},
	}
	// Dangerous first, then sensitive, then normal.
	for _, risk := range []Risk{RiskDangerous, RiskSensitive, RiskNormal} {
		for _, p := range m.Permissions {
			perm, ok := LookupPermission(p)
			if !ok || perm.Risk != risk {
				continue
			}
			conseq, ok := riskConsequence[p]
			if !ok {
				conseq = "use the " + p + " capability"
			}
			facts.Permissions = append(facts.Permissions, PermissionFact{ID: p, Risk: risk, Consequence: conseq})
			if risk == RiskDangerous {
				facts.Risks = append(facts.Risks, "Dangerous permission "+p+": the extension will be able to "+conseq+".")
			}
		}
	}
	return facts, nil
}
