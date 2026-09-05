# Rules, Test Corpus, and UI Quality Plan

## Rule catalogue v1

| Rule ID | Finding | Evidence required | Default kind |
| --- | --- | --- | --- |
| SVA-001 | Subject–verb agreement | finite verb, subject, number/person features | error/possible |
| CLAUSE-001 | Fragment | no independent finite clause | possible |
| TENSE-001 | Tense consistency | multiple linked finite clauses and morphology | possible |
| DET-001 | Determiner/number mismatch | determiner, noun, number features | possible |
| MOD-001 | Dangling modifier | modifier attachment lacks compatible subject | possible |
| PAR-001 | Parallelism | coordination with comparable syntactic slots | possible |
| PUNC-001 | Comma splice/run-on | adjacent independent clauses and punctuation evidence | possible |

Style observations require an explicit effect description and are never errors. A rule may emit Error only above its documented confidence threshold; otherwise it emits Possible issue or nothing.

## Layout tests

For each fixture and viewport width (640, 760, 1024 px), assert: all labels and 44 px hit targets are in bounds; token rectangles do not overlap; connectors do not cross token rectangles; scroll extents reveal all content; selection highlights corresponding map, structure, relation, and finding evidence. Snapshot-test dark and light theme states.

## Fixture corpus

Maintain fixtures with input, expected fallback/map mode, required roles/phrases/relations, expected finding IDs, and prohibited false positives. Include declaratives, questions, imperatives, passive voice, coordination, nested subordinate clauses, relative clauses, quotations, fragments, comma splices, agreement cases, ambiguous attachments, and 60-token sentences.

## Keyboard and lifecycle tests

Open through the bar; verify immediate editor focus; type, paste, select, parse, cancel, retry, switch views, scroll, and close without a mouse. Test rapid edits, parser timeout, malformed provider output, panel reopen during fade, shell reload, fresh install, upgrade with existing config, and network-blocked execution.
