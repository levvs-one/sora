package xray

import (
	"encoding/json"
	"errors"
	"strings"
)

// Xray's routing StringList accepts arrays or a comma-separated string. DNS
// server domains use a strict array; retaining that distinction avoids treating
// commas inside an array's regular expression as separate asset references.
type profileAssetList []string

func (list *profileAssetList) UnmarshalJSON(raw []byte) error {
	var values []string
	if err := json.Unmarshal(raw, &values); err == nil {
		*list = values
		return nil
	}
	var value string
	if err := json.Unmarshal(raw, &value); err != nil {
		return err
	}
	*list = strings.Split(value, ",")
	return nil
}

// Validate the final serialized view so field aliases and duplicate spellings
// resolve exactly as they will in the engine, after Sora replaces owned fields.
func validateProfileAssets(raw []byte) error {
	var cfg struct {
		Routing *struct {
			Rules []json.RawMessage
		}
		DNS *struct {
			Hosts   json.RawMessage
			Servers []json.RawMessage
		}
	}
	if err := json.Unmarshal(raw, &cfg); err != nil {
		return err
	}
	if cfg.Routing != nil {
		for _, raw := range cfg.Routing.Rules {
			var rule struct {
				Domain, Domains, IP, SourceIP, Source, LocalIP profileAssetList
			}
			if err := json.Unmarshal(raw, &rule); err != nil {
				return err
			}
			for _, list := range []profileAssetList{rule.Domain, rule.Domains} {
				if err := checkProfileAssetRefs(list, "ext:", "ext-domain:"); err != nil {
					return err
				}
			}
			source := rule.SourceIP
			if source == nil {
				source = rule.Source
			}
			for _, list := range []profileAssetList{rule.IP, source, rule.LocalIP} {
				if err := checkProfileAssetRefs(list, "ext:", "ext-ip:"); err != nil {
					return err
				}
			}
		}
	}
	if cfg.DNS == nil {
		return nil
	}
	var hosts map[string]json.RawMessage
	if len(cfg.DNS.Hosts) != 0 {
		if err := json.Unmarshal(cfg.DNS.Hosts, &hosts); err != nil {
			return err
		}
	}
	for reference := range hosts {
		if err := checkProfileAssetRefs([]string{reference}, "ext:"); err != nil {
			return err
		}
	}
	for _, raw := range cfg.DNS.Servers {
		var address string
		if json.Unmarshal(raw, &address) == nil {
			continue
		}
		var server struct {
			Domains                               []string
			ExpectedIPs, ExpectIPs, UnexpectedIPs profileAssetList
		}
		if err := json.Unmarshal(raw, &server); err != nil {
			return err
		}
		if err := checkProfileAssetRefs(server.Domains, "ext:", "ext-domain:"); err != nil {
			return err
		}
		expected := server.ExpectedIPs
		if len(expected) == 0 {
			expected = server.ExpectIPs
		}
		for _, list := range []profileAssetList{expected, server.UnexpectedIPs} {
			if err := checkProfileAssetRefs(list, "ext:", "ext-ip:"); err != nil {
				return err
			}
		}
	}
	return nil
}

func checkProfileAssetRefs(list []string, prefixes ...string) error {
	for _, reference := range list {
		for _, prefix := range prefixes {
			resource, external := strings.CutPrefix(reference, prefix)
			if !external {
				continue
			}
			filename, code, separated := strings.Cut(resource, ":")
			// Only these two files ship in Sora's engine bundle. A basename
			// check alone would still admit device names or unapproved assets.
			if !separated || code == "" || strings.Contains(code, ":") || (filename != "geoip.dat" && filename != "geosite.dat") {
				return errors.New("xray: profile external geodata must use bundled geoip.dat or geosite.dat")
			}
		}
	}
	return nil
}
