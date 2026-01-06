# Task Lob - Handoff

Current state for the next instance.

---

## Current Status

**Phase**: Early Foundation - Core Backend Complete
**Last Worked On**: API scaffolding
**Build Status**: API ready, Flutter pending system setup

---

## What's Working

- Health endpoint (`GET /api/health`)
- Lob parser endpoint (`POST /api/lob/parse`, `GET /api/lob/test`)
- Tasks CRUD structure (10 endpoints defined)
- PocketBase schema (7 collections)
- Flutter models (Task, ParsedLob)
- Test fixtures (25 test cases)
- Browser test UI

---

## What's Not Working / Blocked

- **Flutter**: Needs Flutter SDK installed on system
- **PocketBase**: Needs to be running for full integration testing
- **Routing/Brain APIs**: Scaffolded but not implemented

---

## Next Steps

1. Install Flutter SDK on Wardenclyffe system
2. Start PocketBase and import schema
3. Test API endpoints with fixtures
4. Implement Flutter screens (Home, Catcher, Court, Waiting, Brain)
5. Integrate voice input

---

## Test Commands

```bash
# Start PocketBase
cd pocketbase && ./pocketbase serve

# Start API
cd api && npm run dev

# Test parser
curl http://localhost:3000/api/lob/test
```

---

## Open Questions

- Groq API key configured?
- PocketBase admin credentials set?

---

_Handoff from: [Instance name] on [Date]_
