// Package mock exposes the window.soraExt browser mock for embedding.
package mock

import _ "embed"

// JS is the mock script injected by `sora-ext serve`. Never shipped in a
// .soraext: it is a development/testing aid only.
//
//go:embed sora-ext-mock.js
var JS []byte
