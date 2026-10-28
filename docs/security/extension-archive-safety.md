# Extension archive layout and inflation

The Go package verifier and Flutter installer now reject archive namespaces that
cannot be represented unambiguously on both supported desktop platforms. They
do not rename members: the signature authenticates exact names and bytes.

Before this change, a correctly signed package could contain `entry.js` and
`ENTRY.JS`, or a trailing-dot spelling such as `entry.js.`. These are different
keys to a ZIP/checksum map but can name the same Windows file. A private Windows
filesystem reproduction confirmed both aliases. On the tested NTFS volume,
GetShortPathNameW also returned `LONGFI~1.JS` for `longfilename.js`; explicit short
name spellings can collide with another member without a case-only difference.
No filesystem policy or device configuration was changed for those checks.

The package gate refuses:

- Case aliases of files, inconsistent case of a shared directory, duplicate
  names and a file used as another member's directory. Directory components
  sort before sibling filename characters, so inserting `assets.js` cannot hide
  a clash between `assets` and `assets/entry.js`.
- Windows device basenames, including extensions and COM/LPT superscript digits,
  trailing dots/spaces, reserved characters and ASCII controls. Generated 8.3
  alias spellings are excluded even on systems that do not generate short names.
- Noncanonical traversal/absolute/drive/ADS paths, invalid UTF-8 scalar data,
  components over 255 UTF-8 bytes and paths over 512 bytes.

Unicode filenames and ordinary bundle names such as `vendors~app.js` remain
supported. Case keys use the standard simple-uppercase operations in Go/Dart;
this is not a general Unicode confusable or filesystem-normalization service.
Directory-only ZIP records are not extracted. The rules are applied before
inflation and repeated when verifying mutable/in-memory or cached file maps;
opening the ZIP once is not permission to mutate its namespace later.

On Flutter, local ZIP names, encryption and compression metadata are also checked
against the central directory before the decoder processes entries. This avoids
checking one name/method and then decoding another. Go's ZIP reader uses its
central-directory names/methods directly. No ZIP parser is implemented locally.

## Reusing the decoder's resource limits

`pubspec.yaml` now requires archive >=4.5.2, the version already in pubspec.lock.
Its ZipFile decoder limits all writes to the declared uncompressed size,
including LZ77 backreferences; Sora checks that size before decoding. Fixed
package/file-count, per-file, total-content and declared compression-ratio limits
remain. Actual output size and total content are also checked afterward.

The old `_CappedOutput` subclass predated this library API and duplicated only
some write paths. It is removed in favour of the library's maintained limiter.
This does not establish an exploitable inflation bypass in the previously locked
4.5.2 build: that library already supplied its own limit. Requiring the secure
minimum makes the dependency contract match the mechanism the app uses. No
resolved dependency version or new native library is introduced.

The relevant primary references are [Windows filename rules](https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file),
[GetShortPathNameW](https://learn.microsoft.com/en-us/windows/win32/api/fileapi/nf-fileapi-getshortpathnamew)
and the [archive 4.5.2 distribution/documentation](https://pub.dev/packages/archive/versions/4.5.2).
The locked library's source and changelog were inspected, including ZipFile's
declared-size enforcement and the limited stream's backreference handling.

## Choice and verification

The existing Go ZIP reader, Dart archive package and standard string/sort/regex
APIs are sufficient for the signed-layout policy. Candidate snapshot on
25 October 2026 (open counts include PRs):

| Candidate | Latest release | Stars / open | Unpacked package | License / runtime |
| --- | --- | --- | ---: | --- |
| [filenamify](https://github.com/sindresorhus/filenamify) | 7.0.3, 2026-08-28 | 525 / 2 | 12823 B | MIT; Node >=20, ESM |
| [sanitize-filename](https://github.com/parshap/node-sanitize-filename) | 1.6.4, 2026-03-20 | 371 / 26 | 17508 B | WTFPL or ISC; CommonJS, no declared engine range |

Both are active, but need a Node runtime and rewrite individual names. Rewriting
would invalidate signed checksum names and does not detect set-level collisions.
Neither fits this Go/Dart protocol boundary. No dependency is added.

Go and Dart consume shared vectors for aliases, device names, controls, Unicode,
directory clashes and byte limits. Go builds and signs rejected archives with
the existing public test identity. `signed_case_alias.soraext` was produced by
that test builder, not a production key: its signature is verified independently
in Dart before proving rejection and unchanged installed-store state. No script
from it is run. A false ZIP size must stop decompression; mismatched local
name/method/encryption fields must fail before decoder use. The targeted Flutter
suite is included in the existing Windows CI step as well as normal Linux tests.

Previously accepted ambiguous packages must be rebuilt with a portable layout
and signed again. This change does not audit every extraction-directory ACL,
same-user filesystem race, panel native bridge or archive-library internals;
the rest of S3 remains open.
