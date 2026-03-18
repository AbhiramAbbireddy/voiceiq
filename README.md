<p align="center">
  <h1 align="center">VoiceIQ — AI Interview Coach</h1>
  <p align="center">
    AI-powered speaking coach to help users improve interview performance through structured feedback.
  </p>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Mobile-blue?style=for-the-badge" />
  <img src="https://img.shields.io/badge/FastAPI-Backend-green?style=for-the-badge" />
  <img src="https://img.shields.io/badge/PostgreSQL-Database-blue?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Whisper-AI-orange?style=for-the-badge" />
  <img src="https://img.shields.io/badge/Python-3.10+-yellow?style=for-the-badge" />
  <img src="https://img.shields.io/badge/License-MIT-lightgrey?style=for-the-badge" />
</p>

---

## Overview

VoiceIQ is an AI-powered interview speaking coach that enables users to record responses, upload audio, receive AI-generated feedback, and track progress over time.

It combines a Flutter mobile app with a FastAPI backend, PostgreSQL database, and Whisper-based transcription.

---

## Navigation

- Features  
- Architecture  
- Tech Stack  
- Getting Started  
- Project Structure  
- API Flow  
- Next Steps  

---

## Features

| Module | Description |
|--------|------------|
| Voice Recording | Record audio or upload existing responses |
| Transcription | Convert speech to text using Whisper |
| AI Feedback | Generate structured feedback for improvement |
| Reports | Display transcript and coaching insights |
| Authentication | Secure login and signup with JWT |
| Progress Tracking | Monitor user improvement over time |

---

## Architecture

```text
Mobile App (Flutter)
        │
        ▼
FastAPI Backend (Python)
        │
        ├── Whisper (Speech-to-Text)
        ├── AI Feedback Engine
        └── PostgreSQL Database
Tech Stack

Flutter (Mobile frontend)

FastAPI (Backend APIs)

PostgreSQL (Database)

faster-whisper (Speech-to-text)

Docker Compose (Local setup)

Project Structure
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
Getting Started
Prerequisites

Flutter SDK

Python 3.10+

PostgreSQL

Git

Android Studio

Environment Setup

Create a .env file:

DB_NAME=voiceiq
DB_USER=postgres
DB_PASS=yourpassword
JWT_SECRET=your_secret
GEMINI_API_KEY=your_key
WHISPER_MODEL_SIZE=base
WHISPER_DEVICE=cpu
WHISPER_COMPUTE_TYPE=int8
Backend Setup
cd fastapi_backend
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 9090 --reload
Frontend Setup
cd frontend
flutter pub get
flutter run --dart-define=VOICEIQ_API_BASE_URL=http://10.0.2.2:9090
API Flow
Authentication

POST /api/v1/auth/register

POST /api/v1/auth/login

Voice Processing

Create session

Upload audio

Transcription

Generate feedback

User Data

Progress tracking

Profile management

Development Notes

Use small Whisper models (tiny, base) for faster development

Load models once at startup

Avoid blocking API during inference

Prefer real devices over emulators for testing

Next Steps

Payment integration

Production deployment

Background job queue

Advanced analytics dashboard

Backend profile update APIs

License

MIT License


---

If you want, I can take this one level higher like your screenshot:

- section icons using SVG (clean, not emoji)  
- feature cards instead of table  
- architecture diagram image  
- animated GIF demo  

Just tell me 👍