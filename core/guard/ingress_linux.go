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

// arm installs the table, replacing any stale copy in a single nft
// transaction: the delete and the new table commit atomically, so a repeated
// Arm or a crash can never leave a window with the ingress table absent (the
// same guarantee Nftables.Arm gives the kill switch). A batch whose table
// does not exist aborts, so the first install falls back to the table alone.
func (b *nftablesIngressBackend) arm(ctx context.Context) error {
	replace, err := NftIngressReplace(b.cfg, b.nft.bypass)
	if err != nil {
		return err
	}
	if err := b.nft.apply(ctx, replace); err != nil {
		if !isMissingTable(err) {
			return err
		}
		ruleset, err := NftIngressRuleset(b.cfg, b.nft.bypass)
		if err != nil {
			return err
		}
		return b.nft.apply(ctx, ruleset)
	}
	return nil
}

// disarm removes the owned table, treating a missing table as success so
// repeated restores and crash recovery are safe (SORA-M5 pattern).
func (b *nftablesIngressBackend) disarm(ctx context.Context) error {
	if err := b.nft.apply(ctx, NftIngressRemove()); err != nil && !isMissingTable(err) {
		return err
	}
	return nil
}
