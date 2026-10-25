# Environment passed to engine subprocesses

Engine configuration checks and running engines already used `SafeEnv`, which
preserves a small OS/runtime allowlist instead of inheriting service secrets or
proxy variables. Version probing did not set `exec.Cmd.Env`, so that earlier
subprocess inherited the parent's full environment.

`TestEngineCommandsUseFilteredEnvironment` reproduced the difference through
actual child processes. The parent plants an artificial service-secret key and
upper/lowercase HTTP, HTTPS, ALL and NO proxy keys. The existing test executable
runs in a dedicated fixture mode, refuses any inherited forbidden fixture key,
requires an allowed `LANG` value, and prints a fixed version. The old version
probe failed; configuration checking and engine start passed.

The version prober now uses the same existing `SafeEnv` call. The allowlist and
runtime-variable policy are unchanged. No environment parser, dependency,
configuration flag or second filter is introduced. The existing self-process
test harness is reused for probe/check/start, including native Windows execution
with the production window-hiding path.

Fixtures never enumerate or print the real process environment or credential
values. Test variables exist only in the test process and are restored by the
Go test framework. No system/User environment setting, service, route or firewall
is modified. This demonstrates inheritance of planted values, not an incident
involving an actual credential or a live malicious engine.

Version recognition is not cryptographic executable authentication. Discovery
precedence, digest verification before execution, file replacement races and
the version-output resource bound remain separate review items. This change
does not complete the privileged-process or S3 audit.
