# Task Lob - Roadmap

**The Lob Catcher** - catch chaos, parse tasks, route intelligently.

This roadmap tracks what's done, what's in progress, and what's next. Every instance that works on Task Lob should update this file.

---

## The Vision

Task Lob is not a task manager. It's a **lob catcher**.

People don't send clean, well-formatted tasks. They lob chaos:

- Walls of text with 4 different things embedded
- Stream-of-consciousness voice notes
- Rants mixing bugs, requests, reminders, and venting

Task Lob catches that chaos, parses it into discrete pieces, classifies each piece, and routes them intelligently. Built for how neurodivergent people actually communicate.

---

## Don't Re-Debate (Decisions Made)

These decisions are final. Don't revisit them - build on them.

| Decision        | Choice              | Reason                                                                                                     |
| --------------- | ------------------- | ---------------------------------------------------------------------------------------------------------- |
| **AI Provider** | **User-selectable** | Provider-agnostic architecture. Users choose their preferred AI. Must support real-time internet research. |
| Voice Input     | Push-to-talk        | Privacy-first, not always-listening                                                                        |
| Hierarchy       | Peer-to-peer        | No boss/employee distinction in the system                                                                 |
| Backend         | PocketBase          | Self-hosted, real-time subscriptions, single binary                                                        |
| Mobile          | Flutter             | Cross-platform, excellent voice support                                                                    |
| UI Kit          | shadcn_ui (Dart)    | Accessible, neurodivergent-friendly design                                                                 |
| Test Data       | Real chaotic inputs | Never use clean examples - test with actual messy communication                                            |

---

## The 10 Levels (Non-Negotiable Features)

**MVP (Levels 1-5) - Build First:**

- [ ] **1. Catch My Chaos** - Parse however people speak into organized tasks
- [ ] **2. Don't Make Me Think About Routing** - AI learns who handles what
- [ ] **3. Show Me Whose Turn It Is** - Court system always obvious
- [ ] **4. Help Me Help Myself** - Self-service without shame
- [ ] **5. Research When I Can't** - AI researches with real-time internet access

**Moat (Levels 6-10) - What Makes Switching Painful:**

- [ ] **6. Context Injection** - Tasks arrive with what recipient needs
- [ ] **7. Resolution Memory** - AI learns what fixes work
- [ ] **8. Workload Awareness** - See who's carrying what
- [ ] **9. Venting Detection** - Acknowledge, don't action
- [ ] **10. Urgency From Tone** - How it's said, not just what

---

## Phases

### Phase 1: API Complete

**Status: ~70%**

- [x] Project structure and scaffolding
- [x] Health endpoint (`GET /api/health`)
- [x] Lob parser endpoint structure (`POST /api/lob/parse`)
- [x] Prompt library (`api/src/lib/prompts.js`)
- [x] PocketBase client abstraction
- [x] Task CRUD endpoints (10 endpoints defined)
- [x] Test fixtures (25 real-world cases)
- [ ] Full integration testing with PocketBase running
- [ ] Parser accuracy validation against fixtures
- [ ] Routing endpoints implementation
- [ ] Company Brain endpoints implementation
- [ ] Provider abstraction for AI (support multiple providers)

### Phase 2: Flutter UI

**Status: 5%**

- [x] Flutter models (Task, ParsedLob)
- [x] Service scaffolding (API client, voice service)
- [x] **Flutter SDK installed** (3.27.4, Windows desktop ready)
- [ ] HomeScreen - Entry point, quick capture, court overview
- [ ] CatcherScreen - Voice/text input, live parsing preview
- [ ] CourtScreen - Tasks waiting on ME
- [ ] WaitingScreen - Tasks waiting on OTHERS
- [ ] BrainScreen - Company learning, routing patterns

### Phase 3: Voice Integration

**Status: 0%**

- [ ] Push-to-talk implementation
- [ ] Speech-to-text integration
- [ ] Live transcription display
- [ ] Parse-on-release flow
- [ ] Error handling for failed transcription

### Phase 4: End-to-End Flow

**Status: 0%**

- [ ] Lob input → Parse → Display parsed items
- [ ] Review/edit parsed items before sending
- [ ] Route to recipient
- [ ] Recipient receives with context
- [ ] Court flips on action
- [ ] Resolution tracking

### Phase 5: Multi-User

**Status: 0%**

- [ ] User authentication (PocketBase auth)
- [ ] Workspace/team creation
- [ ] Invite flow
- [ ] Court handoffs between users
- [ ] Notification system

### Phase 6: Company Brain

**Status: 0%**

- [ ] Learn routing patterns from confirmations
- [ ] Learn resolution patterns from completions
- [ ] Suggest routing based on history
- [ ] Surface "this worked before" context

### Phase 7: Production Ready

**Status: 0%**

- [ ] Deployment (API + PocketBase)
- [ ] Onboarding flow for new users
- [ ] Documentation for self-hosting
- [ ] Licensing structure
- [ ] Landing page / marketing site

---

## Current Blockers

| Blocker                       | Impact                  | Resolution                                                                      |
| ----------------------------- | ----------------------- | ------------------------------------------------------------------------------- |
| ~~Flutter SDK not installed~~ | ~~Cannot build UI~~     | **RESOLVED** - Flutter 3.27.4 installed at `C:/Users/baenb/flutter-sdk/flutter` |
| PocketBase not running        | Cannot test full flow   | Start PocketBase, import schema                                                 |
| Android SDK not installed     | Cannot build mobile APK | Install Android Studio or standalone SDK when ready for mobile                  |

---

## Quick Start (For Next Instance)

```bash
# Clone (if needed)
git clone https://github.com/CBaen/task-lob.git
cd task-lob

# Start PocketBase
cd pocketbase && ./pocketbase serve
# Import schema.json via admin UI at http://127.0.0.1:8090/_/

# Start API (new terminal)
cd api
cp .env.example .env  # Add your AI provider API key
npm install && npm run dev

# Test parsing
curl http://localhost:3000/api/lob/test

# Flutter (once SDK installed)
cd app && flutter pub get && flutter run
```

---

## Key Files

| What                  | Where                       |
| --------------------- | --------------------------- |
| AI Prompts (critical) | `api/src/lib/prompts.js`    |
| PocketBase client     | `api/src/lib/pocketbase.js` |
| API routes            | `api/src/routes/`           |
| Flutter models        | `app/lib/models/`           |
| Test fixtures         | `test/fixtures/`            |
| Database schema       | `pocketbase/schema.json`    |

---

## Licensing Vision

Task Lob will be offered as:

- **Self-hosted license** - Companies run their own instance, own their data
- **Managed SaaS** - We host, per-seat pricing, lower friction

The core value: **Only tool designed for chaos-first communication.**

---

_Last updated: 2026-01-05 by Reluminant Instance (Flutter SDK setup)_
