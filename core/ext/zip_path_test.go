package ext

import "testing"

// TestArchivePathHardening: backslashes and colons are never legitimate in
// a .soraext path, and on the Windows extractor they are separators
// ("..\\..\\evil", "C:\\evil") or ADS ("panel.html:evil").
func TestArchivePathHardening(t *testing.T) {
	for _, bad := range []string{
		`..\evil.html`,
		`..\\..\\evil.html`,
		`C:\evil.html`,
		`assets\panel.html`,
		`panel.html:evil`,
		`a:b/c.html`,
		`\\server\share.html`,
	} {
		if isSafeArchivePath(bad) {
			t.Errorf("isSafeArchivePath(%q) = true, want false", bad)
		}
	}
	for _, good := range []string{
		"panel.html",
		"assets/panel.html",
		"./panel.html",
		"sora-extension.json",
		"checksums.txt",
	} {
		if !isSafeArchivePath(good) {
			t.Errorf("isSafeArchivePath(%q) = false, want true", good)
		}
	}
}
