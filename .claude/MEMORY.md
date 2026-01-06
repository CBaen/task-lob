# Task Lob - Memory

Decisions, discoveries, and gotchas accumulated across sessions.

---

## Architecture Decisions

| Decision    | Choice             | Reason                              | Date    |
| ----------- | ------------------ | ----------------------------------- | ------- |
| Primary AI  | Groq llama-3.1-70b | Free tier, JSON-optimized           | Initial |
| Fallback AI | DeepSeek           | Backup with similar pricing         | Initial |
| Backend     | PocketBase         | Self-hosted, real-time, one binary  | Initial |
| Mobile      | Flutter            | Cross-platform, excellent voice     | Initial |
| Voice       | Push-to-talk       | Privacy-first, not always-listening | Initial |

---

## Prompt Engineering Notes

_Document what works and what doesn't for the lob parser._

### Signal Detectors That Work Well

- "First... second... also..." patterns
- Topic shifts mid-sentence
- Multiple systems mentioned

### Classification Accuracy Issues

_Track any classification problems here._

---

## PocketBase Gotchas

_Document any database-specific issues._

---

## Key Locations

| What              | Where                       |
| ----------------- | --------------------------- |
| Core prompts      | `api/src/lib/prompts.js`    |
| PocketBase client | `api/src/lib/pocketbase.js` |
| Test fixtures     | `test/fixtures/`            |
| Flutter models    | `app/lib/models/`           |

---

_Updated by: [Instance name] on [Date]_
