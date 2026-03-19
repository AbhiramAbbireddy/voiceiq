import os
import tempfile
import logging
from pathlib import Path
from datetime import timedelta
from typing import List

from fastapi import FastAPI, Depends, HTTPException, status, File, UploadFile, Form, BackgroundTasks
from fastapi.responses import JSONResponse
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from faster_whisper import WhisperModel

import database
import models
import auth

# Lazy import to avoid Windows Registry read on startup
analyze_transcript_with_gemini = None

# Ensure models are created on startup (similar to Hibernate ddl-auto=update)
models.Base.metadata.create_all(bind=database.engine)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("fastapi-backend")

app = FastAPI(title="VoiceIQ API")

# ── Faster-Whisper Initialization ──────────────────────────────
# Lazy load Whisper model to avoid blocking startup (first load downloads model)
MODEL_SIZE = os.getenv("WHISPER_MODEL_SIZE", "tiny") # Changed "base" to "tiny" to save ~800MB RAM
DEVICE = os.getenv("WHISPER_DEVICE", "cpu")
COMPUTE_TYPE = os.getenv("WHISPER_COMPUTE_TYPE", "int8")
LANGUAGE = os.getenv("WHISPER_LANGUAGE", "en")

whisper_model = None  # Will be loaded on first use


def _get_feedback_analyzer():
    global analyze_transcript_with_gemini
    if analyze_transcript_with_gemini is None:
        from ai_coach import analyze_transcript_with_gemini as gemini_analyzer

        analyze_transcript_with_gemini = gemini_analyzer
    return analyze_transcript_with_gemini


def _ensure_feedback_report(db: Session, recording: models.Recording):
    feedback = recording.feedback
    if feedback:
        return feedback

    transcript_text = (recording.transcript or "").strip()
    if not transcript_text:
        return None

    analyzer = _get_feedback_analyzer()
    feedback_json = analyzer(transcript_text, recording.duration_seconds or 0)

    feedback = db.query(models.FeedbackReport).filter(
        models.FeedbackReport.recording_id == recording.id
    ).first()
    if not feedback:
        feedback = models.FeedbackReport(recording_id=recording.id)
        db.add(feedback)

    feedback.overall_score = feedback_json.get("overall_score", 0.0)
    feedback.grammar_score = feedback_json.get("grammar_score", 0.0)
    feedback.clarity_score = feedback_json.get("clarity_score", 0.0)
    feedback.confidence_score = feedback_json.get("confidence_score", 0.0)
    feedback.pace_score = feedback_json.get("pace_score", 0.0)
    feedback.ai_comments = feedback_json.get("ai_comments", "No comments provided.")
    db.commit()
    db.refresh(feedback)
    return feedback


# ── Auth Endpoints ─────────────────────────────────────────────
from pydantic import BaseModel, EmailStr

class UserRegister(BaseModel):
    email: EmailStr
    password: str
    fullName: str
    targetRole: str = "ROLE_USER"

class AuthResponse(BaseModel):
    userId: str
    email: str
    fullName: str
    targetRole: str
    plan: str
    token: str

