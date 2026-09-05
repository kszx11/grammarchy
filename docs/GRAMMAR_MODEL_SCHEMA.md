# GrammarModel Contract v1

Every provider response is converted to this bounded, versioned model before UI rendering.

```json
{
  "schemaVersion": 1,
  "provider": {"id": "local-parser", "version": "1.0", "model": "en"},
  "sentence": {"text": "The dog runs.", "confidence": 0.93},
  "tokens": [{"id": 0, "text": "The", "start": 0, "end": 3, "upos": "DET", "role": "determiner", "features": {}}],
  "clauses": [{"id": "c0", "kind": "independent", "tokenIds": [0,1,2], "confidence": 0.93}],
  "phrases": [{"id": "p0", "kind": "NP", "parent": "c0", "tokenIds": [0,1], "head": 1, "confidence": 0.92}],
  "relations": [{"from": 1, "to": 2, "label": "nsubj", "confidence": 0.95}],
  "findings": [{"id": "agreement", "kind": "correct", "ruleId": "SVA-001", "tokenIds": [1,2], "confidence": 0.95, "message": "Subject and verb agree."}],
  "diagnostics": []
}
```

Validation: schema version is known; 1–128 tokens; IDs unique and contiguous; ranges within sentence; all referenced IDs exist; confidence is 0–1; strings have documented bounds; phrase parents form no cycle; relations contain no self-edge; findings use only `error`, `possible`, `correct`, or `style`. Invalid responses are discarded entirely.

Role values are display labels derived from syntax, not parser POS tags: subject, predicate, direct object, object of preposition, determiner, adjective modifier, adverbial modifier, conjunction, or uncertain.
