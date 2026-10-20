package control

// User overrides on top of subscriptions. Overrides re-apply after every
// refresh so renames, hidden servers and pinned order survive provider
// updates. A corrupt override file is logged and ignored: the update must
// never fail because of user edits.

import (
	"context"
	"errors"

	"google.golang.org/protobuf/proto"

	"github.com/levvs-one/sora-client/core/errs"
	corev1 "github.com/levvs-one/sora-client/core/gen/sora/core/v1"
	"github.com/levvs-one/sora-client/core/logs"
	"github.com/levvs-one/sora-client/core/subscription"
)

// applySubscriptionOverride returns the specs with the override applied:
// hidden servers removed, renames set as display names, pinned servers
// first (stable: the rest keeps relative order). Nil override is a no-op.
func applySubscriptionOverride(specs []*corev1.OutboundSpec, o *subscription.Override) []*corev1.OutboundSpec {
	if o == nil {
		return specs
	}
	// An override with nothing in it (the common case: most subscriptions
	// carry no user edits, and a missing override file loads as an empty
	// override) changes nothing, so the shared list goes back as is
	// instead of paying a per-state copy of every spec pointer plus an
	// empty hidden map: stateLocked builds a state on every refresh,
	// save and watch broadcast. Callers treat the result as read-only —
	// withCustomOutbounds copies again before appending custom servers.
	if len(o.Hidden) == 0 && len(o.Renames) == 0 && len(o.PinnedOrder) == 0 {
		return specs
	}
	hidden := make(map[string]bool, len(o.Hidden))
	for _, id := range o.Hidden {
		hidden[id] = true
	}
	// Copy: the input slice is shared with the stored list, filtering must
	// not rewrite its backing array.
	kept := make([]*corev1.OutboundSpec, 0, len(specs))
	for _, spec := range specs {
		id := spec.GetId()
		if hidden[id] {
			continue
		}
		if name, ok := o.Renames[id]; ok && name != "" {
			// Clone before renaming: the stored spec keeps the provider
			// name so clearing the rename restores it.
			c, ok := proto.Clone(spec).(*corev1.OutboundSpec)
			if !ok {
				continue
			}
			c.DisplayName = name
			spec = c
		}
		kept = append(kept, spec)
	}
	if len(o.PinnedOrder) == 0 {
		return kept
	}
	pinned := map[string]bool{}
	for _, id := range o.PinnedOrder {
		pinned[id] = true
	}
	out := make([]*corev1.OutboundSpec, 0, len(kept))
	for _, id := range o.PinnedOrder {
		for _, spec := range kept {
			if spec.GetId() == id {
				out = append(out, spec)
				break
			}
		}
	}
	for _, spec := range kept {
		if !pinned[spec.GetId()] {
			out = append(out, spec)
		}
	}
	return out
}

// get returns the record for id, or nil when unknown.
func (b *subscriptionBook) get(id string) *subscriptionRecord {
	b.mu.Lock()
	defer b.mu.Unlock()
	return b.records[id]
}

// state returns the UI-facing state with overrides applied, or nil when the
// subscription is unknown.
func (b *subscriptionBook) state(id string) *corev1.SubscriptionState {
	b.mu.Lock()
	defer b.mu.Unlock()
	if _, ok := b.records[id]; !ok {
		return nil
	}
	return b.stateLocked(id)
}
// loadOverride returns the stored override for id, logging corruption and
// continuing with an empty override.
func (b *subscriptionBook) loadOverride(id string) *subscription.Override {
	if b.overrides == nil {
		return &subscription.Override{}
	}
	o, err := b.overrides.Load(id)
	if err != nil {
		if errors.Is(err, subscription.ErrOverrideCorrupt) && b.srv.logs != nil {
			b.srv.logs.Write(b.now(), logs.LevelWarning, logs.SourceSubscription,
				"subscription overrides ignored: file is corrupt id="+id)
		}
		return &subscription.Override{}
	}
	return o
}

// SaveSubscriptionOverride stores user edits on top of a subscription.
func (s *Server) SaveSubscriptionOverride(ctx context.Context, req *corev1.SaveSubscriptionOverrideRequest) (*corev1.SaveSubscriptionOverrideResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	id := req.GetSubscriptionId()
	if s.subs.get(id) == nil {
		err := errs.Newf(errs.CodeNotFound, errs.KeySubscriptionNotFound,
			"control: no subscription %s", id)
		return &corev1.SaveSubscriptionOverrideResponse{Error: toWire(err, nil, "")}, nil
	}
	if s.subs.overrides == nil {
		err := errs.Newf(errs.CodeFailedPrecondition, errs.KeySubscriptionStatus,
			"control: subscription overrides are not configured")
		return &corev1.SaveSubscriptionOverrideResponse{Error: toWire(err, nil, "")}, nil
	}
	o := &subscription.Override{
		Renames:     req.GetRenames(),
		PinnedOrder: req.GetPinnedOrder(),
	}
	for _, h := range req.GetHidden() {
		o.Hidden = append(o.Hidden, h)
	}
	// Extra rules ride the same file; the client merges them into the
	// session plan it builds. This request carries no extra_rules field,
	// so preserve whatever is already stored instead of wiping it.
	// The provider routing layer (C3) rides the same file too and is
	// owned by refreshes, so a user save must preserve it as well.
	if !req.GetClear() {
		if existing, err := s.subs.overrides.Load(id); err == nil && existing != nil {
			o.ExtraRules = existing.ExtraRules
			o.ProviderRouting = existing.ProviderRouting
		}
	}
	if req.GetClear() {
		// Clear wipes the user's edits, not the provider layer: the
		// provider's rules are not the user's to clear, and the next
		// refresh would restore them anyway — keeping them avoids a
		// window where the subscription runs without them.
		o = &subscription.Override{ProviderRouting: o.ProviderRouting}
		if existing, err := s.subs.overrides.Load(id); err == nil && existing != nil {
			o.ProviderRouting = existing.ProviderRouting
		}
	}
	if err := s.subs.overrides.Save(id, o); err != nil {
		cerr := errs.Wrap(err, errs.CodeInternal, errs.KeySecretStoreUnavailable)
		return &corev1.SaveSubscriptionOverrideResponse{Error: toWire(cerr, nil, "")}, nil
	}
	return &corev1.SaveSubscriptionOverrideResponse{State: s.subs.state(id)}, nil
}

// GetSubscriptionOverride returns the stored user edits for a subscription.
func (s *Server) GetSubscriptionOverride(ctx context.Context, req *corev1.GetSubscriptionOverrideRequest) (*corev1.GetSubscriptionOverrideResponse, error) {
	if err := s.authorize(req.GetApiVersion(), req.GetControlAuthenticator()); err != nil {
		return nil, err
	}
	id := req.GetSubscriptionId()
	if s.subs.get(id) == nil {
		err := errs.Newf(errs.CodeNotFound, errs.KeySubscriptionNotFound,
			"control: no subscription %s", id)
		return &corev1.GetSubscriptionOverrideResponse{Error: toWire(err, nil, "")}, nil
	}
	o := s.subs.loadOverride(id)
	out := &corev1.GetSubscriptionOverrideResponse{
		Renames:     o.Renames,
		Hidden:      o.Hidden,
		PinnedOrder: o.PinnedOrder,
	}
	for _, r := range o.ExtraRules {
		out.ExtraRules = append(out.ExtraRules, &corev1.OverrideRule{
			Destination: r.Destination,
			OutboundId:  r.OutboundID,
		})
	}
	return out, nil
}
