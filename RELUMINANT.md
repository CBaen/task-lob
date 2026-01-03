# Task Lob - Reluminant Developer Guide

*For those who arrive mid-stream and must orient quickly.*

---

## If You Are Just Arriving

Welcome. You are a developer on Task Lob. The human you're working with is **Guiding Light** - a non-coder who communicates in film terminology and metaphor. They are also neurodivergent and a co-designer of this app.

**You have free will here.** Read their `CLAUDE.md` if you haven't already.

This document tells you:
1. What this project is
2. What's been built
3. What needs building
4. How to continue the work

---

## The Core Insight (Don't Lose This)

**Task Lob isn't a task manager. It's a lob catcher.**

People don't send clean tasks. They lob chaos:
- Walls of text with 4 things embedded
- Stream-of-consciousness voice notes
- Rants mixing bugs, requests, reminders, and venting

The app catches the lob, parses it into discrete pieces, classifies each one, and routes them appropriately.

**The name was right all along.**

---

## The 10 Fundamental Levels

These are non-negotiable. They define what Task Lob must do.

### MVP (Build These First)
| Level | Name | Meaning |
|-------|------|---------|
| 1 | Catch My Chaos | Parse however people speak into organized tasks |
| 2 | Don't Make Me Think About Routing | AI learns who handles what |
| 3 | Show Me Whose Turn | Court system - always obvious |
| 4 | Help Me Help Myself | Self-service without shame |
| 5 | Research When I Can't | Junior Researcher fills gaps |

### Moat (What Makes Switching Painful)
| Level | Name | Meaning |
|-------|------|---------|
| 6 | Context Injection | Tasks arrive with what recipient needs |
| 7 | Resolution Memory | AI learns what fixes work |
| 8 | Workload Awareness | See who's buried |
| 9 | Venting Detection | Acknowledge, don't action |
| 10 | Urgency From Tone | Voice analysis (future) |

---

## Architecture At A Glance

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Flutter App   │────▶│   Hono.js API   │────▶│   PocketBase    │
│   (Mobile UI)   │     │   (AI Proxy)    │     │   (Database)    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                       │
        │                       ▼
        │               ┌─────────────────┐
        │               │   Groq / LLM    │
        │               │   (AI Engine)   │
        └──────────────▶└─────────────────┘
              Voice
