//go:build linux

package guard

import (
	"context"

	"github.com/levvs-one/sora-client/core/errs"
)

// nftablesIngressBackend installs the ingress ruleset into the owned
// sora_ingress table using the nft binary resolved by Nftables. Same
// package access is deliberate: the backend reuses the trusted binary
// path and the apply helper instead of resolving or executing anything
// on its own.
type nftablesIngressBackend struct {
	nft *Nftables
	cfg IngressConfig
}

func newIngressBackend(inner Firewall, cfg IngressConfig) (ingressBackend, error) {
	if _, ok := inner.(NoopFirewall); ok {
		// No process-managed firewall on this platform: nothing to
		// install, nothing to remove.
		return nil, nil
	}
	nft, ok := inner.(*Nftables)
	if !ok {
		return nil, errs.Newf(errs.CodeFailedPrecondition, errs.KeyGuardFirewallFail,
			"guard: ingress protection needs the nftables firewall, got %T", inner)
	}
	return &nftablesIngressBackend{nft: nft, cfg: cfg}, nil
}

// arm replaces the owned table, mirroring the idempotent delete-then-apply
// of Nftables.Arm so a repeated Arm or a stale table from a crash never
// fails with "File exists" (SORA-M4 pattern).
func (b *nftablesIngressBackend) arm(ctx context.Context) error {
	ruleset, err := NftIngressRuleset(b.cfg, b.nft.bypass)
	if err != nil {
		return err
	}
	if err := b.nft.apply(ctx, NftIngressRemove()); err != nil && !isMissingTable(err) {
		return err
	}
	return b.nft.apply(ctx, ruleset)
}

// disarm removes the owned table, treating a missing table as success so
// repeated restores and crash recovery are safe (SORA-M5 pattern).
func (b *nftablesIngressBackend) disarm(ctx context.Context) error {
	if err := b.nft.apply(ctx, NftIngressRemove()); err != nil && !isMissingTable(err) {
		return err
	}
	return nil
}