@app.post("/api/v1/auth/register")
def register(user_req: UserRegister, db: Session = Depends(database.get_db)):
    if db.query(models.User).filter(models.User.email == user_req.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")
        
    hashed_password = auth.get_password_hash(user_req.password)
    user = models.User(
        email=user_req.email, 
        password_hash=hashed_password, 
        full_name=user_req.fullName, 
        target_role=user_req.targetRole,
        plan="FREE"
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    access_token_expires = timedelta(minutes=60 * 24 * 7)
    access_token = auth.create_access_token(
        data={"sub": str(user.id)}, expires_delta=access_token_expires
    )
    
    response_data = AuthResponse(
        userId=str(user.id),
        email=user.email,
        fullName=user.full_name,
        targetRole=user.target_role,
        plan=user.plan,
        token=access_token
    )
    
    return {
        "success": True,
        "data": response_data.dict(),
        "message": "User registered successfully"
    }

class UserLogin(BaseModel):
    email: str
    password: str

@app.post("/api/v1/auth/login")
def login(login_req: UserLogin, db: Session = Depends(database.get_db)):
    user = db.query(models.User).filter(models.User.email == login_req.email).first()
    if not user or not auth.verify_password(login_req.password, user.password_hash):
        raise HTTPException(status_code=400, detail="Incorrect email or password")
        
    access_token_expires = timedelta(minutes=60 * 24 * 7)
    access_token = auth.create_access_token(
        data={"sub": str(user.id)}, expires_delta=access_token_expires
    )
    
    response_data = AuthResponse(
        userId=str(user.id),
        email=user.email,
        fullName=user.full_name,
        targetRole=user.target_role,
        plan=user.plan,
        token=access_token
    )
    
    return {
        "success": True,
        "data": response_data.dict(),
        "message": "Login successful"
    }


# ── Session Endpoints ──────────────────────────────────────────
@app.post("/api/v1/speech/sessions")
def create_session(db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    # Standardize to Mock Interview #X (like AppController in Flutter)
    session_count = db.query(models.InterviewSession).filter(models.InterviewSession.user_id == current_user.id).count()
    title = f"Mock Interview #{session_count + 1}"
    
    session = models.InterviewSession(user_id=current_user.id, title=title)
    db.add(session)
    db.commit()
    db.refresh(session)
    return {
        "success": True,
        "data": {
            "sessionId": str(session.id), 
            "title": session.title, 
            "status": session.status,
            "promptText": "Please talk briefly about yourself and your background."
        },
        "message": "Session created successfully"
    }

@app.get("/api/v1/speech/sessions")
def get_sessions(db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    sessions = db.query(models.InterviewSession).filter(models.InterviewSession.user_id == current_user.id).all()
    return {
        "success": True,
        "data": [
            {
                "sessionId": str(s.id), 
                "title": s.title, 
                "status": s.status,
                "promptText": "Please talk briefly about yourself and your background."
            } for s in sessions
        ],
        "message": "Sessions retrieved successfully"
    }


# ── Upload & Transcribe (Unified Backend Logic) ──────────────────

class InitiateUploadRequest(BaseModel):
    originalFileName: str
    mimeType: str

@app.post("/api/v1/speech/sessions/{sessionId}/initiate-upload")
def initiate_upload(
    sessionId: str,
    req: InitiateUploadRequest,
    db: Session = Depends(database.get_db), 
    current_user: models.User = Depends(auth.get_current_user)
):
    session = db.query(models.InterviewSession).filter(models.InterviewSession.id == sessionId).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
        
    session.status = "RECORDING"
    db.commit()

    return {
        "success": True,
        "data": {
            "sessionId": sessionId,
            "recordingId": sessionId,
            "uploadType": "BACKEND_MULTIPART",
            "uploadUrl": f"/api/v1/speech/sessions/{sessionId}/upload",
            "objectKey": f"{sessionId}.m4a",
            "storageUrl": "",
            "requiredHeaders": {}
        },
        "message": "Upload initiated"
    }

@app.post("/api/v1/speech/sessions/{sessionId}/upload")
async def upload_audio_multipart(
    sessionId: str,
    background_tasks: BackgroundTasks,
    durationSeconds: int = 1, # fallback query param
    file: UploadFile = File(...)
):
    # Save temp file for complete-upload to use
    suffix = Path(file.filename or "audio.m4a").suffix or ".m4a"
    tmp_path = f"uploads/{sessionId}{suffix}"
    os.makedirs("uploads", exist_ok=True)
    
    with open(tmp_path, "wb") as f:
        content = await file.read()
        f.write(content)
        
    # Run analysis immediately!
    background_tasks.add_task(run_analysis_pipeline, sessionId, tmp_path, durationSeconds)
        
    return {
        "success": True,
        "data": {
            "sessionId": sessionId,
            "status": "ANALYZING"
        },
        "message": "File received and processing started"
    }

class CompleteUploadRequest(BaseModel):
    objectKey: str
    originalFileName: str
    mimeType: str
    durationSeconds: int

def run_analysis_pipeline(sessionId: str, tmp_path: str, duration_seconds: int):
    # Open a fresh database session for the background task
    print(f"\n[AI-COACH] Starting analysis for session {sessionId} on BACKGROUND THREAD...")
    db = database.SessionLocal()
    session = None
    try:
        session = db.query(models.InterviewSession).filter(models.InterviewSession.id == sessionId).first()
        if not session:
            print("[AI-COACH] ERROR: Session not found in DB.")
            return
            
        print("[AI-COACH] Marking session as ANALYZING...")
        session.status = "ANALYZING"
        db.commit()
        
        global whisper_model
        if whisper_model is None:
            print("[AI-COACH] Loading Faster-Whisper Model ('tiny' size to conserve RAM)...")
            # Enforce 1 thread to brutally prevent Intel MKL from allocating a GiB of thread pooling buffers!
            whisper_model = WhisperModel(MODEL_SIZE, device=DEVICE, compute_type=COMPUTE_TYPE, cpu_threads=1, num_workers=1)
            print("[AI-COACH] Whisper Loaded Successfully!")
            
        print("[AI-COACH] Transcribing audio file now...")
        segments, info = whisper_model.transcribe(
            tmp_path, language=LANGUAGE, beam_size=5, vad_filter=True, 
            initial_prompt="Transcribe accurately. Preserve filler words like um, uh, like, basically."
        )
        
        transcript_parts = [segment.text.strip() for segment in segments]
        full_transcript = " ".join(transcript_parts).strip()
        print(f"[AI-COACH] Transcript generated: {len(full_transcript)} characters.")
        
        recording = db.query(models.Recording).filter(models.Recording.session_id == sessionId).first()
        if not recording:
            recording = models.Recording(session_id=sessionId)
            db.add(recording)
            
        recording.file_path = tmp_path 
        recording.duration_seconds = duration_seconds
        recording.transcript = full_transcript
        db.commit()

        if full_transcript:
            print("[AI-COACH] Sending text to Google Gemini for Scoring...")
            _ensure_feedback_report(db, recording)
            print("[AI-COACH] Gemini finished scoring!")
            print("[AI-COACH] Report saved to Database!")
        else:
            session.status = "FAILED"
            db.commit()
            print(f"[AI-COACH] ERROR: No transcript could be extracted for session {sessionId}.")
            return
            
        session.status = "COMPLETED"
        db.commit()
        print(f"[AI-COACH] Session {sessionId} FULLY COMPLETED! Phone should update now.\n")

    except Exception as e:
        if session:
            session.status = "FAILED"
            db.commit()
        print(f"[AI-COACH] ERROR during analysis: {e}")
        logger.error(f"Analysis failed for session {sessionId}: {e}")
    finally:
        db.close()
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
            
@app.post("/api/v1/speech/sessions/{sessionId}/complete-upload")
def complete_upload(
    sessionId: str,
    req: CompleteUploadRequest,
    background_tasks: BackgroundTasks,
    db: Session = Depends(database.get_db), 
    current_user: models.User = Depends(auth.get_current_user)
):
    session = db.query(models.InterviewSession).filter(models.InterviewSession.id == sessionId).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
        
    session.status = "ANALYZING"
    db.commit()

    tmp_path = f"uploads/{req.objectKey}"
    
    # Run analysis immediately without blocking Flutter timeout
    background_tasks.add_task(run_analysis_pipeline, sessionId, tmp_path, req.durationSeconds)
        
    return {
        "success": True,
        "data": {
            "sessionId": sessionId,
            "status": "ANALYZING"
        },
        "message": "Upload complete and analysis started"
    }

# ── Feedback Polling Endpoint ──────────────────────────────────
@app.get("/api/v1/speech/sessions/{sessionId}/status")
def get_analysis_status(sessionId: str, db: Session = Depends(database.get_db), current_user: models.User = Depends(auth.get_current_user)):
    session = db.query(models.InterviewSession).filter(
        models.InterviewSession.id == sessionId
    ).first()
    
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
        
    if session.status != "COMPLETED":
        return {
            "success": True,
            "data": {
                "sessionId": sessionId,
                "status": session.status,
                "reportReady": False,
                "transcriptReady": False,
                "message": f"Session status is {session.status}"
            },
            "message": "Analysis in progress."
        }
        
    recording = db.query(models.Recording).filter(models.Recording.session_id == sessionId).first()
    if not recording:
        return {
            "success": True,
            "data": {
                "sessionId": sessionId,
                "status": "FAILED",
                "reportReady": False,
                "transcriptReady": False,
                "message": "Recording data is missing for this session."
            },
            "message": "Analysis failed."
        }

    feedback = recording.feedback
    if not feedback:
        try:
            feedback = _ensure_feedback_report(db, recording)
        except Exception as exc:
            logger.exception("Failed to rebuild feedback for session %s", sessionId)
            return {
                "success": True,
                "data": {
                    "sessionId": sessionId,
                    "status": "FAILED",
                    "reportReady": False,
                    "transcriptReady": bool((recording.transcript or "").strip()),
                    "message": f"Feedback generation failed: {exc}"
                },
                "message": "Analysis failed."
            }

    if not feedback:
        return {
            "success": True,
            "data": {
                "sessionId": sessionId,
                "status": "FAILED",
                "reportReady": False,
                "transcriptReady": bool((recording.transcript or "").strip()),
                "message": "No speech was detected clearly enough to generate feedback."
            },
            "message": "Analysis failed."
        }

    return {
        "success": True,
        "data": {
            "status": session.status,
            "sessionId": str(session.id),
            "reportReady": True,
            "transcriptReady": True,
            "message": "Analysis completed automatically",
            "transcript": {
                "text": recording.transcript,
                "durationSeconds": recording.duration_seconds
            },
            "report": {
                "id": str(feedback.id),
                "createdAt": recording.session.created_at.isoformat(),
                "overallScore": feedback.overall_score,
                "components": [
                    {"category": "Pace", "score": feedback.pace_score, "feedback": "AI handled globally."},
                    {"category": "Grammar", "score": feedback.grammar_score, "feedback": "AI handled globally."},
                    {"category": "Clarity", "score": feedback.clarity_score, "feedback": "AI handled globally."},
                    {"category": "Confidence", "score": feedback.confidence_score, "feedback": "AI handled globally."}
                ],
                "aiComments": feedback.ai_comments
            }
        },
        "message": "Feedback report retrieved"
    }


@app.get("/api/v1/feedback/reports/{sessionId}")
def get_feedback_report(
    sessionId: str,
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(auth.get_current_user),
):
    session = db.query(models.InterviewSession).filter(
        models.InterviewSession.id == sessionId,
        models.InterviewSession.user_id == current_user.id,
    ).first()

    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    recording = db.query(models.Recording).filter(models.Recording.session_id == sessionId).first()
    if not recording:
        raise HTTPException(status_code=404, detail="Feedback report not found")

    feedback = recording.feedback
    if not feedback:
        try:
            feedback = _ensure_feedback_report(db, recording)
        except Exception as exc:
            logger.exception("Failed to rebuild feedback report for session %s", sessionId)
            raise HTTPException(status_code=500, detail=f"Feedback generation failed: {exc}")

    if not feedback:
        raise HTTPException(status_code=404, detail="Feedback report not found")

    transcript_text = recording.transcript or ""
    ai_comments = feedback.ai_comments or "Feedback generated successfully."

    strengths = []
    weaknesses = []
    suggestions = []

    if feedback.clarity_score >= 70:
        strengths.append("Your response was reasonably clear and easy to follow.")
    else:
        weaknesses.append("Your response could be clearer and more structured.")
        suggestions.append("Break your answer into smaller points with a cleaner beginning, middle, and end.")

    if feedback.confidence_score >= 70:
        strengths.append("Your tone came across as fairly confident.")
    else:
        weaknesses.append("Your delivery sounded less confident than it could be.")
        suggestions.append("Slow down slightly and finish each sentence with conviction.")

    if feedback.pace_score >= 70:
        strengths.append("Your speaking pace was comfortable for listening.")
    else:
        weaknesses.append("Your speaking pace needs better control.")
        suggestions.append("Aim for a steadier pace and add brief pauses between ideas.")

    if not strengths:
        strengths.append("You completed the answer and gave enough material for analysis.")
    if not weaknesses:
        weaknesses.append("There are still a few areas you can refine to sound sharper.")
    if not suggestions:
        suggestions.append("Practice the same answer once more and focus on structure, pace, and confidence.")

    filler_score = int(round((feedback.grammar_score + feedback.clarity_score) / 2.0))

    return {
        "success": True,
        "data": {
            "reportId": str(feedback.id),
            "sessionId": str(session.id),
            "overallScore": int(round(feedback.overall_score or 0)),
            "paceScore": int(round(feedback.pace_score or 0)),
            "clarityScore": int(round(feedback.clarity_score or 0)),
            "confidenceScore": int(round(feedback.confidence_score or 0)),
            "fillerScore": filler_score,
            "transcriptText": transcript_text,
            "transcriptHighlights": [],
            "summary": ai_comments,
            "strengths": strengths,
            "weaknesses": weaknesses,
            "suggestions": suggestions,
            "betterAnswer": "",
            "fillerBreakdown": [],
            "hesitationPhrases": [],
        },
        "message": "Feedback report fetched successfully",
    }


@app.get("/api/v1/subscription/me")
def get_current_subscription(
    current_user: models.User = Depends(auth.get_current_user),
):
    plan = current_user.plan or "FREE"
    developer_account = current_user.email.endswith("@gmail.com")
    session_limit = 9999 if plan == "PRO" else 10
    processed_seconds_limit = 999999 if plan == "PRO" else 900

    return {
        "success": True,
        "data": {
            "plan": plan,
            "developerAccount": developer_account,
            "sessionsUsed": 0,
            "sessionLimit": session_limit,
            "sessionsRemaining": session_limit,
            "processedSecondsUsed": 0,
            "processedSecondsLimit": processed_seconds_limit,
            "processedSecondsRemaining": processed_seconds_limit,
        },
        "message": "Subscription fetched successfully",
    }
