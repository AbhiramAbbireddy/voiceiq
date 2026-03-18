<p align="center">
  <h1 align="center">VoiceIQ — AI Interview Speaking Coach</h1>
  <p align="center">
    AI-powered platform to help users improve interview communication through speech analysis and feedback.
  </p>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Mobile-blue?style=for-the-badge" />
  <img src="https://img.shields.io/badge/FastAPI-Backend-green?style=for-the-badge" />
  <img src="https://img.shields.io/badge/PostgreSQL-Database-blue?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Whisper-AI-orange?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Python-3.10+-yellow?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Docker-Containerization-blue?style=for-the-badge" />
  <img src="https://img.shields.io/badge/License-MIT-lightgrey?style=for-the-badge" />
</p>

---

## Overview

VoiceIQ is an AI-powered interview speaking coach designed to help users prepare for interviews by analyzing their spoken responses.

Users can record answers, upload audio, receive AI-generated feedback, and track their progress over time. The system combines a mobile frontend with a scalable backend and speech-to-text intelligence.

---

## Navigation

- Features  
- Architecture  
- Tech Stack  
- Project Structure  
- Getting Started  
- API Flow  
- Development Notes  
- Next Steps  
- License  

---

## Features

| Module | Description |
|--------|------------|
| Voice Recording | Record answers or upload audio files |
| Speech-to-Text | Transcription using faster-whisper |
| AI Feedback | Analyze responses and generate improvement suggestions |
| Reports | Structured feedback with transcript display |
| Authentication | Secure login and signup with JWT |
| Progress Tracking | Monitor user performance over time |

---

## Architecture

```text
Flutter Mobile App
        │
        ▼
FastAPI Backend (Python)
        │
        ├── Speech-to-Text (Whisper)
        ├── AI Feedback Engine
        └── PostgreSQL Database
```

---

## Tech Stack

- Flutter (Mobile frontend)  
- FastAPI (Backend APIs)  
- PostgreSQL (Database)  
- faster-whisper (Speech-to-text)  
- Docker Compose (Local development)

---

## Project Structure

```text
voiceiq/
├─ fastapi_backend/
├─ frontend/
├─ database/
├─ nginx/
├─ scripts/
├─ infra/
├─ backend_spring_deprecated/
├─ docker-compose.yml
├─ .gitignore
└─ README.md
```

---

## Getting Started

### Prerequisites

- Flutter SDK  
- Python 3.10+  
- PostgreSQL  
- Git  
- Android Studio  

---

### Environment Setup

Create a `.env` file in the root directory:

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

---

### Backend Setup

```bash
cd fastapi_backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 9090 --reload
```

Access API docs:

```
http://localhost:9090/docs
```

---

### Frontend Setup

```bash
cd frontend
flutter pub get
flutter run --dart-define=VOICEIQ_API_BASE_URL=http://10.0.2.2:9090
```

For physical device:

```bash
flutter run --dart-define=VOICEIQ_API_BASE_URL=http://<your-ip>:9090
```

---

## API Flow

### Authentication
- POST /api/v1/auth/register  
- POST /api/v1/auth/login  

### Voice Processing
- Create session  
- Upload audio  
- Transcription  
- Generate feedback  

### User Data
- Progress tracking  
- Profile management  

---

## Development Notes

- Use smaller Whisper models (`tiny`, `base`) during development  
- Load models once at application startup  
- Avoid blocking API during inference tasks  
- Prefer real devices over emulators for performance testing  

---

## Next Steps

- Payment integration  
- Production deployment  
- Background job queue for AI processing  
- Advanced analytics dashboard  
- Backend profile update APIs  

---

## License

This project is licensed under the MIT License.