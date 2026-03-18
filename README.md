# VoiceIQ

VoiceIQ is an AI-powered interview speaking coach that helps users record answers, upload audio, get feedback, and improve communication round performance over time. It combines a Flutter mobile app with a FastAPI backend, PostgreSQL, and Whisper-based transcription.

## What this project does

- `Flutter app` for onboarding, auth, recording, upload, feedback, progress, and profile flows
- `FastAPI backend` for authentication, audio upload, transcription, scoring, and AI coaching
- `PostgreSQL` for storing users, sessions, recordings, reports, and progress data
- `Docker setup` for local development

## Project structure

```text
voiceiq/
├─ fastapi_backend/              # Active backend
├─ frontend/                     # Flutter Android app
├─ database/                     # SQL init, migrations, seeds
├─ nginx/                        # Nginx config
├─ scripts/                      # Local helper scripts
├─ infra/                        # Infra-related workspace
├─ backend_spring_deprecated/    # Archived Spring Boot backend
├─ docker-compose.yml
├─ .gitignore
└─ README.md
```

## Tech stack

- `Flutter` for the mobile frontend
- `FastAPI` for backend APIs
- `PostgreSQL` for persistence
- `faster-whisper` for speech-to-text
- `Docker Compose` for local orchestration

## Features built so far

- `🔐 Auth flow`
  - Sign up
  - Log in
  - JWT-based session handling

- `🎙️ Voice flow`
  - Record audio inside the app
  - Pick existing audio files from the device
  - Upload audio for analysis

- `🧠 AI analysis`
  - Whisper transcription
  - Feedback generation
  - Report screen with transcript and coaching

- `📈 User journey`
  - Dashboard
  - Progress screen
  - Profile and local profile editing

## Requirements

Before running the project, make sure you have:

- `Flutter SDK`
- `Python 3.10+`
- `PostgreSQL`
- `Git`
- `Android Studio` with platform tools
- A real Android device or emulator

## Environment setup

Create a root `.env` file for backend values.

Example:

```env
DB_NAME=voiceiq
DB_USER=postgres
DB_PASS=yourpassword
JWT_SECRET=your_super_secret_key
GEMINI_API_KEY=your_key_if_used
WHISPER_MODEL_SIZE=base
WHISPER_DEVICE=cpu
WHISPER_COMPUTE_TYPE=int8
```

## Database setup

Make sure PostgreSQL is running and create a database named `voiceiq`.

If you are using Docker:

```powershell
docker-compose up --build
```

If you are using local PostgreSQL manually, ensure the credentials in `.env` match your system.

## Backend setup

The active backend is inside `fastapi_backend/`.

### 1. Create virtual environment

```powershell
cd E:\voiceiq\fastapi_backend
python -m venv venv
.\venv\Scripts\activate
```

### 2. Install dependencies

```powershell
pip install -r requirements.txt
```

### 3. Run the backend

```powershell
uvicorn main:app --host 0.0.0.0 --port 9090 --reload
```

### 4. Check the backend

Open:

- [http://localhost:9090/docs](http://localhost:9090/docs)

If you want to test from a physical Android phone on the same Wi-Fi, use your laptop IP instead of `localhost`.

Example:

- [http://10.101.123.83:9090/docs](http://10.101.123.83:9090/docs)

## Frontend setup

The Flutter app lives inside `frontend/`.

### 1. Install packages

```powershell
cd E:\voiceiq\frontend
flutter pub get
```

### 2. Connect a real Android device

- Enable `Developer options`
- Enable `USB debugging`
- Connect the device with USB
- Confirm the trust dialog on the phone

Check devices:

```powershell
flutter devices
```

### 3. Run the app

For an Android emulator:

```powershell
flutter run --dart-define=VOICEIQ_API_BASE_URL=http://10.0.2.2:9090
```

For a physical Android device on the same Wi-Fi:

```powershell
flutter run --dart-define=VOICEIQ_API_BASE_URL=http://10.101.123.83:9090
```

Replace `10.101.123.83` with your laptop IP when needed.

## API flow used by the app

### `1. Authentication`

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`

### `2. Voice analysis`

- create session
- upload recorded audio
- process transcription
- fetch feedback report

### `3. Progress and profile`

- progress view for completed sessions
- profile details and local edit state

## Important development notes

- `⚡ Use small Whisper models during development`
  - `tiny` or `base` are best on laptops
- `🧵 Load Whisper once at startup`
  - do not reload the model for every request
- `🧠 Prefer background processing`
  - avoid freezing the API on heavy inference
- `📱 Use a real phone when possible`
  - Android emulator + Whisper + backend together can slow the machine heavily

## Files and folders intentionally ignored

The root `.gitignore` now ignores:

- local virtual environments
- build folders
- logs
- local uploads
- IDE folders
- generated Flutter and Python caches

This keeps the repo clean for GitHub pushes.

## Archived code

`backend_spring_deprecated/` is kept as an archived reference to the earlier Spring Boot backend. It is not the active backend right now.

## Recommended GitHub push flow

```powershell
cd E:\voiceiq
git status
git add .
git commit -m "Prepare VoiceIQ project for GitHub"
git branch -M main
git remote add origin <your-repo-url>
git push -u origin main
```

## Next steps

- `💳 Razorpay integration`
- `☁️ Production deployment`
- `📬 Background job queue for heavy AI work`
- `📝 Better report history and progress analytics`
- `👤 Real backend profile update API`

---

Built with a lot of iteration, debugging, and stubbornness so the experience feels useful, calm, and real for interview preparation.
