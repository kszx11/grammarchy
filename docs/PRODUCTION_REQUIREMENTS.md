# Grammarchy Production Requirements

## Parser decision gate

The implementation cannot claim production grammar analysis until one local English parser is selected through a benchmark. Candidates: packaged spaCy (`en_core_web_sm` or licensed equivalent), Stanza, or an offline ONNX dependency parser.

The selected provider must have a redistributable license, no network requirement at runtime, a documented model version/checksum, cancellation support, and a known disk/RAM budget. Record its version in every `GrammarModel` response.

Acceptance benchmark: 250 curated sentences across simple clauses, questions, passive voice, coordination, subordination, quotations, fragments, and punctuation errors. Measure token-role accuracy, dependency accuracy, rule false positives, cold/warm latency, RAM, and package size. A provider is accepted only after product-defined thresholds are met and failures have safe fallbacks.

## Operational requirements

| Area | Requirement |
| --- | --- |
| Locality | Parsing never transmits text. Any remote provider is a separate opt-in implementation. |
| Limits | 1,000 characters, 128 tokens, 1.5 s default timeout, cancellable request. |
| Updates | Parser/model versions are pinned, checksummed, and upgradeable independently of user configuration. |
| Recovery | Preserve input and last valid model on timeout, crash, malformed response, or cancellation. |
| Diagnostics | Record provider/version/error class only; never sentence text. |
| Resources | Target ≤500 ms warm parse for 8–30 tokens; document cold start, RSS, and model size. |

## Security and privacy

Treat clipboard and parser output as untrusted. Validate length, Unicode normalization, token IDs, list lengths, source ranges, confidence range, and all text before rendering. Do not log input, parser response, or clipboard contents. Configuration is user-owned, non-symlinked, size-bounded, and parsed fail-closed.

## Release gates

A release requires passing unit, integration, visual-layout, keyboard-only, network-blocked, fresh-install, upgrade, and rollback tests. The release record includes plugin version, provider/model version, checksum, test corpus revision, benchmark results, and known limitations.
