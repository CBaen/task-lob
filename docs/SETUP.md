# Task Lob - Setup Guide

Complete setup instructions for getting Task Lob running on a new machine.

## Prerequisites

### Required
- **Node.js 18+** - [nodejs.org](https://nodejs.org)
- **Flutter 3.x** - [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install)
- **Git** - [git-scm.com](https://git-scm.com)

### For Mobile Development
- **iOS**: Xcode (Mac only)
- **Android**: Android Studio

### API Key
- **Groq API Key** (free) - [console.groq.com/keys](https://console.groq.com/keys)

## Step 1: Clone the Repo

```bash
git clone https://github.com/CBaen/task-lob.git
cd task-lob
```

## Step 2: Set Up the API Proxy

```bash
cd api
npm install
```

Create your `.env` file:
```bash
cp .env.example .env
```

Edit `.env` and add your Groq API key:
```
GROQ_API_KEY=your_key_here
POCKETBASE_URL=http://127.0.0.1:8090
PORT=3000
```

Test the API:
```bash
npm run dev
```

Visit http://localhost:3000/api/health - you should see `{"status":"ok"}`.

## Step 3: Set Up PocketBase

### Download PocketBase
1. Go to [pocketbase.io/docs](https://pocketbase.io/docs/)
2. Download the executable for your OS
3. Extract to `task-lob/pocketbase/`

### Start PocketBase
```bash
cd pocketbase
./pocketbase serve
```

### Create Admin Account
1. Go to http://127.0.0.1:8090/_/
2. Create your admin account
3. Import schema: Settings > Import collections > upload `schema.json`

## Step 4: Set Up Flutter App

```bash
cd app
flutter pub get
```

### iOS Setup (Mac only)
```bash
cd ios
pod install
cd ..
```

### Run the App
```bash
# With API URL configured
flutter run --dart-define=API_URL=http://localhost:3000
```

## Step 5: Verify Everything Works

1. **API Health**: http://localhost:3000/api/health
2. **PocketBase Admin**: http://127.0.0.1:8090/_/
3. **Test Lob Parsing**: http://localhost:3000/api/lob/test
4. **Flutter App**: Should show "Task Lob" with mic button

## Development Workflow

### Start All Services

Terminal 1 (PocketBase):
```bash
cd pocketbase
./pocketbase serve
```

Terminal 2 (API):
```bash
cd api
npm run dev
```

Terminal 3 (Flutter):
```bash
cd app
flutter run
```

## Troubleshooting

### "GROQ_API_KEY not set"
- Make sure you created `api/.env` with your key
- Restart the API server after editing `.env`

### "PocketBase connection refused"
- Make sure PocketBase is running
- Check it's on port 8090

### "Flutter dependencies failed"
- Run `flutter doctor` to check for issues
- Make sure you have the correct Flutter version (3.x)

### "speech_to_text not working"
- iOS: Add microphone permission to Info.plist
- Android: Add microphone permission to AndroidManifest.xml
- Check device has microphone access enabled

## Next Steps

Once everything is running:
1. Hold the mic button and speak
2. Watch the transcript appear
3. See it parsed into task cards
4. Send to PocketBase

You're ready to start catching lobs!
