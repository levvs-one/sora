package engine

// IsVPNTarget excludes serverless routes and ambiguous provider routing.
// Checking all group members prevents a later selector move or automatic
// fallback from turning an existing extension listener into a direct proxy.
func (p *Plan) IsVPNTarget(target string) bool {
	if p == nil {
		return false
	}
	visiting := map[string]bool{}
	var check func(string) bool
	check = func(id string) bool {
		if id == "" || IsBuiltInTarget(id) || visiting[id] {
			return false
		}
		visiting[id] = true
		defer delete(visiting, id)
		if o, ok := p.OutboundByID(id); ok {
			if !validProtocols[o.Protocol] || o.Protocol == ProtocolDirect || o.Protocol == ProtocolBypass || o.Protocol == ProtocolXrayProfile {
				return false
			}
			return o.Via == "" || check(o.Via)
		}
		for _, g := range p.Groups {
			if g.Name != id {
				continue
			}
			if len(g.Outbounds) == 0 {
				return false
			}
			for _, member := range g.Outbounds {
				if !check(member) {
					return false
				}
			}
			return true
		}
		return false
	}
	return check(target)
}
