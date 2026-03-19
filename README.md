# VoiceIQ

VoiceIQ is an AI speaking coach for interview practice. Users record an answer, the backend transcribes it with Faster-Whisper, generates coaching feedback, and the Flutter app shows a report with scores, transcript, and progress.

## What is in this repo

- `fastapi_backend/` - FastAPI backend, Whisper transcription, Gemini-backed coaching fallback
- `frontend/` - Flutter Android app
- `database/` - SQL bootstrap files
- `nginx/` - reverse proxy config for production
- `docker-compose.yml` - local/dev stack
- `docker-compose.prod.yml` - production-style stack

## Local development

### Backend

```powershell
cd E:\voiceiq\fastapi_backend
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
$env:WHISPER_MODEL_SIZE="tiny"
python -m uvicorn main:app --host 0.0.0.0 --port 9090 --reload
```

API docs:

- [http://localhost:9090/docs](http://localhost:9090/docs)
- [http://localhost:9090/healthz](http://localhost:9090/healthz)

### Flutter app

```powershell
cd E:\voiceiq\frontend
flutter pub get
flutter run --dart-define=VOICEIQ_API_BASE_URL=http://10.101.123.83:9090
```

Replace `10.101.123.83` with your laptop LAN IP for physical-device testing.

## Production backend deployment

### 1. Prepare the server

Install these on your VPS or cloud VM:

- Docker
- Docker Compose plugin

Copy the repo to the server, then create a production env file from [`.env.production.example`](E:\voiceiq\.env.production.example).

Example:

```bash
cp .env.production.example .env
```

Update at least:

- `DB_PASS`
- `JWT_SECRET`
- `GEMINI_API_KEY`
- `WHISPER_MODEL_SIZE`

### 2. Start the production stack

```bash
docker compose --env-file .env -f docker-compose.prod.yml up -d --build
```

This starts:

- PostgreSQL
- FastAPI backend
- Nginx reverse proxy on port `80`

### 3. Verify the server

Open:

- `http://YOUR_SERVER_IP/healthz`
- `http://YOUR_SERVER_IP/docs`

If those work, the backend is live.

## Android release build

### 1. Create a keystore

Run this on your machine:

```powershell
keytool -genkey -v -keystore E:\voiceiq\frontend\android\voiceiq-release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias voiceiq
```

### 2. Create key.properties

Copy [key.properties.example](E:\voiceiq\frontend\android\key.properties.example) to `frontend/android/key.properties` and fill your real values.

Example:

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=voiceiq
storeFile=E:\\voiceiq\\frontend\\android\\voiceiq-release-keystore.jks
```

Important:

- `frontend/android/key.properties` is ignored by Git
- your keystore file should also stay private

### 3. Build the APK

```powershell
cd E:\voiceiq\frontend
flutter clean
flutter pub get
flutter build apk --release --dart-define=VOICEIQ_API_BASE_URL=http://YOUR_SERVER_IP
```

The APK will be generated at:

- [app-release.apk](E:\voiceiq\frontend\build\app\outputs\flutter-apk\app-release.apk)

### 4. Recommended store build

For Play Store upload, build an App Bundle instead of only an APK:

```powershell
flutter build appbundle --release --dart-define=VOICEIQ_API_BASE_URL=http://YOUR_SERVER_IP
```

Official Flutter docs recommend using `flutter build appbundle` for Play Store distribution: [Flutter docs](https://docs.flutter.dev/perf/app-size)

## Production notes

- The Android app now uses a real production package id: `com.voiceiq.app`
- Release builds should always pass `VOICEIQ_API_BASE_URL`
- The backend Docker build now pre-downloads the configured Whisper model
- `tiny` is best for local development
- `base` is a better default starting point for a low-cost production server
- If Gemini fails, the backend still generates a local fallback report

## FastAPI deployment reference

FastAPI's official deployment guidance for Docker and server processes:

- [FastAPI Docker deployment docs](https://fastapi.tiangolo.com/pt/deployment/docker/)
- [FastAPI deployment concepts](https://fastapi.tiangolo.com/de/deployment/concepts/)

## Suggested launch order

1. Deploy backend to the server
2. Verify `/healthz` and `/docs`
3. Build release APK with the production API URL
4. Install APK on phone and test signup, record, upload, report, progress
5. After that, set up HTTPS and a domain name

## Next production upgrades

- Move Gemini code from `google.generativeai` to `google.genai`
- Add HTTPS with Nginx + Certbot
- Replace local uploads with S3/R2 in the FastAPI backend too
- Add proper DB migrations instead of only `create_all()`
- Add background job queue if transcription load increases
