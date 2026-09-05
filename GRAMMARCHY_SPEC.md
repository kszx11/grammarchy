# Grammarchy — Robust English Grammar Map

**Status:** implementation specification · **Platform:** Omarchy 4 / Hyprland · **Language:** English

## Product decision

Grammarchy is a local-first sentence learning tool. Its primary display is a **grammar map**, not a universal Reed–Kellogg renderer. It must accept any English input without crashing, clipping essential content, or inventing certainty. Traditional diagrams are a future, deliberately limited teaching mode.

It provides four linked views from one shared model:

1. **Map** — graphical core clause and attached phrase groups.
2. **Structure** — accessible clause and phrase hierarchy.
3. **Relationships** — dependency links and uncertainty.
4. **Improve** — evidence-backed grammar findings and separate style observations.

## Reliability contract

| Input | Required result |
| --- | --- |
| Ordinary high-confidence sentence | Complete map, roles, phrases, clauses, and relations. |
| Ambiguous sentence | Best analysis with visible possible-attachment marker. |
| Long or complex sentence | Collapsed phrase/clause groups; never crossing-line graphics. |
| Fragment, quotation, poetry, malformed input | Token/partial structure view and explanation of uncertainty. |
| Parser unavailable | Keep editable input and prior map; offer retry. |

Only concrete rule evidence may be labelled **Error**. Tone, clarity, and voice are always **Style choice** or **Learning note**.

## Interaction and shell integration

Use Omarchy `KeyboardPanel`, anchored to the bar icon. The sentence editor receives focus on open and remains editable while parsing. The panel itself is vertically scrollable; a view may add one internal scroll direction only when necessary.

| Region | Contents |
| --- | --- |
| Header | Grammarchy, local-parser status, close. |
| Editor | Sentence field; one line, optionally two for overflow. |
| Tabs | Map, Structure, Relationships, Improve, Patterns. |
| Viewport | Current view and stable token selection. |
| Footer | Parse state, retry/cancel, keyboard hints. |

`Enter` parses immediately; `Esc` closes; `Tab` traverses controls. Live parsing is debounced 250–350 ms and retains the last valid analysis until a replacement is ready.

## Parser contract

Replace word-list heuristics with a versioned, offline English parser provider. It returns bounded, schema-validated syntax:

```text
NeutralSyntaxTree
  tokens: id, text, lemma, POS, morphology, source range
  dependencies: dependent id, head id, label, confidence
  constituents: type, token ids, parent id
  sentences: token ids, confidence, diagnostics
```

Recommended implementations are a packaged spaCy/Stanza model or offline ONNX dependency parser. It must be cancellable, accept at most 1,000 characters/128 tokens, and respect the configured timeout. No network is permitted by default.

## Shared grammar model

Every view consumes `GrammarModel`, never raw parser output:

```text
GrammarModel
  tokens: role, morphology, source range
  clauses: type, token ids, confidence
  phrases: NP/VP/PP/AdvP, parent, token ids
  relations: source, target, label, confidence
  findings: kind, rule id, evidence token ids, explanation
```

The UI validates all IDs, list bounds, text lengths, and confidence values before rendering.

## Grammar-map renderer

One deterministic layout engine measures labels, assigns geometry, and emits words, groups, connectors, focus targets, and accessibility data from a single scene. Never calculate canvas paths independently from QML text coordinates.

- Core lane: subject → predicate → object/complement.
- Phrase groups: labelled blocks attached to their governing token.
- Connector lanes: routed around token rectangles; never intersect a label or connector.
- Subordinate clauses: collapsed groups by default; expand on activation.
- Overflow: preserve at least 14 px label size and scroll instead of overlap or shrink.
- Uncertain relations: dotted connector plus textual uncertainty.
- Nodes: stable ID, 44 px hit target, visible selection state, accessible name.

Structure is the canonical fallback. Relationships displays directed, labelled links. Improve highlights the evidence token IDs referenced by its finding.

Patterns is a separate teaching layer for named English constructions. It may identify structurally clear patterns, but must not infer a sentence's historical language, source tradition, or cultural provenance.

## Rule engine

Rules use morphology and dependencies, never token position alone. Initial rules: subject–verb agreement, fragments, tense consistency, determiner/number mismatch, dangling modifier candidates, parallelism candidates, and comma-splice/run-on candidates.

Each finding includes a stable rule ID, severity (`error`, `possible`, `correct`, `style`), evidence IDs, confidence, plain-language explanation, and optional rewrite principle. Insufficient confidence downgrades Error to Possible.

## Privacy, accessibility, performance

- No network, telemetry, history, or persisted sentence input by default.
- Clipboard retains only the latest candidate and clears on close per configuration.
- Meet WCAG AA; color never solely conveys role or severity.
- Screen-reader order: sentence → clauses → phrases → tokens → relations → findings.
- Warm parse target ≤500 ms for 8–30 tokens; map first paint ≤100 ms after model receipt.

## Verification and acceptance

Test parser schema validation, cancellation/race handling, rule fixtures, layout invariants, and representative declaratives, questions, passive voice, coordination, nested clauses, quotations, fragments, and 60-token sentences.

Layout tests must prove every label and hit target is inside bounds, token rectangles never overlap, connectors never intersect token rectangles, and every relationship references a valid token.

Done means a keyboard-only user can open, edit, parse, select, switch views, and close; any accepted input yields a map or useful fallback; the panel never hangs, empties, or clips inaccessible content; and source tests, plugin validation, shell reload, and visual smoke tests pass.

## Delivery sequence

1. Stabilize keyboard panel and scroll container.
2. Introduce provider and `GrammarModel` contracts with fixtures.
3. Ship Structure and Improve against the model.
4. Implement measured grammar-map blocks for simple clauses and phrases.
5. Add nesting, uncertainty, complex-sentence collapse, and more rules.
6. Evaluate a limited Reed–Kellogg teaching mode only after map reliability is proven.

## Companion production documents

- [Production requirements](docs/PRODUCTION_REQUIREMENTS.md)
- [GrammarModel contract](docs/GRAMMAR_MODEL_SCHEMA.md)
- [Rule catalogue and verification plan](docs/RULES_AND_TEST_PLAN.md)
