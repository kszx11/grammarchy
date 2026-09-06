# UDPipe runtime provenance

Grammarchy ships the Linux x86_64 UDPipe executable exactly as released by the
UDPipe project. It is **not** a locally compiled or modified executable.

## Authoritative release artifact

- Project: [UFAL UDPipe](https://github.com/ufal/udpipe)
- Release: [`v1.4.0`](https://github.com/ufal/udpipe/releases/tag/v1.4.0)
- Git source revision: `a0e72fcb1ba0d36998dc671db4350bbd159861b5`
- GitHub release asset ID: `318906028`
- Immutable-version download URL:
  `https://github.com/ufal/udpipe/releases/download/v1.4.0/udpipe-1.4.0-bin.zip`
- Release archive SHA-256:
  `457f541e204737d354c749b473060a28b2debf625f23075543d9eba78be016c1`
- Archive member bundled by Grammarchy:
  `udpipe-1.4.0-bin/bin-linux64/udpipe`
- Bundled binary SHA-256:
  `8770ff2114258a1df1ea8403dcbea92d3336ab6d3e420499d57c54e3dea6a11b`

The archive checksum pins the exact upstream release bytes. The executable
checksum pins the extracted member. Both must verify before a release is
accepted into this repository.

## Source audit reference

The corresponding source archive is independently pinned for review:

- URL:
  `https://github.com/ufal/udpipe/archive/a0e72fcb1ba0d36998dc671db4350bbd159861b5.tar.gz`
- SHA-256:
  `b06d279b1353b0cb417a989847b21789a7449520390b071d8cf48f168c0cc33e`

UDPipe's upstream release process uses its own maintained compiler toolchain;
we therefore do not claim that a local build reproduces the official binary
byte-for-byte. The authoritative-artifact route above is the provenance claim
for the executable that Grammarchy ships.

## Verification

On Linux with `bash`, `curl`, `unzip`, `tar`, `sha256sum`, and `cmp`:

```bash
bash contrib/verify-udpipe-runtime.sh
```

The command downloads only the pinned upstream archives over HTTPS into a
temporary directory. It verifies the archives and extracted executable, then
byte-compares the result with `runtime/linux-x86_64/udpipe`. It does not
modify the checkout.
