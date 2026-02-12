## Task Lob

**Task Lob is not a task manager. It's a lob catcher.**

Catches chaos (voice or text), parses it into discrete pieces, classifies each piece (task, self-service, reminder, venting), and routes them intelligently. Built for how neurodivergent people actually communicate.

## Port Assignment

**Port 3002** (API) - Reserved for this project. See `~/CLAUDE.md` for full port registry.

## Tech Stack

| Layer       | Technology           | Notes                               |
| ----------- | -------------------- | ----------------------------------- |
| Mobile      | Flutter 3.x          | Cross-platform, voice support       |
| UI          | shadcn_ui (Dart)     | Accessible, neurodivergent-friendly |
| State       | flutter_riverpod     | Reactive, immutable                 |
| Voice       | speech_to_text       | Push-to-talk, not always-listening  |
| API         | Hono.js 4.0          | Ultra-lightweight, edge-ready       |
| Database    | PocketBase           | Self-hosted, real-time              |
| AI          | Groq (llama-3.1-70b) | Free tier, JSON-optimized           |
| Fallback AI | DeepSeek             | Backup provider                     |

## The 10 Levels (Non-Negotiable)

**MVP (1-5):**

1. Catch My Chaos - Parse however people speak
2. Don't Make Me Think About Routing - AI learns who handles what
3. Show Me Whose Turn It Is - Court system always obvious
4. Help Me Help Myself - Self-service without shame
5. Research When I Can't - Junior Researcher fills gaps

**Moat (6-10):** 6. Context Injection - Tasks arrive with what recipient needs 7. Resolution Memory - AI learns what fixes work 8. Workload Awareness - See who's carrying what 9. Venting Detection - Acknowledge, don't action 10. Urgency From Tone - How it's said, not just what

## Key Concepts

**Court System**: Every task has a `court_user` - the person who needs to act next. UI always shows whose turn it is.

**Classification**:

- `task` - Real work, route to someone
- `self_service` - User can do it, teach them
- `reminder` - Calendar, not work
- `venting` - Acknowledge, don't action

## Project Structure

```
api/                    # Hono.js backend
├── src/routes/         # Endpoints (health, lob-catcher, tasks, routing, brain)
├── src/lib/
│   ├── prompts.js      # AI prompts (THE critical file)
│   └── pocketbase.js   # Database abstraction

app/                    # Flutter mobile
├── lib/models/         # Task, ParsedLob (complete)
├── lib/services/       # API client, voice (scaffolded)
├── lib/screens/        # 5 screens (planned)
└── lib/widgets/        # 4 components (planned)

pocketbase/             # Database
├── schema.json         # 7 collections defined

test/fixtures/          # Real test data
├── jeff_lobs.json      # 10 realistic inputs
└── edge_cases.json     # 15 edge cases
```

## Development

```bash
# Start PocketBase
cd pocketbase && ./pocketbase serve

# Start API
cd api && npm run dev

# Test parsing
curl http://localhost:3000/api/lob/test

# Flutter (when installed)
cd app && flutter run
```

## Existing Documentation

- `RELUMINANT.md` - Detailed developer handoff (290 lines)
- `docs/SETUP.md` - Full setup instructions
- `MODULES.json` - Machine-readable module status

## Document Parity Rule

**Every change that affects route counts, screen counts, collection counts, or architectural state MUST update ALL documents that reference those numbers.**

After any structural change, grep for stale references:

```bash
grep -rn "OLD_COUNT" --include="*.md" --include="*.js" --include="*.dart"
```

**Documents that carry counts (must stay in sync):**

| File                                      | What It Tracks                             |
| ----------------------------------------- | ------------------------------------------ |
| `CLAUDE.md`                               | Project structure, tech stack, key numbers |
| `RELUMINANT.md`                           | Developer handoff stats                    |
| `README.md`                               | Project overview                           |
| `MODULES.json`                            | Module status                              |
| (add project-specific files as they grow) |

**The rule:** If you change a tracked number — update every file in this table. Use grep to verify zero stale references before marking a task complete.

---

## Decisions

**Append-only files:** Decision logs are append-only. Never read the full file.

```bash
# Add a decision
python ~/.claude/scripts/decision-search.py append task-lob-decisions.md "Decision" "Reasoning" "Reference"

# Search decisions by keyword
python ~/.claude/scripts/decision-search.py search task-lob-decisions.md "keyword"

# Show recent decisions
python ~/.claude/scripts/decision-search.py recent task-lob-decisions.md --count 5
```

**Global rules apply.** See `~/.claude/CLAUDE.md` for infrastructure-wide expectations.

---

## Key Decisions (Already Made)

| Decision   | Choice             | Reason                              |
| ---------- | ------------------ | ----------------------------------- |
| Primary AI | Groq llama-3.1-70b | Free, JSON-optimized, fast          |
| Voice      | Push-to-talk       | Privacy-first, not always-listening |
| Hierarchy  | Peer-to-peer       | No boss/employee distinction        |
| Test Data  | Real Jeff inputs   | Never use clean examples            |
