# Task Lob - The Lob Catcher

**Task Lob isn't a task manager. It's a lob catcher.**

People don't send "tasks" - they lob chaos over the wall. Walls of text with 4 different things embedded. Stream-of-consciousness voice notes. Rants that contain bugs, requests, reminders, and things they could do themselves all mixed together.

The app catches the lob, parses it into discrete pieces, makes sense of each one, and distributes them where they need to go.

## Project Structure

```
task-lob/
├── app/                    # Flutter mobile app
│   └── lib/
│       ├── screens/        # UI screens
│       ├── widgets/        # Reusable components
│       ├── services/       # API calls, voice
│       ├── models/         # Data models
│       └── providers/      # State management
├── api/                    # Hono.js AI Proxy
│   └── src/
│       ├── routes/         # API endpoints
│       └── lib/            # AI prompts, utilities
├── pocketbase/             # PocketBase config + schema
└── docs/                   # Documentation
```

## The 10 Fundamental Levels

### MVP (Levels 1-5)
1. **Catch My Chaos** - Speak/type however you think, it gets organized
2. **Don't Make Me Think About Routing** - AI learns who handles what
3. **Show Me Whose Turn It Is** - Court is always obvious
4. **Help Me Help Myself** - Self-service without shame
5. **Research When I Can't** - AI fills gaps you don't have time to fill

### Moat (Levels 6-10)
6. **Context Injection** - Tasks arrive with what recipient needs
7. **Resolution Memory** - AI learns what fixes work
8. **Workload Awareness** - See who's carrying what
9. **Venting Detection** - Acknowledge, don't action
10. **Urgency From Tone** - How it's said, not just what

## Tech Stack

| Layer | Tool |
|-------|------|
| Mobile | Flutter |
| UI | shadcn_ui |
| Voice | speech_to_text |
| Backend | PocketBase |
| AI Proxy | Hono.js + Vercel AI SDK |
| Primary AI | Groq (free tier) |
| Fallback AI | DeepSeek |

## Getting Started

### Prerequisites
- Flutter 3.x
- Node.js 18+
- PocketBase

### Setup

```bash
# Clone the repo
git clone https://github.com/CBaen/task-lob.git
cd task-lob

# Set up API
cd api
npm install
cp .env.example .env
# Add your GROQ_API_KEY to .env

# Start PocketBase
cd ../pocketbase
./pocketbase serve

# Start API (in another terminal)
cd ../api
npm run dev

# Start Flutter app (in another terminal)
cd ../app
flutter pub get
flutter run
```

## Environment Variables

Create `api/.env`:
```
GROQ_API_KEY=your_key_here
POCKETBASE_URL=http://127.0.0.1:8090
```

## License

MIT
