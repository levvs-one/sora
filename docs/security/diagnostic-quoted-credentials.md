# Quoted credentials in diagnostic output

The existing redactor masks exact registered plan values and recognised
credential labels in otherwise unknown engine output. Its old key/value pattern
missed quoted JSON keys and masked only the first word of a quoted log value.
Unknown passwords or tokens containing spaces could therefore leave the core in
diagnostic text and the diagnostic ZIP.

Regression tests use planted, unregistered values. The original redactor was
also compiled through a temporary Go source overlay, without changing the working
tree, to confirm that both `Collector.Run` and `report.txt` inside an actual
exported ZIP exposed the fixture. The overlay and source copy were temporary;
no real credential or production key was used.

The existing Go regular expression now recognises quoted keys and complete
quoted scalar values, including escaped quotes/backslashes, YAML doubled single
quotes, multiline whitespace and truncated values ending at EOF. Replacements
preserve quotes for valid JSON scalar fields. Unrelated keys such as `token_count`
remain intact; running the redactor twice does not change already masked output.
The label set, exact-value registration and URL/UUID masking remain in use.
This is a change to the existing standard-library matcher, not a new parser or
dependency.

Coverage includes eight input styles, unrelated structured fields, truncated
quotes/escapes, the existing plan/REALITY/scheme tests, and all three decompressed
diagnostic ZIP entries. The fixture source supplies report/events through the
real collector; it is not evidence of a live engine leaking a user's password.
The test explicitly checks that the ZIP contains three entries.

Redaction remains a defence in depth. Producers must register known secrets and
avoid logging credentials. Arbitrary encoded/renamed fields, secret objects or
arrays, opaque binary values and every possible malformed serialization are not
covered by this scalar key/value matcher. This does not complete the diagnostic
data-flow review or the S3 audit.
