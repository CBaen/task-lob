# task-lob Capabilities TODO

**Reference**: `~/.claude/CAPABILITY_IMPLEMENTATION_GUIDE.md` has full implementation details.

**When you complete an item**: Mark it here AND in the main guide's Progress Tracking section.

---

## Why These Matter for task-lob

task-lob catches chaos from overwhelmed people. Every capability below serves that mission:

- **Caching** = Lower costs so Guiding Light can afford to run this
- **Audio analysis** = Level 10 - Urgency From Tone (the heart of task-lob)
- **Extended thinking** = Better routing for ambiguous tasks
- **Embeddings** = Semantic task matching ("website issue" → WordPress person)

---

## Phase 1: Foundations

### Prompt Caching

**Priority**: HIGHEST - do this first

`LOB_PARSER_PROMPT` is ~2,500 tokens sent with every lob. Cache it.

**File to modify**: `api/src/routes/lob-catcher.js` (or wherever Claude API is called)

```javascript
system: [
  {
    type: 'text',
    text: LOB_PARSER_PROMPT,
    cache_control: { type: 'ephemeral' },
  },
];
```

- [ ] LOB_PARSER_PROMPT cached
- [ ] CONTEXT_SYNTHESIS_PROMPT cached
- [ ] CLASSIFICATION_PROMPT cached
- [ ] Verified cache hits in response headers

### GitHub Actions

- [ ] `.github/workflows/claude-review.yml` created
- [ ] ANTHROPIC_API_KEY added to GitHub secrets
- [ ] Test PR verified workflow runs

### Extended Thinking

For complex routing decisions and ambiguous classification.

- [ ] Added to routing suggestion logic (budget: 5,000 tokens)
- [ ] Added to ambiguous task classification

---

## Phase 2: Gemini Audio (CRITICAL for task-lob)

This enables Level 10: Urgency From Tone.

**Current flow**: Voice → speech_to_text → Groq Whisper → text → LOB_PARSER
**New flow**: Voice → audio file → Gemini Audio API → {transcription, emotion, urgency} → Enhanced LOB_PARSER

- [ ] Audio recording captures file (not just text)
- [ ] Gemini audio analysis endpoint created
- [ ] Emotion detection integrated into LOB_PARSER input
- [ ] Urgency classification uses emotional context
- [ ] Tested with frustrated vs calm audio samples

---

## Phase 3: Semantic Embeddings

For smarter routing: "check on the website" → routes to WordPress person even without the word "WordPress"

- [ ] Embedding generation for routing patterns
- [ ] Similarity search for task matching
- [ ] Integration with routing suggestion API

---

## Not Applicable to task-lob

These are handled in other projects:

- Video analysis (WARDENCLYFFE)
- Imagen 4 (WARDENCLYFFE)
- 1M context (WARDENCLYFFE)
- Files API (WARDENCLYFFE)

---

_When complete, update `~/.claude/CAPABILITY_IMPLEMENTATION_GUIDE.md` Progress Tracking_
