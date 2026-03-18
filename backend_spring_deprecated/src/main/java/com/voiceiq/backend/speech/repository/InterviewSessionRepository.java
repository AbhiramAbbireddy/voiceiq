package com.voiceiq.backend.speech.repository;

import com.voiceiq.backend.speech.domain.InterviewSession;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface InterviewSessionRepository extends JpaRepository<InterviewSession, UUID> {
    List<InterviewSession> findByUser_IdOrderByCreatedAtDesc(UUID userId);
}
