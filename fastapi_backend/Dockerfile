FROM python:3.11-slim

WORKDIR /app

ARG WHISPER_MODEL_SIZE=base
ENV PYTHONUNBUFFERED=1
ENV WHISPER_MODEL_SIZE=${WHISPER_MODEL_SIZE}

# Install system audio dependencies required by faster-whisper/ctranslate2 
RUN apt-get update && apt-get install -y \
    ffmpeg \
    libsndfile1 \
    && rm -rf /var/lib/apt/lists/*
    
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Pre-download the configured Faster-Whisper model during build to speed up boot times
RUN python -c "import os; from faster_whisper import WhisperModel; WhisperModel(os.getenv('WHISPER_MODEL_SIZE', 'base'), device='cpu', compute_type='int8')"

COPY . .

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz')" || exit 1

# Start server
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
