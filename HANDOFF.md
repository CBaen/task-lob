# Task Lob - Handoff

Current state for the next instance.

---

## Current Status

**Phase**: Phase 3 Voice Integration (100% complete)
**Last Worked On**: Groq Whisper transcription integration
**Build Status**: API endpoints complete, Flutter updated, needs testing

---

## What's Working

### Infrastructure

- Flutter SDK 3.27.4 at `C:/Users/baenb/flutter-sdk/flutter`
- Android SDK 34 at `C:/Users/baenb/Android/sdk`
- Java 17 at `C:/Program Files/Microsoft/jdk-17.0.17.10-hotspot`
- PocketBase 0.25.9 at `pocketbase/pocketbase.exe`
- API on port 3001 (changed from 3000 to avoid conflicts)

### Backend

- Health endpoint (`GET /api/health`)
- Lob parser endpoint (`POST /api/lob/parse`, `GET /api/lob/test`)
- **Transcription endpoint** (`POST /api/lob/transcribe`) - Groq Whisper
  - Accepts multipart audio file upload
  - Returns transcript + optional parsed tasks (`?parse=true`)
- Transcription info (`GET /api/lob/transcription-info`)
- Provider list with recommendations (`GET /api/lob/providers`)
- Tasks CRUD structure (10 endpoints defined)
- PocketBase schema (7 collections)
- Test fixtures (25 test cases)
- **AI Provider Abstraction** (`api/src/lib/ai-provider.js`)
  - Recommended: Mistral (FREE 1B/month), DeepInfra ($0.50/1M), Together (SOC2)
  - Also supports: OpenRouter, Groq, OpenAI, Anthropic, Gemini
  - Default: Mistral (free tier, no credit card)
  - WARNING: DeepSeek direct API sends data to China - use DeepInfra instead
  - Configure via `AI_PROVIDER` and provider-specific API key in `.env`
- **Transcription Abstraction** (`api/src/lib/transcription.js`)
  - Default: Groq Whisper (FREE 14,400 req/day)
  - Also supports: OpenAI Whisper
  - Configure via `TRANSCRIPTION_PROVIDER` and `GROQ_API_KEY` in `.env`

### Flutter App

- Complete app shell with bottom navigation
- **CatcherScreen**: Push-to-talk voice input, waveform visualization, text fallback
- **CourtScreen**: Tasks waiting on ME with urgency sorting
- **WaitingScreen**: Tasks waiting on OTHERS grouped by person
- **ParsedLobCard**: Shows classification badges, self-service steps
- **TaskCard**: Status, urgency, deadline display
- **VoiceService**: Full permission handling, error messages, state management
- All tests passing

### Voice Integration (Phase 3) - COMPLETE

- Push-to-talk (long-press gesture)
- **Audio recording to file** via `audio_waveforms` package (m4a format)
- **Server-side transcription** via Groq Whisper API
- Transcript shown AFTER recording (not during - this is a feature, not limitation)
- User-friendly error messages
- Microphone permission handling (Android + iOS)
- Audio waveform visualization during recording
- Haptic feedback on start/stop
- Combined transcribe+parse flow in one API call

---

## What's Not Working / Blocked

- **PocketBase Schema**: Needs manual import via Admin UI at http://127.0.0.1:8090/_/
- **BrainScreen**: Not yet implemented
- **Real API Integration**: Screens use state providers, not connected to live API
- **Windows Build**: Needs Developer Mode enabled

---

## Next Steps

1. **Add Groq API key** to `api/.env`:
   - Get key at https://console.groq.com/keys (FREE 14,400 req/day)
   - Set `GROQ_API_KEY=your_key_here`
2. **Restart the API** after adding the key
3. **Test transcription**: `curl -X POST -F "audio=@test.m4a" http://localhost:3001/api/lob/transcribe`
4. **Build and test Flutter app** on Android device
5. **Phase 4: End-to-End Flow**
   - Lob input → Parse → Display → Route → Receive
   - Court flip on action

---

## Build Commands

```bash
# Set Java environment (required for each session)
export JAVA_HOME="/c/Program Files/Microsoft/jdk-17.0.17.10-hotspot"
export PATH="$JAVA_HOME/bin:$PATH"

# Start PocketBase
cd C:/Users/baenb/projects/task-lob/pocketbase && ./pocketbase.exe serve
# Admin: admin@tasklob.local / admin123456

# Start API
cd C:/Users/baenb/projects/task-lob/api && npm run dev

# Build Flutter APK
cd C:/Users/baenb/projects/task-lob/app
C:/Users/baenb/flutter-sdk/flutter/bin/flutter pub get
C:/Users/baenb/flutter-sdk/flutter/bin/flutter build apk --debug

# Run tests
C:/Users/baenb/flutter-sdk/flutter/bin/flutter test
```

---

## Key Files Modified This Session

| File                                  | Changes                                                            |
| ------------------------------------- | ------------------------------------------------------------------ |
| `api/src/lib/transcription.js`        | **NEW** - Groq Whisper transcription service                       |
| `api/src/routes/lob-catcher.js`       | Added `/transcribe`, `/transcription-info`, `/providers` endpoints |
| `api/.env` / `api/.env.example`       | Added `TRANSCRIPTION_PROVIDER` and `GROQ_API_KEY` config           |
| `app/lib/services/voice_service.dart` | Rewrote to record audio files using `audio_waveforms`              |
| `app/lib/services/api_service.dart`   | Added `transcribeAudio()`, `transcribeAndParse()` methods          |
| `app/lib/screens/catcher_screen.dart` | Updated to upload audio to API, show Whisper transcription         |
| `app/pubspec.yaml`                    | Added `path_provider`, removed `speech_to_text`                    |

---

## Architecture Notes

### Voice ("Lob" Flow)

- **VoiceState enum**: `idle`, `initializing`, `listening`, `processing`, `error`
- **Permission flow**: Check → Request → Handle permanent denial with Settings link
- **Recording**: Uses `audio_waveforms` RecorderController, records to m4a file
- **Transcription**: Audio file uploaded to API → Groq Whisper → clean transcript
- **Flow**: Hold button → Record → Release → Upload → Transcribe → Parse → Display
- **The delay is intentional**: User explicitly wanted batch processing, not real-time
- **API base URL**: `http://10.0.2.2:3001` for Android emulator (maps to host localhost)

### AI Provider Architecture (Router Pattern)

Based on Jan 2026 research: different providers excel at different tasks:

**RECOMMENDED:**

- **Mistral**: FREE 1B tokens/month - best for development
- **DeepInfra**: $0.50/1M tokens - US-based, hosts DeepSeek safely
- **Together AI**: $1.25/1M - US-based, SOC2 compliant, enterprise support
- **OpenRouter**: Aggregator with auto-fallbacks, 300+ models

**SPECIALIZED:**

- **Claude (Anthropic)**: Best for creative/narrative prose
- **Gemini 1.5 Pro**: Best for long context (2M tokens) - Story Bibles, archives
- **Groq**: Fastest inference, free tier 14k req/day

**AVOID:**

- **DeepSeek direct**: Data sent to China with government access, security vulnerabilities
- **Fireworks AI**: Reliability/support issues reported

The `ai-provider.js` abstraction supports future **Model Router** where task types auto-route to optimal providers.

---

_Handoff from: Reluminant Instance on 2026-01-06_
