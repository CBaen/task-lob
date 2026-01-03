# Task Lob - Flutter App

The mobile app for Task Lob - The Lob Catcher.

## Structure

```
lib/
├── main.dart              # App entry point
├── models/
│   ├── task.dart          # Task data model
│   └── parsed_lob.dart    # Parsed lob result model
├── screens/
│   ├── home_screen.dart   # Main screen with PTT button
│   ├── lob_catcher.dart   # Review parsed tasks before sending
│   ├── my_court.dart      # Tasks waiting for my action
│   └── waiting.dart       # Tasks waiting on others
├── widgets/
│   ├── ptt_button.dart    # Push-to-talk button
│   ├── task_card.dart     # Task display card
│   └── lob_card.dart      # Card in lob catcher grid
├── services/
│   ├── api_service.dart   # Talk to AI Proxy
│   ├── voice_service.dart # Speech-to-text
│   └── pocketbase.dart    # PocketBase client
└── providers/
    ├── auth.dart          # Authentication state
    ├── tasks.dart         # Task state management
    └── voice.dart         # Voice input state
```

## Setup

### Prerequisites
- Flutter 3.x
- Xcode (for iOS) or Android Studio (for Android)

### Install Dependencies
```bash
flutter pub get
```

### Configure API URL
Set the API URL before running:
```bash
# Development
flutter run --dart-define=API_URL=http://localhost:3000

# Production
flutter run --dart-define=API_URL=https://your-api.com
```

### Run
```bash
# iOS Simulator
flutter run -d ios

# Android Emulator
flutter run -d android

# Both
flutter run
```

## Key Features to Implement

### Phase 0 (Hello World)
- [ ] Push-to-talk button
- [ ] Speech-to-text integration
- [ ] API connection to proxy
- [ ] Basic task display

### Phase 1 (Lob Catcher)
- [ ] Lob Catcher UI (card grid)
- [ ] Task/Self-service/Reminder/Venting cards
- [ ] Edit before sending
- [ ] Send selected tasks

### Phase 2 (Company Brain)
- [ ] Onboarding flow
- [ ] Routing suggestions
- [ ] Memory management UI

### Phase 3 (Court)
- [ ] My Court dashboard
- [ ] Waiting On Others dashboard
- [ ] Quick replies
- [ ] Push notifications

## Design Principles

### Neurodivergent-Friendly
- Large touch targets
- Clear visual hierarchy
- Minimal cognitive load
- Obvious "whose turn" indicators
- Non-judgmental tone

### Push-to-Talk First
- Voice is the primary input
- Text is fallback
- Hold button = record
- Release = send to AI

### Court-Centric
- Always know whose turn it is
- Red = waiting on you
- Clear = waiting on others
- Green = done
