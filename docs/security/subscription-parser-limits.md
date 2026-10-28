# Imported server count limits

The core's `LinkParser.MaxItems` previously capped link/base64 lists and Mieru
binding expansion, but JSON and YAML imports ignored it. Real regression tests
with three unique valid entries and a limit of one returned three servers for
Clash YAML, sing-box JSON, SIP008 JSON and arrays of Xray profiles.

The existing limit now applies before converting or serialising further JSON or
YAML entries. It counts accepted unique servers, matching link-list behaviour.
Extra entries are reported as unsupported with their source index and the stable
reason `item limit exceeded`; the import is not silently truncated. Zero or a
negative configured value still selects the existing default of 20,000.
Duplicates and invalid entries before the limit keep their existing accounting.
A complete Xray configuration remains one profile: its internal outbounds are
not split or discarded to meet the outer server count.

The same matrix exposed a trailing empty Base64 line counted as an unsupported
server after the limit. Empty lines and comments now stay outside item counting.
OLCRTC metadata still attaches to the last accepted server; metadata after a
rejected server cannot overwrite that earlier server. The standalone detector
also checks the existing 16 MiB byte limit before whitespace conversion and
empty-source classification.

Tests first failed on the old implementation. Coverage includes six list formats
at limits -1, 0, 1, 2, 3 and 4; mixed duplicate/invalid/valid entries; source
indexes; a multi-outbound Xray profile; oversized whitespace; and metadata at the
cap in plain and Base64 lists. Existing parser/protocol tests remain required.
Only the existing Go standard library and installed YAML/protobuf decoders are
used; no new parser, validator, dependency or configuration option is introduced.

This fixes the result-count contract, not every resource boundary. JSON and YAML
still decode a whole document before the result cap; input trees, alias/depth
behaviour, reports for many rejected entries and concurrent imports need their
own resource review. The 16 MiB input bound and a server-count limit are not a
hard process memory or CPU budget. No hostile process-exhaustion test was run on
the owner's machine, and this is not the complete S3 or an external audit.
