// Package templates exposes the scaffold templates for embedding.
package templates

import "embed"

// FS holds all scaffold templates: panel, theme, nethook, routing,
// background, plus shared/sora-ext.d.ts.
//
//go:embed all:panel all:theme all:nethook all:routing all:background all:shared
var FS embed.FS
