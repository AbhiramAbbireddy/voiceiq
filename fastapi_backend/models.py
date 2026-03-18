import enum
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, Boolean, DateTime, ForeignKey, Text, Float, Enum, inspect
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from database import Base
import uuid

def generate_uuid():
    return uuid.uuid4()

class PlanType(str, enum.Enum):
    FREE = "FREE"
    PRO = "PRO"

class User(Base):
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=generate_uuid)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    full_name = Column(String)
    target_role = Column(String, default="ROLE_USER")
    plan = Column(String, default="FREE")
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    sessions = relationship("InterviewSession", back_populates="user")
    
class InterviewSession(Base):
    __tablename__ = "interview_sessions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=generate_uuid)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=False)
    status = Column(String, default="PENDING") # PENDING, RECORDING, ANALYZING, COMPLETED
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    
    user = relationship("User", back_populates="sessions")
    recordings = relationship("Recording", back_populates="session", uselist=False)

class Recording(Base):
    __tablename__ = "recordings"

    id = Column(UUID(as_uuid=True), primary_key=True, default=generate_uuid)
    session_id = Column(UUID(as_uuid=True), ForeignKey("interview_sessions.id"), unique=True)
    file_path = Column(String, nullable=False) # Local path or S3 key
    duration_seconds = Column(Integer, default=0)
    transcript = Column(Text, nullable=True) # Text output from Faster-Whisper
    
    session = relationship("InterviewSession", back_populates="recordings")
    feedback = relationship("FeedbackReport", back_populates="recording", uselist=False)

class FeedbackReport(Base):
    __tablename__ = "feedback_reports"

    id = Column(UUID(as_uuid=True), primary_key=True, default=generate_uuid)
    recording_id = Column(UUID(as_uuid=True), ForeignKey("recordings.id"), unique=True)
    overall_score = Column(Float, default=0.0)
    grammar_score = Column(Float, default=0.0)
    clarity_score = Column(Float, default=0.0)
    confidence_score = Column(Float, default=0.0)
    pace_score = Column(Float, default=0.0)
    ai_comments = Column(Text) # Text returned from Gemini 
    
    recording = relationship("Recording", back_populates="feedback")
    