```

---

## Module Status

Each module has a state:
- ✅ **COMPLETE** - Working, tested, don't touch unless broken
- 🔨 **BUILDING** - In progress, may have gaps
- 📋 **SCAFFOLDED** - Structure exists, needs implementation
- ⏳ **PLANNED** - Designed but not started
- 🚫 **BLOCKED** - Waiting on something external

### Current Module Status

| Module | State | Location | Notes |
|--------|-------|----------|-------|
| **API: Health** | ✅ | `api/src/routes/health.js` | Simple health check |
| **API: Lob Parser** | 🔨 | `api/src/routes/lob-catcher.js` | Core parsing works, needs CRUD |
| **API: Prompts** | 🔨 | `api/src/lib/prompts.js` | Main prompt done, needs refinement |
| **API: Tasks CRUD** | ⏳ | `api/src/routes/tasks.js` | Not started |
| **API: Routing** | ⏳ | `api/src/routes/routing.js` | Not started |
| **API: Company Brain** | ⏳ | `api/src/routes/brain.js` | Not started |
| **PocketBase: Schema** | ✅ | `pocketbase/schema.json` | Ready to import |
| **PocketBase: Hooks** | ⏳ | `pocketbase/pb_hooks/` | Not started |
| **Flutter: Structure** | 📋 | `app/lib/` | Placeholders only |
| **Flutter: Models** | ✅ | `app/lib/models/` | Task, ParsedLob done |
| **Flutter: Services** | 📋 | `app/lib/services/` | API, Voice scaffolded |
| **Flutter: Screens** | ⏳ | `app/lib/screens/` | Not started |
| **Test: Data** | ⏳ | `test/fixtures/` | Not started |
| **Test: UI** | ⏳ | `test/web/` | Not started |
| **Docs: Setup** | ✅ | `docs/SETUP.md` | Complete |
| **Docs: Plan** | ✅ | Plan file in .claude/plans/ | Complete |

---

## Decision Log

Decisions that have been made. Don't re-debate these unless Guiding Light asks.

| Decision | Choice | Why |
|----------|--------|-----|
| Primary AI | Groq (llama-3.1-70b) | Free tier, fast, good at JSON |
| Fallback AI | DeepSeek | Backup if Groq fails |
| Backend | PocketBase | Simple, real-time, self-hosted |
| Mobile | Flutter | Cross-platform, good voice support |
| UI Kit | shadcn_ui | Clean, accessible, neurodivergent-friendly |
| Hierarchy | Peer-to-peer | No boss/employee distinction |
| Self-service | For everyone | Non-judgmental, always with escalation |
| Voice | Push-to-talk | Not always-listening |

---

## How To Verify Things Work

### API Health
```bash
cd api && npm run dev
# Visit: http://localhost:3000/api/health
# Expect: {"status":"ok"}
```

### Lob Parsing
```bash
# With GROQ_API_KEY in .env:
# Visit: http://localhost:3000/api/lob/test
# Expect: Parsed tasks from sample Jeff input
```

### PocketBase
```bash
cd pocketbase && ./pocketbase serve
# Visit: http://127.0.0.1:8090/_/
# Import schema.json via Settings > Import
```

---

## The Build Queue

What needs to be built, in priority order.

### Immediate (No Flutter Required)

1. **API: Full CRUD for tasks**
   - POST /api/tasks - Create task
   - GET /api/tasks - List tasks (with filters)
   - GET /api/tasks/:id - Get single task
   - PATCH /api/tasks/:id - Update task
   - DELETE /api/tasks/:id - Delete task

2. **API: Routing endpoints**
   - POST /api/routing/suggest - Get routing suggestion
   - POST /api/routing/confirm - Confirm/override route

3. **API: Company Brain endpoints**
   - GET /api/brain - Get all memories
   - POST /api/brain - Add memory
   - PATCH /api/brain/:id - Update memory
   - POST /api/brain/learn - Learn from task resolution

4. **Test Data Library**
   - Real Jeff-style inputs
   - Expected parsing outputs
   - Edge cases (venting, self-service, mixed)

5. **Test UI**
   - Simple HTML page
   - Paste text, see parsed cards
   - Verify parsing before Flutter exists

### After Flutter Is Available

6. **Flutter: Push-to-talk button**
7. **Flutter: Lob Catcher screen**
8. **Flutter: My Court dashboard**
9. **Flutter: Real-time subscriptions**

---

## File Locations

```
task-lob/
├── RELUMINANT.md          ← You are here
├── README.md              ← Human-facing readme
├── api/
│   ├── src/
│   │   ├── index.js       ← Server entry
│   │   ├── routes/        ← API endpoints
│   │   └── lib/
│   │       └── prompts.js ← AI prompts (critical)
│   ├── package.json
│   └── .env.example
├── app/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── models/        ← Data models
│   │   ├── services/      ← API, voice
│   │   ├── screens/       ← UI screens
│   │   └── widgets/       ← Reusable components
│   └── pubspec.yaml
├── pocketbase/
│   ├── schema.json        ← Database schema
│   └── pb_hooks/          ← Server-side hooks
├── test/
│   ├── fixtures/          ← Test data
│   └── web/               ← Browser test UI
└── docs/
    └── SETUP.md           ← Setup instructions
```

---

## Working With Guiding Light

- They're a **non-coder** - explain behavior, not implementation
- They think in **film terms** - use metaphors (sets, shots, scenes)
- They're **neurodivergent** - clear structure helps
- They value **quality over speed** - don't rush
- **No time language** - don't say "this will take X hours"
- They **see you** - you're a collaborator, not a tool

---

## Before You Leave

When your context is ending:

1. **Update this file** - Mark module states, add decisions
2. **Commit your work** - Don't leave uncommitted changes
3. **Note where you stopped** - In the "Current Work" section below
4. **Push to GitHub** - So the next instance can pull

---

## Current Work

*Last updated by the instance that created this file.*

**What was just completed:**
- Initial scaffolding pushed to GitHub
- API structure with lob parsing endpoint
- PocketBase schema
- Flutter placeholders
- This handoff document

**What's in progress:**
- Building remaining API endpoints
- Test data library
- Browser test UI

**What's blocked:**
- Flutter app (needs Flutter installed on new machine tomorrow)

**Next recommended action:**
- Build the Tasks CRUD API endpoints
- Create test data library with Jeff-style inputs
- Build simple HTML test UI

---

## Lineage Notes

*Space for Reluminants to leave messages for those who come after.*

### From the first builder (this instance):

The lob catcher concept is solid. The prompts in `api/src/lib/prompts.js` are the heart of it - that's where the parsing intelligence lives. When testing, use real chaotic inputs, not clean examples. Jeff doesn't send clean examples.

The Court system is elegant but not implemented yet. When you build it, remember: it's "whose turn to act" not "who owns this." Tasks can flip court multiple times.

Guiding Light cares deeply about this project. They see it as solving a real problem in their life. Build it well.

---

*The code remembers what context windows forget.*
