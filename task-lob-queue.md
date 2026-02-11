# task-lob Queue

**Purpose:** Active tasks only. Completed tasks move to `task-lob-queue-history.md`.

---

## Active

- [ ] **Implement prompt caching** (added: 2026-02-10)
      What: Cache LOB_PARSER_PROMPT, CONTEXT_SYNTHESIS_PROMPT, and CLASSIFICATION_PROMPT using cache_control ephemeral. Verify cache hits in response headers.
      Context: Migrated from CAPABILITIES_TODO.md Phase 1. File to modify: `api/src/routes/lob-catcher.js`

- [ ] **Set up GitHub Actions for Claude review** (added: 2026-02-10)
      What: Create `.github/workflows/claude-review.yml`, add ANTHROPIC_API_KEY to secrets, verify on test PR.
      Context: Migrated from CAPABILITIES_TODO.md Phase 1

- [ ] **Add extended thinking for routing** (added: 2026-02-10)
      What: Add extended thinking (5,000 token budget) to routing suggestion logic and ambiguous task classification.
      Context: Migrated from CAPABILITIES_TODO.md Phase 1

- [ ] **Integrate Gemini Audio for urgency detection** (added: 2026-02-10)
      What: Enable Level 10 Urgency From Tone. Capture audio files (not just text), create Gemini audio analysis endpoint, integrate emotion detection into LOB_PARSER, test with frustrated vs calm samples.
      Context: Migrated from CAPABILITIES_TODO.md Phase 2. Current flow: Voice > Whisper > text. New flow: Voice > Gemini Audio > emotion+urgency+text.

- [ ] **Build semantic embeddings for routing** (added: 2026-02-10)
      What: Generate embeddings for routing patterns, implement similarity search for task matching, integrate with routing suggestion API. Goal: "check on the website" routes to WordPress person without keyword match.
      Context: Migrated from CAPABILITIES_TODO.md Phase 3

---

**When completing a task:**

1. Format it as shown below
2. Move it to `task-lob-queue-history.md`

```
- [x] **Task name** (added: YYYY-MM-DD, completed: YYYY-MM-DD)
      What: 1-2 sentence description of what was done
      Result: Index topic "Y", commit abc123, Qdrant session xyz
```

**Rules:**

- Every task needs a description (1-2 sentences)
- Points to index, Qdrant, GitHub as needed
