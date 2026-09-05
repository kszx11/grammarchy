# Marketplace Readiness

## Installation model verified on Omarchy 4

Omarchy third-party plugins are plain Git repositories. `omarchy plugin add`
clones the repository into the user's plugin directory, validates the manifest,
and can enable the plugin in its declared bar section. It does not run plugin
code, install hooks, package managers, or `sudo` during installation.

Therefore a release cannot rely on an installation script to create a Python
environment or download a language model.

## Current release gate

The repository itself is small and the manifest correctly declares a
`bar-widget` with `defaultSection: "right"`. Python 3 and `wl-clipboard` are
present on the tested Omarchy system. Manual sentence entry remains available
when clipboard capture is unavailable.

The development-only spaCy runtime at `~/.config/grammarchy/runtime` is not a
release dependency. It is approximately 330 MB and tied to the host
Python/architecture, so it is intentionally excluded from the plugin.

The release candidate instead bundles a 19 MB Linux x86_64 UDPipe 1.4.0 binary
and the English UD model in `runtime/linux-x86_64/`. The adapter invokes this
artifact directly and does not import spaCy when the bundled provider is
available. The exact checksums, source, attribution, and licenses are in
`runtime/THIRD_PARTY_NOTICES.md`.

This removes setup and runtime-network burden for supported Linux x86_64
systems. Cross-architecture release artifacts and clean-install verification
remain release gates.

## Acceptable release paths

1. **Bundled portable parser artifact — selected.** UDPipe 1.4.0 plus the
   English model is bundled for Linux x86_64, runs offline, and has pinned
   checksums and notices.
2. **Additional architecture artifacts — pending.** Build and test matching
   artifacts for every architecture the public listing claims to support.
3. **Honest lightweight fallback — retained.** Unsupported architectures keep
   a clearly labelled heuristic fallback instead of silently failing.

An automatic first-use package download is not acceptable for the default
release: it is not offline, cannot run at marketplace installation time, and
would hide a large dependency behind a normal interaction.

## Release gates after parser packaging

- A current preview is included at `assets/grammarchy-phrases-preview.png`.
- Fresh install from a Git checkout: the bar widget appears in the right
  section and opens without configuration.
- Full parser works with the network disabled and no files outside the plugin
  checkout except user configuration created by the plugin itself.
- Parser artifact is pinned, checksummed, license-reviewed, and compatible
  with the supported architecture.
- Plugin validation, parser tests, keyboard-only smoke test, visual layout
  smoke test, upgrade test, and removal test pass.
- README, manifest, privacy statement, screenshot, license, and removal
  instructions accurately describe the shipped behavior.
