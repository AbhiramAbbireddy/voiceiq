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